import { useState, useEffect } from 'react'
import { api } from '../lib/api'
import type { User, Report } from '../types/api'

const ROLE_LABELS: Record<string, string> = {
  admin: 'Administrateur', supervisor: 'Superviseur',
  analyst: 'Analyste', field_agent: 'Agent terrain',
}

const ROLE_OPTIONS = [
  { value: 'field_agent', label: 'Agent terrain' },
  { value: 'analyst',     label: 'Analyste' },
  { value: 'supervisor',  label: 'Superviseur' },
  { value: 'admin',       label: 'Administrateur' },
]

const STATUS_STYLE = {
  active:   { label: 'Actif',   bg: '#22C55E18', text: '#22C55E', dot: '#22C55E' },
  inactive: { label: 'Inactif', bg: '#EF444418', text: '#EF4444', dot: '#EF4444' },
}

interface AgentStats { assigned: number; resolved: number; inProgress: number; performance: number }
interface Municipality { id: number; name: string }

function initials(name: string) {
  return name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
}
function agentStatus(u: User): keyof typeof STATUS_STYLE {
  return u.is_active ? 'active' : 'inactive'
}
function perfColor(p: number) {
  return p >= 80 ? '#22C55E' : p >= 60 ? '#0038AF' : '#F59E0B'
}

function Skeleton() {
  return (
    <div className="bg-white rounded-xl p-5 border border-[#E2E8F0] shadow-sm animate-pulse">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-full bg-[#E2E8F0]" />
          <div><div className="h-4 bg-[#E2E8F0] rounded w-28 mb-1" /><div className="h-3 bg-[#E2E8F0] rounded w-20" /></div>
        </div>
        <div className="h-5 bg-[#E2E8F0] rounded-full w-16" />
      </div>
      <div className="h-16 bg-[#E2E8F0] rounded-lg mb-4" />
      <div className="h-2 bg-[#E2E8F0] rounded-full" />
    </div>
  )
}

interface AddAgentForm {
  full_name: string; email: string; phone: string
  role: string; municipality_id: string; password: string
}

const EMPTY_FORM: AddAgentForm = {
  full_name: '', email: '', phone: '', role: 'field_agent', municipality_id: '', password: ''
}

const MISSION_STATUS_LABELS: Record<string, string> = {
  received: 'Reçu', under_review: 'En examen', in_progress: 'En cours',
}
const MISSION_STATUS_COLORS: Record<string, string> = {
  received: '#0EA5E9', under_review: '#F59E0B', in_progress: '#F97316',
}

export default function Teams() {
  const [view, setView] = useState<'grid' | 'list'>('grid')
  const [staff, setStaff] = useState<User[]>([])
  const [statsMap, setStatsMap] = useState<Record<string, AgentStats>>({})
  const [municipalities, setMunicipalities] = useState<Municipality[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Missions for selected agent
  const [missions, setMissions] = useState<Report[]>([])
  const [missionsLoading, setMissionsLoading] = useState(false)

  // Add agent modal
  const [showAdd, setShowAdd] = useState(false)
  const [form, setForm] = useState<AddAgentForm>(EMPTY_FORM)
  const [formError, setFormError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const [togglingId, setTogglingId] = useState<string | null>(null)

  function loadData() {
    setLoading(true)
    Promise.all([
      api.get<User[]>('/admin/users'),
      api.get<{ items: Report[]; total: number }>('/reports', { page_size: '500' }).catch(() => ({ items: [] as Report[], total: 0 })),
      api.get<Municipality[]>('/admin/municipalities').catch(() => [] as Municipality[]),
    ])
      .then(([users, rData, munis]) => {
        setStaff(users)
        setMunicipalities(munis)
        const map: Record<string, AgentStats> = {}
        users.forEach(u => {
          const mine = rData.items.filter(r => r.assigned_to === u.id)
          const res = mine.filter(r => r.status === 'resolved').length
          const inp = mine.filter(r => r.status === 'in_progress').length
          map[u.id] = {
            assigned: mine.length,
            resolved: res,
            inProgress: inp,
            performance: mine.length > 0 ? Math.round((res / mine.length) * 100) : 0
          }
        })
        setStatsMap(map)
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }

  useEffect(() => { loadData() }, [])

  // Load missions when agent is selected
  useEffect(() => {
    if (!selectedId) { setMissions([]); return }
    setMissionsLoading(true)
    api.get<{ items: Report[] }>('/reports', { agent_id: selectedId, page_size: 20 })
      .then(data => setMissions((data.items ?? []).filter(r => !['resolved', 'rejected'].includes(r.status))))
      .catch(() => setMissions([]))
      .finally(() => setMissionsLoading(false))
  }, [selectedId])

  async function submitAdd() {
    if (!form.full_name.trim() || !form.email.trim() || !form.password.trim() || !form.municipality_id) {
      setFormError('Tous les champs obligatoires doivent être remplis.')
      return
    }
    setSubmitting(true)
    setFormError(null)
    try {
      await api.post('/admin/users', {
        full_name: form.full_name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim() || undefined,
        role: form.role,
        municipality_id: parseInt(form.municipality_id),
        password: form.password,
        preferred_language: 'fr',
      })
      setShowAdd(false)
      setForm(EMPTY_FORM)
      loadData()
    } catch (e: unknown) {
      setFormError(e instanceof Error ? e.message : 'Erreur lors de la création')
    } finally {
      setSubmitting(false)
    }
  }

  async function toggleActive(user: User) {
    setTogglingId(user.id)
    try {
      await api.patch(`/admin/users/${user.id}`, { is_active: !user.is_active })
      setStaff(prev => prev.map(u => u.id === user.id ? { ...u, is_active: !u.is_active } : u))
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Erreur')
    } finally {
      setTogglingId(null)
    }
  }

  const detail = staff.find(a => a.id === selectedId)

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">Équipes & Agents</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? 'Chargement...' : `${staff.length} membres du personnel`}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="bg-[#eceef3] p-1 rounded-lg flex gap-1">
            {(['grid', 'list'] as const).map(v => (
              <button key={v} onClick={() => setView(v)}
                className={`px-3 py-1.5 rounded-md text-sm font-medium transition-all ${view === v ? 'bg-white shadow-sm text-[#0038AF]' : 'text-[#64748B]'}`}>
                <span className="material-symbols-outlined" style={{ fontSize: 16 }}>
                  {v === 'grid' ? 'grid_view' : 'format_list_bulleted'}
                </span>
              </button>
            ))}
          </div>
          <button
            onClick={() => { setShowAdd(true); setFormError(null); setForm(EMPTY_FORM) }}
            className="flex items-center gap-2 px-4 py-2 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity">
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>person_add</span>
            Ajouter un agent
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
          <button onClick={() => setError(null)} className="ml-auto text-red-400"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>close</span></button>
        </div>
      )}

      <div className="flex gap-6">
        <div className="flex-1 min-w-0">
          {view === 'grid' ? (
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
              {loading
                ? Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} />)
                : staff.map(agent => {
                    const ss = STATUS_STYLE[agentStatus(agent)]
                    const s = statsMap[agent.id] ?? { assigned: 0, resolved: 0, inProgress: 0, performance: 0 }
                    const pc = perfColor(s.performance)
                    const isSelected = selectedId === agent.id
                    return (
                      <div key={agent.id} onClick={() => setSelectedId(isSelected ? null : agent.id)}
                        className={`bg-white rounded-xl p-5 border shadow-sm cursor-pointer transition-all hover:shadow-md
                          ${isSelected ? 'border-[#0038AF] ring-1 ring-[#0038AF]' : 'border-[#E2E8F0]'}`}>
                        <div className="flex items-start justify-between mb-4">
                          <div className="flex items-center gap-3">
                            <div className="relative">
                              <div className="w-12 h-12 rounded-full bg-[#0038AF] text-white flex items-center justify-center text-base font-bold">
                                {initials(agent.full_name)}
                              </div>
                              <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 border-white" style={{ backgroundColor: ss.dot }} />
                            </div>
                            <div>
                              <p className="text-sm font-bold text-[#181c20]">{agent.full_name}</p>
                              <p className="text-xs text-[#64748B]">{ROLE_LABELS[agent.role] ?? agent.role}</p>
                            </div>
                          </div>
                          <span className="px-2 py-0.5 rounded-full text-xs font-medium flex-shrink-0" style={{ backgroundColor: ss.bg, color: ss.text }}>{ss.label}</span>
                        </div>
                        <div className="grid grid-cols-3 gap-2 mb-4">
                          {[{ label: 'Assignés', value: s.assigned, color: '#0038AF' }, { label: 'Résolus', value: s.resolved, color: '#22C55E' }, { label: 'En cours', value: s.inProgress, color: '#F97316' }].map(x => (
                            <div key={x.label} className="text-center p-2 rounded-lg" style={{ backgroundColor: `${x.color}10` }}>
                              <p className="text-lg font-bold" style={{ color: x.color }}>{x.value}</p>
                              <p className="text-[10px] text-[#64748B]">{x.label}</p>
                            </div>
                          ))}
                        </div>
                        <div>
                          <div className="flex justify-between items-center mb-1">
                            <span className="text-xs text-[#64748B]">Performance</span>
                            <span className="text-xs font-bold" style={{ color: pc }}>{s.performance}%</span>
                          </div>
                          <div className="w-full h-1.5 bg-[#f1f4f9] rounded-full overflow-hidden">
                            <div className="h-full rounded-full" style={{ width: `${s.performance}%`, backgroundColor: pc }} />
                          </div>
                        </div>
                        <div className="flex items-center gap-1.5 mt-4 pt-3 border-t border-[#E2E8F0]">
                          <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 14 }}>email</span>
                          <span className="text-xs text-[#64748B] truncate">{agent.email ?? '—'}</span>
                        </div>
                      </div>
                    )
                  })}
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
              <table className="w-full text-left">
                <thead>
                  <tr className="bg-[#f7f9fe] border-b border-[#E2E8F0]">
                    {['Agent', 'Rôle', 'Statut', 'Assignés', 'Résolus', 'Performance', 'Email', 'Actions'].map(h => (
                      <th key={h} className="px-5 py-3 text-xs font-semibold text-[#64748B] uppercase tracking-wider">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E2E8F0]">
                  {loading
                    ? Array.from({ length: 5 }).map((_, i) => (
                        <tr key={i} className="animate-pulse">{Array.from({ length: 8 }).map((__, j) => <td key={j} className="px-5 py-3.5"><div className="h-4 bg-[#E2E8F0] rounded w-20" /></td>)}</tr>
                      ))
                    : staff.map(agent => {
                        const ss = STATUS_STYLE[agentStatus(agent)]
                        const s = statsMap[agent.id] ?? { assigned: 0, resolved: 0, inProgress: 0, performance: 0 }
                        const pc = perfColor(s.performance)
                        return (
                          <tr key={agent.id} className="hover:bg-[#f7f9fe] transition-colors">
                            <td className="px-5 py-3.5">
                              <div className="flex items-center gap-3 cursor-pointer" onClick={() => setSelectedId(agent.id === selectedId ? null : agent.id)}>
                                <div className="w-8 h-8 rounded-full bg-[#0038AF] text-white flex items-center justify-center text-xs font-bold flex-shrink-0">{initials(agent.full_name)}</div>
                                <span className="text-sm font-medium text-[#181c20]">{agent.full_name}</span>
                              </div>
                            </td>
                            <td className="px-5 py-3.5 text-sm text-[#64748B]">{ROLE_LABELS[agent.role] ?? agent.role}</td>
                            <td className="px-5 py-3.5"><span className="px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: ss.bg, color: ss.text }}>{ss.label}</span></td>
                            <td className="px-5 py-3.5 text-sm font-bold text-[#0038AF]">{s.assigned}</td>
                            <td className="px-5 py-3.5 text-sm font-bold text-[#22C55E]">{s.resolved}</td>
                            <td className="px-5 py-3.5">
                              <div className="flex items-center gap-2">
                                <div className="w-20 h-1.5 bg-[#f1f4f9] rounded-full overflow-hidden"><div className="h-full rounded-full" style={{ width: `${s.performance}%`, backgroundColor: pc }} /></div>
                                <span className="text-xs font-bold" style={{ color: pc }}>{s.performance}%</span>
                              </div>
                            </td>
                            <td className="px-5 py-3.5 text-sm text-[#64748B] truncate max-w-40">{agent.email ?? '—'}</td>
                            <td className="px-5 py-3.5">
                              <button
                                onClick={() => toggleActive(agent)}
                                disabled={togglingId === agent.id}
                                className={`text-xs px-2 py-1 rounded-lg font-medium transition-colors disabled:opacity-50
                                  ${agent.is_active ? 'bg-red-50 text-red-500 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'}`}>
                                {togglingId === agent.id ? '…' : agent.is_active ? 'Désactiver' : 'Activer'}
                              </button>
                            </td>
                          </tr>
                        )
                      })}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Detail panel */}
        {detail && (() => {
          const ss = STATUS_STYLE[agentStatus(detail)]
          const s = statsMap[detail.id] ?? { assigned: 0, resolved: 0, inProgress: 0, performance: 0 }
          const pc = perfColor(s.performance)
          return (
            <div className="w-80 flex-shrink-0 bg-white rounded-xl border border-[#E2E8F0] shadow-sm sticky top-24 max-h-[calc(100vh-7rem)] flex flex-col overflow-hidden">
              <div className="px-5 py-4 border-b border-[#E2E8F0] flex items-center justify-between flex-shrink-0">
                <h4 className="text-[#181c20] font-semibold text-sm">Fiche agent</h4>
                <button onClick={() => setSelectedId(null)} className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                  <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 18 }}>close</span>
                </button>
              </div>

              <div className="flex-1 overflow-y-auto">
                {/* Profile header */}
                <div className="p-5">
                  <div className="flex flex-col items-center mb-5 text-center">
                    <div className="w-16 h-16 rounded-full bg-[#0038AF] text-white flex items-center justify-center text-xl font-bold mb-3">{initials(detail.full_name)}</div>
                    <p className="text-base font-bold text-[#181c20]">{detail.full_name}</p>
                    <p className="text-sm text-[#64748B]">{ROLE_LABELS[detail.role] ?? detail.role}</p>
                    <span className="mt-2 px-2.5 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: ss.bg, color: ss.text }}>{ss.label}</span>
                  </div>

                  {/* Stats */}
                  <div className="grid grid-cols-3 gap-2 mb-4">
                    {[{ label: 'Assignés', value: s.assigned, color: '#0038AF' }, { label: 'Résolus', value: s.resolved, color: '#22C55E' }, { label: 'En cours', value: s.inProgress, color: '#F97316' }].map(x => (
                      <div key={x.label} className="text-center p-2 rounded-lg" style={{ backgroundColor: `${x.color}10` }}>
                        <p className="text-xl font-bold" style={{ color: x.color }}>{x.value}</p>
                        <p className="text-[10px] text-[#64748B]">{x.label}</p>
                      </div>
                    ))}
                  </div>

                  {/* Performance bar */}
                  <div className="mb-4">
                    <div className="flex justify-between items-center mb-1.5">
                      <span className="text-xs font-semibold text-[#64748B]">Performance</span>
                      <span className="text-sm font-bold" style={{ color: pc }}>{s.performance}%</span>
                    </div>
                    <div className="w-full h-2 bg-[#f1f4f9] rounded-full overflow-hidden">
                      <div className="h-full rounded-full" style={{ width: `${s.performance}%`, backgroundColor: pc }} />
                    </div>
                  </div>

                  {/* Contact */}
                  {detail.email && <div className="flex items-center gap-2 text-sm text-[#64748B] mb-1.5"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>email</span><span className="truncate">{detail.email}</span></div>}
                  {detail.phone && <div className="flex items-center gap-2 text-sm text-[#64748B] mb-3"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>phone</span><span>{detail.phone}</span></div>}
                  <p className="text-xs text-[#94A3B8] mb-4">Membre depuis {new Date(detail.created_at).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })}</p>

                  <button onClick={() => toggleActive(detail)} disabled={togglingId === detail.id}
                    className={`w-full py-2 rounded-xl text-sm font-medium transition-colors disabled:opacity-50
                      ${detail.is_active ? 'bg-red-50 text-red-500 hover:bg-red-100 border border-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100 border border-green-100'}`}>
                    {togglingId === detail.id ? 'Mise à jour...' : detail.is_active ? 'Désactiver le compte' : 'Réactiver le compte'}
                  </button>
                </div>

                {/* Missions actives */}
                <div className="border-t border-[#E2E8F0] px-5 py-4">
                  <div className="flex items-center justify-between mb-3">
                    <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider">Missions actives</p>
                    {missions.length > 0 && (
                      <span className="bg-[#F97316] text-white text-[10px] font-bold rounded-full px-1.5 py-0.5">{missions.length}</span>
                    )}
                  </div>
                  {missionsLoading ? (
                    <div className="space-y-2">
                      {[1, 2].map(i => <div key={i} className="h-12 bg-[#f1f4f9] rounded-lg animate-pulse" />)}
                    </div>
                  ) : missions.length === 0 ? (
                    <div className="text-center py-4">
                      <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 28 }}>check_circle</span>
                      <p className="text-xs text-[#94A3B8] mt-1">Aucune mission en cours</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {missions.map(m => {
                        const color = MISSION_STATUS_COLORS[m.status] ?? '#94A3B8'
                        const label = MISSION_STATUS_LABELS[m.status] ?? m.status
                        return (
                          <div
                            key={m.id}
                            className="w-full text-left px-3 py-2.5 bg-[#f7f9fe] rounded-lg border border-[#E2E8F0]"
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div className="flex-1 min-w-0">
                                <p className="text-xs font-medium text-[#181c20] truncate">{m.title}</p>
                                <p className="text-[10px] text-[#94A3B8] font-mono mt-0.5">{m.tracking_code}</p>
                              </div>
                              <span className="flex-shrink-0 text-[10px] font-bold px-1.5 py-0.5 rounded-full" style={{ backgroundColor: `${color}18`, color }}>
                                {label}
                              </span>
                            </div>
                            {m.city && <p className="text-[10px] text-[#64748B] mt-1 flex items-center gap-1"><span className="material-symbols-outlined" style={{ fontSize: 10 }}>location_on</span>{m.city}</p>}
                          </div>
                        )
                      })}
                    </div>
                  )}
                </div>
              </div>
            </div>
          )
        })()}
      </div>

      {/* Add Agent Modal */}
      {showAdd && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
          onClick={e => { if (e.target === e.currentTarget) setShowAdd(false) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-5 border-b border-[#E2E8F0] flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-[#181c20]">Ajouter un agent</h3>
                <p className="text-xs text-[#64748B] mt-0.5">Créer un nouveau compte membre du personnel</p>
              </div>
              <button onClick={() => setShowAdd(false)} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>close</span>
              </button>
            </div>
            <div className="p-6 space-y-4">
              {formError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3">
                  <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
                  <span className="text-sm text-red-600">{formError}</span>
                </div>
              )}
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">Nom complet *</label>
                  <input value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
                    placeholder="ex: Sami Mejri"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">Email *</label>
                  <input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                    placeholder="agent@sahali.tn"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">Téléphone</label>
                  <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                    placeholder="+216 XX XXX XXX"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">Rôle *</label>
                  <select value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                    {ROLE_OPTIONS.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">Municipalité *</label>
                  <select value={form.municipality_id} onChange={e => setForm(f => ({ ...f, municipality_id: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                    <option value="">Sélectionner...</option>
                    {municipalities.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                  </select>
                </div>
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">Mot de passe *</label>
                  <input type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                    placeholder="Min. 8 caractères"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3">
              <button onClick={() => setShowAdd(false)}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                Annuler
              </button>
              <button onClick={submitAdd} disabled={submitting}
                className="flex-1 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                {submitting ? 'Création...' : 'Créer le compte'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
