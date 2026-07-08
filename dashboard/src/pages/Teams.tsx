import { useState, useEffect, useCallback } from 'react'
import { api } from '../lib/api'
import type { User, Report, UserListOut, Municipality, MunicipalityListOut } from '../types/api'
import { useLang } from '../context/LangContext'

const PAGE_SIZE = 20

interface AgentStats { assigned: number; resolved: number; inProgress: number; performance: number }

function initials(name: string) {
  return name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
}
function agentIsActive(u: User): boolean {
  return u.is_active
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

export default function Teams() {
  const { t, locale } = useLang()
  const [view, setView] = useState<'grid' | 'list'>('grid')
  const [staff, setStaff] = useState<User[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [statsMap, setStatsMap] = useState<Record<string, AgentStats>>({})
  const [municipalities, setMunicipalities] = useState<Municipality[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [missions, setMissions] = useState<Report[]>([])
  const [missionsLoading, setMissionsLoading] = useState(false)

  const [showAdd, setShowAdd] = useState(false)
  const [form, setForm] = useState<AddAgentForm>(EMPTY_FORM)
  const [formError, setFormError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const [editingAgent, setEditingAgent] = useState<User | null>(null)
  const [editForm, setEditForm] = useState({ full_name: '', role: 'field_agent', municipality_id: '' })
  const [editError, setEditError] = useState<string | null>(null)
  const [savingEdit, setSavingEdit] = useState(false)

  const [deleteTarget, setDeleteTarget] = useState<User | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  const [togglingId, setTogglingId] = useState<string | null>(null)

  // Debounce the search box before it hits the server
  useEffect(() => {
    const id = setTimeout(() => { setDebouncedSearch(search); setPage(1) }, 350)
    return () => clearTimeout(id)
  }, [search])

  const roleLabel = (role: string) => t(
    role === 'admin' ? 'role_admin' :
    role === 'supervisor' ? 'role_supervisor' :
    role === 'analyst' ? 'role_analyst' :
    role === 'field_agent' ? 'role_field_agent' :
    role === 'citizen' ? 'role_citizen' : 'role_field_agent'
  )

  const missionStatusLabel = (status: string) => t(
    status === 'received' ? 'status_received' :
    status === 'under_review' ? 'status_under_review' :
    status === 'in_progress' ? 'status_in_progress' : 'status_received'
  )

  const missionStatusColor: Record<string, string> = {
    received: '#0EA5E9', under_review: '#F59E0B', in_progress: '#F97316',
  }

  const [allReports, setAllReports] = useState<Report[]>([])

  // Municipality list for the add/edit dropdowns — fetched once, large page
  // so it covers the full list regardless of the staff table's own paging.
  useEffect(() => {
    api.get<MunicipalityListOut>('/admin/municipalities', { page_size: 500 })
      .then(data => setMunicipalities(data.items ?? []))
      .catch(() => setMunicipalities([]))
  }, [])

  // Reports (for the per-agent stats) — fetched once, independent of the
  // staff table's own pagination/search/role filter.
  useEffect(() => {
    api.get<{ items: Report[]; total: number }>('/reports', { page_size: 500 })
      .then(data => setAllReports(data.items ?? []))
      .catch(() => setAllReports([]))
  }, [])

  const fetchStaff = useCallback(() => {
    setLoading(true)
    setError(null)
    const params: Record<string, string | number | undefined> = { page, page_size: PAGE_SIZE }
    if (debouncedSearch) params.search = debouncedSearch
    if (roleFilter) params.role = roleFilter
    api.get<UserListOut>('/admin/users', params)
      .then(data => { setStaff(data.items ?? []); setTotal(data.total ?? 0) })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [page, debouncedSearch, roleFilter])

  useEffect(() => { fetchStaff() }, [fetchStaff])

  // Recompute per-agent stats whenever the current staff page or the report
  // set changes.
  useEffect(() => {
    const map: Record<string, AgentStats> = {}
    staff.forEach(u => {
      const mine = allReports.filter(r => r.assigned_to === u.id)
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
  }, [staff, allReports])

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))

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
      setFormError(t('required_fields_err'))
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
      fetchStaff()
    } catch (e: unknown) {
      setFormError(e instanceof Error ? e.message : t('err_creation'))
    } finally {
      setSubmitting(false)
    }
  }

  function openEditAgent(user: User) {
    setEditingAgent(user)
    setEditForm({
      full_name: user.full_name,
      role: user.role,
      municipality_id: user.municipality_id != null ? String(user.municipality_id) : '',
    })
    setEditError(null)
  }

  async function submitEdit() {
    if (!editingAgent) return
    if (!editForm.full_name.trim()) { setEditError(t('required_fields_err')); return }
    setSavingEdit(true)
    setEditError(null)
    try {
      await api.patch(`/admin/users/${editingAgent.id}`, {
        full_name: editForm.full_name.trim(),
        role: editForm.role,
        municipality_id: editForm.municipality_id ? parseInt(editForm.municipality_id) : undefined,
      })
      setEditingAgent(null)
      fetchStaff()
    } catch (e: unknown) {
      setEditError(e instanceof Error ? e.message : t('err_creation'))
    } finally {
      setSavingEdit(false)
    }
  }

  async function confirmDeleteAgent() {
    if (!deleteTarget) return
    setDeleting(true)
    setDeleteError(null)
    try {
      await api.delete(`/admin/users/${deleteTarget.id}`)
      setDeleteTarget(null)
      if (selectedId === deleteTarget.id) setSelectedId(null)
      fetchStaff()
    } catch (e: unknown) {
      setDeleteError(e instanceof Error ? e.message : t('err_creation'))
    } finally {
      setDeleting(false)
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

  const roleOptions = [
    { value: 'field_agent', label: t('role_field_agent') },
    { value: 'analyst',     label: t('role_analyst') },
    { value: 'supervisor',  label: t('role_supervisor') },
    { value: 'admin',       label: t('role_admin') },
  ]

  const listHeaders = [t('col_agent'), t('col_role'), t('col_status'), t('stat_assigned'), t('stat_resolved_n'), t('performance'), 'Email', t('col_actions')]

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('teams_title')}</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? t('loading') : `${total} ${t('staff_members')}`}
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
            {t('btn_add_agent')}
          </button>
        </div>
      </div>

      {/* Search + role filter */}
      <div className="bg-white rounded-xl border border-[#E2E8F0] p-4 mb-4 flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-48">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#747686]" style={{ fontSize: 16 }}>search</span>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            type="text"
            placeholder={t('agent_search_placeholder')}
            className="w-full bg-[#f1f4f9] rounded-lg pl-9 pr-4 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 border-0"
          />
        </div>
        <select
          value={roleFilter}
          onChange={e => { setRoleFilter(e.target.value); setPage(1) }}
          className="bg-[#f1f4f9] rounded-lg px-3 py-2 text-sm outline-none border-0 text-[#181c20]"
        >
          <option value="">{t('all_roles')}</option>
          {roleOptions.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
        </select>
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
                    const isActive = agentIsActive(agent)
                    const ssBg = isActive ? '#22C55E18' : '#EF444418'
                    const ssText = isActive ? '#22C55E' : '#EF4444'
                    const ssDot = isActive ? '#22C55E' : '#EF4444'
                    const ssLabel = isActive ? t('agent_active') : t('agent_inactive')
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
                              <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2 border-white" style={{ backgroundColor: ssDot }} />
                            </div>
                            <div>
                              <p className="text-sm font-bold text-[#181c20]">{agent.full_name}</p>
                              <p className="text-xs text-[#64748B]">{roleLabel(agent.role)}</p>
                            </div>
                          </div>
                          <span className="px-2 py-0.5 rounded-full text-xs font-medium flex-shrink-0" style={{ backgroundColor: ssBg, color: ssText }}>{ssLabel}</span>
                        </div>
                        <div className="grid grid-cols-3 gap-2 mb-4">
                          {[
                            { label: t('stat_assigned'), value: s.assigned, color: '#0038AF' },
                            { label: t('stat_resolved_n'), value: s.resolved, color: '#22C55E' },
                            { label: t('stat_in_prog'), value: s.inProgress, color: '#F97316' },
                          ].map(x => (
                            <div key={x.label} className="text-center p-2 rounded-lg" style={{ backgroundColor: `${x.color}10` }}>
                              <p className="text-lg font-bold" style={{ color: x.color }}>{x.value}</p>
                              <p className="text-[10px] text-[#64748B]">{x.label}</p>
                            </div>
                          ))}
                        </div>
                        <div>
                          <div className="flex justify-between items-center mb-1">
                            <span className="text-xs text-[#64748B]">{t('performance')}</span>
                            <span className="text-xs font-bold" style={{ color: pc }}>{s.performance}%</span>
                          </div>
                          <div className="w-full h-1.5 bg-[#f1f4f9] rounded-full overflow-hidden">
                            <div className="h-full rounded-full" style={{ width: `${s.performance}%`, backgroundColor: pc }} />
                          </div>
                        </div>
                        <div className="flex items-center justify-between gap-1.5 mt-4 pt-3 border-t border-[#E2E8F0]">
                          <div className="flex items-center gap-1.5 min-w-0">
                            <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 14 }}>email</span>
                            <span className="text-xs text-[#64748B] truncate">{agent.email ?? '—'}</span>
                          </div>
                          <div className="flex items-center gap-1 flex-shrink-0" onClick={e => e.stopPropagation()}>
                            <button onClick={() => openEditAgent(agent)} title={t('btn_edit')}
                              className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-[#eceef3]">
                              <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 16 }}>edit</span>
                            </button>
                            <button onClick={() => { setDeleteTarget(agent); setDeleteError(null) }} title={t('btn_delete')}
                              className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-red-50">
                              <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>delete</span>
                            </button>
                          </div>
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
                    {listHeaders.map(h => (
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
                        const isActive = agentIsActive(agent)
                        const ssBg = isActive ? '#22C55E18' : '#EF444418'
                        const ssText = isActive ? '#22C55E' : '#EF4444'
                        const ssLabel = isActive ? t('agent_active') : t('agent_inactive')
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
                            <td className="px-5 py-3.5 text-sm text-[#64748B]">{roleLabel(agent.role)}</td>
                            <td className="px-5 py-3.5"><span className="px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: ssBg, color: ssText }}>{ssLabel}</span></td>
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
                              <div className="flex items-center gap-1.5">
                                <button
                                  onClick={() => toggleActive(agent)}
                                  disabled={togglingId === agent.id}
                                  className={`text-xs px-2 py-1 rounded-lg font-medium transition-colors disabled:opacity-50
                                    ${agent.is_active ? 'bg-red-50 text-red-500 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'}`}>
                                  {togglingId === agent.id ? '…' : agent.is_active ? t('btn_deactivate') : t('btn_activate')}
                                </button>
                                <button onClick={() => openEditAgent(agent)} title={t('btn_edit')}
                                  className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-[#eceef3]">
                                  <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 16 }}>edit</span>
                                </button>
                                <button onClick={() => { setDeleteTarget(agent); setDeleteError(null) }} title={t('btn_delete')}
                                  className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-red-50">
                                  <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>delete</span>
                                </button>
                              </div>
                            </td>
                          </tr>
                        )
                      })}
                </tbody>
              </table>
              {!loading && staff.length === 0 && (
                <div className="flex flex-col items-center justify-center py-16 text-[#94A3B8]">
                  <span className="material-symbols-outlined mb-3" style={{ fontSize: 40 }}>search_off</span>
                  <p className="text-sm">{t('no_agents_found')}</p>
                </div>
              )}
            </div>
          )}

          {!loading && view === 'grid' && staff.length === 0 && (
            <div className="flex flex-col items-center justify-center py-16 text-[#94A3B8] bg-white rounded-xl border border-[#E2E8F0]">
              <span className="material-symbols-outlined mb-3" style={{ fontSize: 40 }}>search_off</span>
              <p className="text-sm">{t('no_agents_found')}</p>
            </div>
          )}

          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-4">
              <span className="text-sm text-[#64748B]">
                {t('page_word')} {page} {t('of_word')} {totalPages} · {total.toLocaleString()} {t('results')}
              </span>
              <div className="flex items-center gap-2">
                <button disabled={page === 1} onClick={() => setPage(p => p - 1)}
                  className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe]">
                  {t('prev')}
                </button>
                <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}
                  className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe]">
                  {t('next')}
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Detail panel */}
        {detail && (() => {
          const isActive = agentIsActive(detail)
          const ssBg = isActive ? '#22C55E18' : '#EF444418'
          const ssText = isActive ? '#22C55E' : '#EF4444'
          const ssLabel = isActive ? t('agent_active') : t('agent_inactive')
          const s = statsMap[detail.id] ?? { assigned: 0, resolved: 0, inProgress: 0, performance: 0 }
          const pc = perfColor(s.performance)
          return (
            <div className="w-80 flex-shrink-0 bg-white rounded-xl border border-[#E2E8F0] shadow-sm sticky top-24 max-h-[calc(100vh-7rem)] flex flex-col overflow-hidden">
              <div className="px-5 py-4 border-b border-[#E2E8F0] flex items-center justify-between flex-shrink-0">
                <h4 className="text-[#181c20] font-semibold text-sm">{t('panel_agent')}</h4>
                <button onClick={() => setSelectedId(null)} className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                  <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 18 }}>close</span>
                </button>
              </div>

              <div className="flex-1 overflow-y-auto">
                <div className="p-5">
                  <div className="flex flex-col items-center mb-5 text-center">
                    <div className="w-16 h-16 rounded-full bg-[#0038AF] text-white flex items-center justify-center text-xl font-bold mb-3">{initials(detail.full_name)}</div>
                    <p className="text-base font-bold text-[#181c20]">{detail.full_name}</p>
                    <p className="text-sm text-[#64748B]">{roleLabel(detail.role)}</p>
                    <span className="mt-2 px-2.5 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: ssBg, color: ssText }}>{ssLabel}</span>
                  </div>

                  <div className="grid grid-cols-3 gap-2 mb-4">
                    {[
                      { label: t('stat_assigned'), value: s.assigned, color: '#0038AF' },
                      { label: t('stat_resolved_n'), value: s.resolved, color: '#22C55E' },
                      { label: t('stat_in_prog'), value: s.inProgress, color: '#F97316' },
                    ].map(x => (
                      <div key={x.label} className="text-center p-2 rounded-lg" style={{ backgroundColor: `${x.color}10` }}>
                        <p className="text-xl font-bold" style={{ color: x.color }}>{x.value}</p>
                        <p className="text-[10px] text-[#64748B]">{x.label}</p>
                      </div>
                    ))}
                  </div>

                  <div className="mb-4">
                    <div className="flex justify-between items-center mb-1.5">
                      <span className="text-xs font-semibold text-[#64748B]">{t('performance')}</span>
                      <span className="text-sm font-bold" style={{ color: pc }}>{s.performance}%</span>
                    </div>
                    <div className="w-full h-2 bg-[#f1f4f9] rounded-full overflow-hidden">
                      <div className="h-full rounded-full" style={{ width: `${s.performance}%`, backgroundColor: pc }} />
                    </div>
                  </div>

                  {detail.email && <div className="flex items-center gap-2 text-sm text-[#64748B] mb-1.5"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>email</span><span className="truncate">{detail.email}</span></div>}
                  {detail.phone && <div className="flex items-center gap-2 text-sm text-[#64748B] mb-3"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>phone</span><span>{detail.phone}</span></div>}
                  <p className="text-xs text-[#94A3B8] mb-4">{t('member_since')} {new Date(detail.created_at).toLocaleDateString(locale, { month: 'long', year: 'numeric' })}</p>

                  <button onClick={() => toggleActive(detail)} disabled={togglingId === detail.id}
                    className={`w-full py-2 rounded-xl text-sm font-medium transition-colors disabled:opacity-50
                      ${detail.is_active ? 'bg-red-50 text-red-500 hover:bg-red-100 border border-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100 border border-green-100'}`}>
                    {togglingId === detail.id ? t('updating') : detail.is_active ? t('btn_deactivate_account') : t('btn_activate_account')}
                  </button>
                  <div className="flex gap-2 mt-2">
                    <button onClick={() => openEditAgent(detail)}
                      className="flex-1 py-2 rounded-xl text-sm font-medium bg-[#f1f4f9] text-[#181c20] hover:bg-[#e2e8f0] transition-colors">
                      {t('btn_edit')}
                    </button>
                    <button onClick={() => { setDeleteTarget(detail); setDeleteError(null) }}
                      className="flex-1 py-2 rounded-xl text-sm font-medium bg-red-50 text-red-500 hover:bg-red-100 transition-colors">
                      {t('btn_delete')}
                    </button>
                  </div>
                </div>

                <div className="border-t border-[#E2E8F0] px-5 py-4">
                  <div className="flex items-center justify-between mb-3">
                    <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider">{t('missions_active')}</p>
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
                      <p className="text-xs text-[#94A3B8] mt-1">{t('missions_none')}</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {missions.map(m => {
                        const color = missionStatusColor[m.status] ?? '#94A3B8'
                        const label = missionStatusLabel(m.status)
                        return (
                          <div key={m.id} className="w-full text-left px-3 py-2.5 bg-[#f7f9fe] rounded-lg border border-[#E2E8F0]">
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
                <h3 className="text-base font-bold text-[#181c20]">{t('modal_add_title')}</h3>
                <p className="text-xs text-[#64748B] mt-0.5">{t('modal_add_sub')}</p>
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
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_full_name')}</label>
                  <input value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
                    placeholder="ex: Sami Mejri"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_email_f')}</label>
                  <input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                    placeholder="agent@sahali.tn"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_phone_f')}</label>
                  <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                    placeholder="+216 XX XXX XXX"
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_role_f')}</label>
                  <select value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                    {roleOptions.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_municipality_f')}</label>
                  <select value={form.municipality_id} onChange={e => setForm(f => ({ ...f, municipality_id: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                    <option value="">{t('select_option')}</option>
                    {municipalities.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                  </select>
                </div>
                <div className="col-span-2">
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_password_f')}</label>
                  <input type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                    placeholder={t('ph_password_min')}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3">
              <button onClick={() => setShowAdd(false)}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                {t('btn_cancel')}
              </button>
              <button onClick={submitAdd} disabled={submitting}
                className="flex-1 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                {submitting ? t('creating') : t('btn_create_account')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Agent Modal */}
      {editingAgent && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
          onClick={e => { if (e.target === e.currentTarget) setEditingAgent(null) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-5 border-b border-[#E2E8F0] flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-[#181c20]">{t('btn_edit')}</h3>
                <p className="text-xs text-[#64748B] mt-0.5">{editingAgent.full_name}</p>
              </div>
              <button onClick={() => setEditingAgent(null)} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>close</span>
              </button>
            </div>
            <div className="p-6 space-y-4">
              {editError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3">
                  <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
                  <span className="text-sm text-red-600">{editError}</span>
                </div>
              )}
              <div>
                <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_full_name')}</label>
                <input value={editForm.full_name} onChange={e => setEditForm(f => ({ ...f, full_name: e.target.value }))}
                  className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_role_f')}</label>
                  <select value={editForm.role} onChange={e => setEditForm(f => ({ ...f, role: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                    {roleOptions.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_municipality_f')}</label>
                  <select value={editForm.municipality_id} onChange={e => setEditForm(f => ({ ...f, municipality_id: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                    <option value="">{t('select_option')}</option>
                    {municipalities.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                  </select>
                </div>
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3">
              <button onClick={() => setEditingAgent(null)}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                {t('btn_cancel')}
              </button>
              <button onClick={submitEdit} disabled={savingEdit}
                className="flex-1 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                {savingEdit ? t('saving') : t('btn_save')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete confirm */}
      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
          onClick={e => { if (e.target === e.currentTarget) setDeleteTarget(null) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-full bg-red-50 flex items-center justify-center flex-shrink-0">
                <span className="material-symbols-outlined text-red-500" style={{ fontSize: 20 }}>warning</span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#181c20]">{t('confirm_delete_agent_title')}</h3>
                <p className="text-xs text-[#64748B]">{deleteTarget.full_name}</p>
              </div>
            </div>
            <p className="text-sm text-[#64748B] mb-4">{t('confirm_delete_agent_body')}</p>
            {deleteError && (
              <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
                <span className="text-sm text-red-600">{deleteError}</span>
              </div>
            )}
            <div className="flex gap-3">
              <button onClick={() => setDeleteTarget(null)}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                {t('btn_cancel')}
              </button>
              <button onClick={confirmDeleteAgent} disabled={deleting}
                className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                {deleting ? t('deleting') : t('btn_delete')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
