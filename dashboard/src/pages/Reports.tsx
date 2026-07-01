import { useState, useEffect, useCallback } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { api, API_BASE } from '../lib/api'
import type { Report, ReportStatus, Category, User, Assignment, ResolutionReport, StatusHistoryEntry } from '../types/api'
import { useReportEvents } from '../hooks/useReportEvents'
import StatusBadge from '../components/ui/StatusBadge'
import { PRIORITY_COLORS, PRIORITY_LABELS } from '../data/mockData'
import { useLang } from '../context/LangContext'

const STATUS_LABELS: Record<ReportStatus, string> = {
  submitted:    'Nouveau',
  received:     'Reçu',
  under_review: 'En examen',
  in_progress:  'En cours',
  resolved:     'Résolu',
  rejected:     'Rejeté',
}

const NEXT_STATUSES: Partial<Record<ReportStatus, ReportStatus[]>> = {
  submitted:    ['received', 'rejected'],
  received:     ['under_review', 'rejected'],
  under_review: ['in_progress', 'rejected'],
  in_progress:  ['resolved', 'rejected'],
}

const ALL_STATUSES: ReportStatus[] = ['submitted', 'received', 'under_review', 'in_progress', 'resolved', 'rejected']

const PAGE_SIZE = 20

type DetailTab = 'info' | 'history' | 'assignation' | 'rapport'

export default function Reports() {
  const { t } = useLang()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [reports, setReports] = useState<Report[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState<ReportStatus | ''>('')
  const [selected, setSelected] = useState<string[]>([])
  const [detailReport, setDetailReport] = useState<Report | null>(null)
  const [activeTab, setActiveTab] = useState<DetailTab>('info')

  // Detail panel data
  const [assignments, setAssignments] = useState<Assignment[]>([])
  const [history, setHistory] = useState<StatusHistoryEntry[]>([])
  const [resolution, setResolution] = useState<ResolutionReport | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)

  // Assignment panel
  const [staffUsers, setStaffUsers] = useState<User[]>([])
  const [selectedAgents, setSelectedAgents] = useState<string[]>([])
  const [assignNote, setAssignNote] = useState('')
  const [assigning, setAssigning] = useState(false)

  // Status change
  const [categories, setCategories] = useState<Record<number, Category>>({})
  const [updatingStatus, setUpdatingStatus] = useState(false)
  const [statusNote, setStatusNote] = useState('')
  const [pendingStatus, setPendingStatus] = useState<ReportStatus | null>(null)

  // Resolution report form
  const [resComment, setResComment] = useState('')
  const [resMaterials, setResMaterials] = useState('')
  const [submittingRes, setSubmittingRes] = useState(false)

  useEffect(() => {
    api.get<Category[]>('/categories')
      .then(cats => {
        const map: Record<number, Category> = {}
        cats.forEach(c => {
          map[c.id] = c
          c.children?.forEach(child => { map[child.id] = child })
        })
        setCategories(map)
      })
      .catch(() => {})
    api.get<User[]>('/admin/users', { page_size: 200 })
      .then(data => setStaffUsers((Array.isArray(data) ? data : []).filter(u => ['field_agent', 'analyst', 'supervisor'].includes(u.role))))
      .catch(() => {})
  }, [])

  const fetchReports = useCallback(() => {
    setLoading(true)
    setError(null)
    const params: Record<string, string | number | undefined> = { page, page_size: PAGE_SIZE }
    if (filterStatus) params.status = filterStatus
    api.get<{ items: Report[]; total: number }>('/reports', params)
      .then(data => { setReports(data.items ?? []); setTotal(data.total ?? 0) })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [page, filterStatus])

  useEffect(() => { fetchReports() }, [fetchReports])
  useReportEvents(fetchReports)

  // Auto-open a specific report when navigated from a notification (?report=ID)
  useEffect(() => {
    const targetId = searchParams.get('report')
    if (!targetId) return
    // Try to find in current page first
    const found = reports.find(r => r.id === targetId)
    if (found) {
      openDetail(found)
      navigate('/reports', { replace: true })
      return
    }
    // Fetch it directly if not on current page
    api.get<Report>(`/reports/${targetId}`)
      .then(r => { openDetail(r); navigate('/reports', { replace: true }) })
      .catch(() => {})
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams, reports])

  // Load detail panel data whenever selection changes
  useEffect(() => {
    if (!detailReport) return
    const id = detailReport.id
    setDetailLoading(true)
    setAssignments([])
    setHistory([])
    setResolution(null)
    Promise.all([
      api.get<Assignment[]>(`/reports/${id}/assignments`).catch(() => []),
      api.get<StatusHistoryEntry[]>(`/reports/${id}/history`).catch(() => []),
      detailReport.status === 'resolved'
        ? api.get<ResolutionReport>(`/reports/${id}/resolution-report`).catch(() => null)
        : Promise.resolve(null),
    ]).then(([a, h, r]) => {
      setAssignments(a ?? [])
      setHistory(h ?? [])
      setResolution(r)
      setSelectedAgents((a ?? []).filter(x => x.is_active).map(x => x.agent.id))
    }).finally(() => setDetailLoading(false))
  }, [detailReport?.id, detailReport?.status])

  const filtered = search
    ? reports.filter(r => {
        const q = search.toLowerCase()
        return (
          r.tracking_code.toLowerCase().includes(q) ||
          r.title.toLowerCase().includes(q) ||
          (r.city ?? '').toLowerCase().includes(q) ||
          (r.address ?? '').toLowerCase().includes(q)
        )
      })
    : reports

  function toggleSelect(id: string) {
    setSelected(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])
  }

  function openDetail(r: Report) {
    if (detailReport?.id === r.id) { setDetailReport(null); return }
    setDetailReport(r)
    setActiveTab('info')
    setPendingStatus(null)
    setStatusNote('')
  }

  async function updateStatus(reportId: string, newStatus: ReportStatus) {
    setUpdatingStatus(true)
    try {
      const updated = await api.patch<Report>(`/reports/${reportId}/status`, {
        status: newStatus,
        note: statusNote || undefined,
      })
      setReports(prev => prev.map(r => r.id === reportId ? updated : r))
      setDetailReport(updated)
      setPendingStatus(null)
      setStatusNote('')
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Erreur lors de la mise à jour')
    } finally {
      setUpdatingStatus(false)
    }
  }

  async function submitAssignment() {
    if (!detailReport || selectedAgents.length === 0) return
    setAssigning(true)
    try {
      const newAssignments = await api.post<Assignment[]>(`/reports/${detailReport.id}/assign`, {
        agent_ids: selectedAgents,
        note: assignNote || undefined,
      })
      setAssignments(newAssignments)
      setAssignNote('')
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : "Erreur lors de l'assignation")
    } finally {
      setAssigning(false)
    }
  }

  async function submitResolution() {
    if (!detailReport || !resComment) return
    setSubmittingRes(true)
    try {
      const rr = await api.post<ResolutionReport>(`/reports/${detailReport.id}/resolution-report`, {
        comment: resComment,
        materials: resMaterials || undefined,
      })
      setResolution(rr)
      setResComment('')
      setResMaterials('')
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Erreur lors de la création du rapport')
    } finally {
      setSubmittingRes(false)
    }
  }

  const totalPages = Math.ceil(total / PAGE_SIZE)

  const TABS: { key: DetailTab; label: string; icon: string }[] = [
    { key: 'info',        label: t('tab_info'),       icon: 'info' },
    { key: 'history',     label: t('tab_history'),    icon: 'history' },
    { key: 'assignation', label: t('tab_assignment'), icon: 'group' },
    { key: 'rapport',     label: t('tab_report'),     icon: 'assignment' },
  ]

  return (
    <div className="flex gap-6 h-full">
      {/* Main Panel */}
      <div className="flex-1 min-w-0">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
          <div>
            <h2 className="text-[#0F172A] text-2xl font-bold">Signalements</h2>
            <p className="text-[#64748B] text-sm mt-1">
              {loading ? 'Chargement...' : `${total.toLocaleString('fr-FR')} signalements`}
            </p>
          </div>
          <button
            onClick={async () => {
              const base = import.meta.env.VITE_API_URL ?? 'http://localhost:8000'
              const token = localStorage.getItem('access_token')
              const res = await fetch(`${base}/v1/admin/reports/export`, {
                headers: { Authorization: `Bearer ${token}` },
              })
              if (!res.ok) return
              const blob = await res.blob()
              const url = URL.createObjectURL(blob)
              const a = document.createElement('a')
              a.href = url; a.download = 'signalements.csv'; a.click()
              URL.revokeObjectURL(url)
            }}
            className="bg-white border border-[#E2E8F0] text-[#64748B] px-4 py-2 rounded-xl flex items-center gap-2 text-sm font-medium hover:bg-[#f7f9fe] transition-colors"
          >
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>download</span>
            Exporter CSV
          </button>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-xl border border-[#E2E8F0] p-4 mb-4 flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-48">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#747686]" style={{ fontSize: 16 }}>search</span>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              type="text"
              placeholder="Rechercher par code, titre, ville..."
              className="w-full bg-[#f1f4f9] rounded-lg pl-9 pr-4 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 border-0"
            />
          </div>
          <select
            value={filterStatus}
            onChange={e => { setFilterStatus(e.target.value as ReportStatus | ''); setPage(1) }}
            className="bg-[#f1f4f9] rounded-lg px-3 py-2 text-sm outline-none border-0 text-[#181c20]"
          >
            <option value="">Tous les statuts</option>
            {ALL_STATUSES.map(s => <option key={s} value={s}>{STATUS_LABELS[s]}</option>)}
          </select>
        </div>

        {selected.length > 0 && (
          <div className="bg-[#0038AF]/10 border border-[#0038AF]/20 rounded-xl px-4 py-2 mb-4 flex items-center justify-between">
            <span className="text-[#0038AF] text-sm font-medium">
              {selected.length} sélectionné{selected.length > 1 ? 's' : ''}
            </span>
            <button className="text-[#ba1a1a] text-sm hover:underline" onClick={() => setSelected([])}>
              Désélectionner
            </button>
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
            <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
            <span className="text-sm text-red-600">{error}</span>
            <button onClick={fetchReports} className="ml-auto text-[#0038AF] text-sm hover:underline">Réessayer</button>
          </div>
        )}

        <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-[#f7f9fe] border-b border-[#E2E8F0]">
                <th className="w-10 px-4 py-3">
                  <input
                    type="checkbox"
                    className="rounded"
                    checked={selected.length === filtered.length && filtered.length > 0}
                    onChange={e => setSelected(e.target.checked ? filtered.map(r => r.id) : [])}
                  />
                </th>
                {['Code', 'Titre', 'Ville', 'Priorité', 'Statut', 'Date', ''].map(h => (
                  <th key={h} className="px-4 py-3 text-xs font-semibold text-[#64748B] uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2E8F0]">
              {loading
                ? Array.from({ length: 8 }).map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      {Array.from({ length: 8 }).map((__, j) => (
                        <td key={j} className="px-4 py-3.5"><div className="h-4 bg-[#E2E8F0] rounded w-20" /></td>
                      ))}
                    </tr>
                  ))
                : filtered.map(r => (
                    <tr
                      key={r.id}
                      onClick={() => openDetail(r)}
                      className={`hover:bg-[#f7f9fe] transition-colors cursor-pointer ${detailReport?.id === r.id ? 'bg-[#f1f4f9]' : ''}`}
                    >
                      <td className="px-4 py-3.5" onClick={e => e.stopPropagation()}>
                        <input type="checkbox" className="rounded" checked={selected.includes(r.id)} onChange={() => toggleSelect(r.id)} />
                      </td>
                      <td className="px-4 py-3.5 text-xs font-mono text-[#181c20] font-medium">{r.tracking_code}</td>
                      <td className="px-4 py-3.5 text-sm text-[#181c20] max-w-48 truncate">{r.title}</td>
                      <td className="px-4 py-3.5">
                        <div>
                          <p className="text-sm text-[#181c20]">{r.city}</p>
                          <p className="text-xs text-[#94A3B8] truncate max-w-32">{r.address}</p>
                        </div>
                      </td>
                      <td className="px-4 py-3.5">
                        {r.priority ? (
                          <span
                            className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-tight"
                            style={{ backgroundColor: `${PRIORITY_COLORS[r.priority]}18`, color: PRIORITY_COLORS[r.priority] }}
                          >
                            {PRIORITY_LABELS[r.priority]}
                          </span>
                        ) : <span className="text-xs text-[#94A3B8]">—</span>}
                      </td>
                      <td className="px-4 py-3.5"><StatusBadge status={r.status} /></td>
                      <td className="px-4 py-3.5 text-xs text-[#94A3B8]">
                        {new Date(r.created_at).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="px-4 py-3.5">
                        <button className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-[#eceef3]" onClick={e => e.stopPropagation()}>
                          <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 16 }}>more_vert</span>
                        </button>
                      </td>
                    </tr>
                  ))}
            </tbody>
          </table>
          {!loading && filtered.length === 0 && (
            <div className="flex flex-col items-center justify-center py-16 text-[#94A3B8]">
              <span className="material-symbols-outlined mb-3" style={{ fontSize: 40 }}>search_off</span>
              <p className="text-sm">Aucun signalement trouvé</p>
            </div>
          )}
        </div>

        {totalPages > 1 && (
          <div className="flex items-center justify-between mt-4">
            <span className="text-sm text-[#64748B]">Page {page} sur {totalPages} · {total.toLocaleString('fr-FR')} résultats</span>
            <div className="flex items-center gap-2">
              <button disabled={page === 1} onClick={() => setPage(p => p - 1)}
                className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe]">
                ← Précédent
              </button>
              <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}
                className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe]">
                Suivant →
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Detail Panel */}
      {detailReport && (
        <div className="w-96 flex-shrink-0 bg-white rounded-xl border border-[#E2E8F0] shadow-sm sticky top-24 max-h-[calc(100vh-7rem)] flex flex-col overflow-hidden">
          {/* Header */}
          <div className="px-5 py-4 border-b border-[#E2E8F0] flex items-center justify-between flex-shrink-0">
            <div>
              <p className="text-xs font-mono text-[#94A3B8]">{detailReport.tracking_code}</p>
              <h4 className="text-[#181c20] font-semibold text-sm leading-tight mt-0.5">{detailReport.title}</h4>
            </div>
            <button onClick={() => setDetailReport(null)} className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-[#f1f4f9] ml-2 flex-shrink-0">
              <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 18 }}>close</span>
            </button>
          </div>

          {/* Tabs */}
          <div className="flex border-b border-[#E2E8F0] flex-shrink-0 overflow-x-auto">
            {TABS.map(t => (
              <button
                key={t.key}
                onClick={() => setActiveTab(t.key)}
                className={`flex items-center gap-1.5 px-3 py-2.5 text-xs font-medium whitespace-nowrap border-b-2 transition-colors ${
                  activeTab === t.key
                    ? 'border-[#0038AF] text-[#0038AF]'
                    : 'border-transparent text-[#64748B] hover:text-[#181c20]'
                }`}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 14 }}>{t.icon}</span>
                {t.label}
                {t.key === 'assignation' && assignments.filter(a => a.is_active).length > 0 && (
                  <span className="bg-[#0038AF] text-white text-[9px] font-bold rounded-full w-4 h-4 flex items-center justify-center">
                    {assignments.filter(a => a.is_active).length}
                  </span>
                )}
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className="flex-1 overflow-y-auto">
            {detailLoading && (
              <div className="flex items-center justify-center py-8 text-[#94A3B8]">
                <span className="text-xs">Chargement...</span>
              </div>
            )}

            {/* ── Détail ── */}
            {!detailLoading && activeTab === 'info' && (
              <div className="p-5 space-y-4">
                <div className="flex items-center gap-2">
                  <StatusBadge status={detailReport.status} />
                  {detailReport.priority && (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-bold uppercase"
                      style={{ backgroundColor: `${PRIORITY_COLORS[detailReport.priority]}18`, color: PRIORITY_COLORS[detailReport.priority] }}>
                      {PRIORITY_LABELS[detailReport.priority]}
                    </span>
                  )}
                </div>
                <div>
                  <p className="text-[#94A3B8] text-xs mb-1">Catégorie</p>
                  <p className="text-sm text-[#181c20]">{categories[detailReport.category_id]?.label_fr ?? `#${detailReport.category_id}`}</p>
                </div>
                <div>
                  <p className="text-[#94A3B8] text-xs mb-1">Adresse</p>
                  <p className="text-sm text-[#181c20]">{[detailReport.address, detailReport.city].filter(Boolean).join(', ') || '—'}</p>
                </div>
                {detailReport.lat != null && detailReport.lng != null && (
                  <div>
                    <p className="text-[#94A3B8] text-xs mb-1.5">Coordonnées GPS</p>
                    <a
                      href={`https://www.google.com/maps?q=${detailReport.lat},${detailReport.lng}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-[#f0f4ff] border border-[#0038AF]/20 hover:bg-[#e0e9ff] transition-colors group w-full"
                    >
                      <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 16 }}>location_on</span>
                      <span className="text-xs font-mono text-[#0038AF] flex-1">
                        {detailReport.lat.toFixed(6)}, {detailReport.lng.toFixed(6)}
                      </span>
                      <span className="material-symbols-outlined text-[#0038AF] opacity-60 group-hover:opacity-100 transition-opacity" style={{ fontSize: 13 }}>open_in_new</span>
                    </a>
                  </div>
                )}
                {detailReport.description && (
                  <div>
                    <p className="text-[#94A3B8] text-xs mb-1">Description</p>
                    <p className="text-sm text-[#64748B] leading-relaxed">{detailReport.description}</p>
                  </div>
                )}
                {(() => {
                  // Build a deduplicated list from photo_urls, falling back to photo_url
                  const rawUrls: string[] = detailReport.photo_urls?.length
                    ? detailReport.photo_urls
                    : detailReport.photo_url ? [detailReport.photo_url] : []
                  // Resolve relative paths (/reports/photo/...) to full API URLs
                  const photos = rawUrls.map(u => u.startsWith('/') ? `${API_BASE}${u}` : u)
                  if (!photos.length) return null
                  return (
                    <div>
                      <p className="text-[#94A3B8] text-xs mb-2">
                        {photos.length > 1 ? `Photos (${photos.length})` : 'Photo'}
                      </p>
                      <div className={`grid gap-2 ${photos.length > 1 ? 'grid-cols-2' : 'grid-cols-1'}`}>
                        {photos.map((src, i) => (
                          <a key={i} href={src} target="_blank" rel="noopener noreferrer">
                            <img
                              src={src}
                              alt={`Photo ${i + 1}`}
                              className="w-full rounded-xl object-cover cursor-zoom-in hover:opacity-90 transition-opacity"
                              style={{ maxHeight: photos.length > 1 ? 120 : 200 }}
                              onError={e => { (e.currentTarget as HTMLImageElement).parentElement!.style.display = 'none' }}
                            />
                          </a>
                        ))}
                      </div>
                      <p className="text-[10px] text-[#94A3B8] mt-1">Cliquer pour agrandir</p>
                    </div>
                  )
                })()}
                <div>
                  <p className="text-[#94A3B8] text-xs mb-1">Soumis le</p>
                  <p className="text-sm text-[#181c20]">
                    {new Date(detailReport.created_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}
                  </p>
                </div>
                {detailReport.resolved_at && (
                  <div>
                    <p className="text-[#94A3B8] text-xs mb-1">Résolu le</p>
                    <p className="text-sm text-[#181c20]">
                      {new Date(detailReport.resolved_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}
                    </p>
                  </div>
                )}

                {/* Status transition */}
                {NEXT_STATUSES[detailReport.status] && (
                  <div className="pt-3 border-t border-[#E2E8F0]">
                    <p className="text-[#94A3B8] text-xs mb-2 font-medium">{t('change_status')}</p>
                    {pendingStatus ? (
                      <div className="space-y-2">
                        <p className="text-xs text-[#64748B]">
                          {t('move_to')} <strong>{STATUS_LABELS[pendingStatus]}</strong>
                        </p>
                        <div>
                          <label className="text-xs text-[#64748B] mb-1 block">
                            {pendingStatus === 'rejected' ? t('rejection_reason') : t('note_optional')}
                          </label>
                          <textarea
                            value={statusNote}
                            onChange={e => setStatusNote(e.target.value)}
                            placeholder={pendingStatus === 'rejected'
                              ? t('rejection_placeholder')
                              : t('note_optional')}
                            rows={pendingStatus === 'rejected' ? 3 : 2}
                            className={`w-full bg-[#f1f4f9] border rounded-lg px-3 py-2 text-xs outline-none resize-none transition-colors ${
                              pendingStatus === 'rejected' && !statusNote
                                ? 'border-red-200 focus:ring-2 focus:ring-red-200'
                                : 'border-0 focus:ring-2 focus:ring-[#0038AF]/20'
                            }`}
                          />
                          {pendingStatus === 'rejected' && !statusNote && (
                            <p className="text-[10px] text-red-500 mt-1">Le motif de rejet est obligatoire</p>
                          )}
                        </div>
                        <div className="flex gap-2">
                          <button
                            onClick={() => updateStatus(detailReport.id, pendingStatus)}
                            disabled={updatingStatus || (pendingStatus === 'rejected' && !statusNote.trim())}
                            className={`flex-1 py-2 rounded-lg text-xs font-medium transition-opacity disabled:opacity-50 ${
                              pendingStatus === 'rejected'
                                ? 'bg-red-500 text-white hover:opacity-90'
                                : 'bg-[#0038AF] text-white hover:opacity-90'
                            }`}>
                            {updatingStatus ? t('loading') : t('btn_confirm')}
                          </button>
                          <button onClick={() => { setPendingStatus(null); setStatusNote('') }}
                            className="flex-1 border border-[#E2E8F0] text-[#64748B] py-2 rounded-lg text-xs font-medium hover:bg-[#f7f9fe]">
                            {t('btn_cancel')}
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex flex-col gap-1.5">
                        {(NEXT_STATUSES[detailReport.status] ?? []).map(s => (
                          <button key={s} onClick={() => setPendingStatus(s)}
                            className={`w-full text-left px-3 py-2 rounded-lg border text-xs font-medium flex items-center justify-between transition-colors ${
                              s === 'rejected'
                                ? 'border-red-100 text-red-600 hover:bg-red-50'
                                : 'border-[#E2E8F0] text-[#181c20] hover:bg-[#f7f9fe] hover:border-[#0038AF]/30'
                            }`}>
                            {STATUS_LABELS[s]}
                            <span className="material-symbols-outlined" style={{ fontSize: 14, color: s === 'rejected' ? '#EF4444' : '#94A3B8' }}>arrow_forward</span>
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* ── Traçabilité ── */}
            {!detailLoading && activeTab === 'history' && (
              <div className="p-5">
                <p className="text-[#94A3B8] text-xs font-medium mb-3">Historique des statuts</p>
                {history.length === 0 ? (
                  <p className="text-xs text-[#94A3B8] text-center py-4">Aucun historique</p>
                ) : (
                  <div className="relative">
                    <div className="absolute left-3.5 top-0 bottom-0 w-px bg-[#E2E8F0]" />
                    <div className="space-y-4">
                      {history.map((h) => {
                        const statusLabel = STATUS_LABELS[h.to_status as ReportStatus] ?? h.to_status
                        return (
                          <div key={h.id} className="flex gap-3 relative">
                            <div className="w-7 h-7 rounded-full bg-[#f7f9fe] border border-[#E2E8F0] flex items-center justify-center flex-shrink-0 relative z-10">
                              <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 13 }}>
                                {h.to_status === 'resolved' ? 'check_circle' : h.to_status === 'rejected' ? 'cancel' : 'circle'}
                              </span>
                            </div>
                            <div className="flex-1 pt-0.5">
                              <p className="text-xs font-medium text-[#181c20]">{statusLabel}</p>
                              {h.changed_by_name && (
                                <p className="text-xs text-[#64748B]">par {h.changed_by_name}</p>
                              )}
                              {h.note && <p className="text-xs text-[#94A3B8] mt-0.5 italic">{h.note}</p>}
                              <p className="text-[10px] text-[#94A3B8] mt-0.5">
                                {new Date(h.created_at).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}
                              </p>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* ── Assignation ── */}
            {!detailLoading && activeTab === 'assignation' && (
              <div className="p-5 space-y-4">
                {/* Current assignees */}
                {assignments.filter(a => a.is_active).length > 0 && (
                  <div>
                    <p className="text-[#94A3B8] text-xs font-medium mb-2">{t('assigned_agents')}</p>
                    <div className="space-y-2">
                      {assignments.filter(a => a.is_active).map(a => (
                        <div key={a.id} className="flex items-center gap-2 px-3 py-2 bg-[#f7f9fe] rounded-lg">
                          <div className="w-6 h-6 rounded-full bg-[#0038AF]/10 flex items-center justify-center">
                            <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 12 }}>person</span>
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-medium text-[#181c20] truncate">{a.agent.full_name}</p>
                            <p className="text-[10px] text-[#94A3B8]">{t('assigned_by')} {a.assigned_by_user.full_name}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Assign form */}
                {detailReport.status !== 'resolved' && detailReport.status !== 'rejected' && (
                  <div className="pt-2 border-t border-[#E2E8F0]">
                    <p className="text-[#94A3B8] text-xs font-medium mb-2">
                      {assignments.filter(a => a.is_active).length > 0 ? t('reassign') : t('assign_agents')}
                    </p>
                    <div className="max-h-48 overflow-y-auto border border-[#E2E8F0] rounded-lg divide-y divide-[#E2E8F0] mb-2">
                      {staffUsers.length === 0 ? (
                        <p className="text-xs text-[#94A3B8] p-3 text-center">{t('no_agents')}</p>
                      ) : staffUsers.map(u => (
                        <label key={u.id} className="flex items-center gap-2 px-3 py-2.5 hover:bg-[#f7f9fe] cursor-pointer">
                          <input
                            type="checkbox"
                            checked={selectedAgents.includes(u.id)}
                            onChange={e => setSelectedAgents(prev =>
                              e.target.checked ? [...prev, u.id] : prev.filter(id => id !== u.id)
                            )}
                            className="rounded"
                          />
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-medium text-[#181c20] truncate">{u.full_name}</p>
                            <p className="text-[10px] text-[#94A3B8] capitalize">{u.role.replace('_', ' ')}</p>
                          </div>
                          {selectedAgents.includes(u.id) && (
                            <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 14 }}>check_circle</span>
                          )}
                        </label>
                      ))}
                    </div>
                    <input
                      value={assignNote}
                      onChange={e => setAssignNote(e.target.value)}
                      placeholder={t('assign_note_placeholder')}
                      className="w-full bg-[#f1f4f9] border-0 rounded-lg px-3 py-2 text-xs outline-none focus:ring-2 focus:ring-[#0038AF]/20 mb-2"
                    />
                    <button
                      onClick={submitAssignment}
                      disabled={assigning || selectedAgents.length === 0}
                      className="w-full bg-[#0038AF] text-white py-2 rounded-lg text-xs font-semibold hover:opacity-90 disabled:opacity-50 transition-opacity flex items-center justify-center gap-1.5"
                    >
                      <span className="material-symbols-outlined" style={{ fontSize: 14 }}>group_add</span>
                      {assigning ? t('assigning') : `${t('btn_assign')}${selectedAgents.length > 0 ? ` (${selectedAgents.length})` : ''}`}
                    </button>
                  </div>
                )}

                {/* Past assignments */}
                {assignments.filter(a => !a.is_active).length > 0 && (
                  <div>
                    <p className="text-[#94A3B8] text-xs font-medium mb-2">{t('assign_history')}</p>
                    <div className="space-y-1.5">
                      {assignments.filter(a => !a.is_active).map(a => (
                        <div key={a.id} className="flex items-center gap-2 px-2 py-1.5 rounded opacity-60">
                          <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 12 }}>person_off</span>
                          <p className="text-xs text-[#64748B]">{a.agent.full_name}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* ── Rapport de résolution ── */}
            {!detailLoading && activeTab === 'rapport' && (
              <div className="p-5 space-y-4">
                {detailReport.status !== 'resolved' ? (
                  <div className="text-center py-8">
                    <span className="material-symbols-outlined text-[#94A3B8] mb-2" style={{ fontSize: 36 }}>assignment_late</span>
                    <p className="text-xs text-[#94A3B8]">Disponible une fois le signalement résolu</p>
                  </div>
                ) : resolution ? (
                  <>
                    <div>
                      <p className="text-[#94A3B8] text-xs font-medium mb-1">Résolu par</p>
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-green-100 flex items-center justify-center">
                          <span className="material-symbols-outlined text-green-600" style={{ fontSize: 12 }}>check</span>
                        </div>
                        <p className="text-sm font-medium text-[#181c20]">{resolution.resolved_by_user.full_name}</p>
                      </div>
                    </div>
                    <div>
                      <p className="text-[#94A3B8] text-xs font-medium mb-1">Rapport d'intervention</p>
                      <p className="text-sm text-[#181c20] bg-[#f7f9fe] rounded-lg p-3 leading-relaxed">{resolution.comment}</p>
                    </div>
                    {resolution.materials && (
                      <div>
                        <p className="text-[#94A3B8] text-xs font-medium mb-1">Matériaux utilisés</p>
                        <p className="text-sm text-[#64748B]">{resolution.materials}</p>
                      </div>
                    )}
                    {assignments.filter(a => a.is_active).length > 0 && (
                      <div>
                        <p className="text-[#94A3B8] text-xs font-medium mb-1">Équipe</p>
                        <div className="flex flex-wrap gap-1.5">
                          {assignments.filter(a => a.is_active).map(a => (
                            <span key={a.id} className="text-xs bg-[#f1f4f9] text-[#64748B] px-2 py-0.5 rounded-full">
                              {a.agent.full_name}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                    {detailReport.resolved_at && (
                      <div>
                        <p className="text-[#94A3B8] text-xs font-medium mb-1">Date de résolution</p>
                        <p className="text-sm text-[#181c20]">
                          {new Date(detailReport.resolved_at).toLocaleString('fr-FR', { dateStyle: 'long', timeStyle: 'short' })}
                        </p>
                      </div>
                    )}
                    <p className="text-[10px] text-[#94A3B8]">
                      Rapport créé le {new Date(resolution.created_at).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}
                    </p>
                  </>
                ) : (
                  <div>
                    <p className="text-[#94A3B8] text-xs font-medium mb-3">Créer le rapport de résolution</p>
                    <div className="space-y-3">
                      <div>
                        <label className="text-xs text-[#64748B] mb-1 block">Compte-rendu d'intervention *</label>
                        <textarea
                          value={resComment}
                          onChange={e => setResComment(e.target.value)}
                          placeholder="Décrivez les actions réalisées..."
                          rows={4}
                          className="w-full bg-[#f1f4f9] border-0 rounded-lg px-3 py-2 text-xs outline-none focus:ring-2 focus:ring-[#0038AF]/20 resize-none"
                        />
                      </div>
                      <div>
                        <label className="text-xs text-[#64748B] mb-1 block">Matériaux utilisés</label>
                        <input
                          value={resMaterials}
                          onChange={e => setResMaterials(e.target.value)}
                          placeholder="Ex: 2 m³ de béton, signalétique..."
                          className="w-full bg-[#f1f4f9] border-0 rounded-lg px-3 py-2 text-xs outline-none focus:ring-2 focus:ring-[#0038AF]/20"
                        />
                      </div>
                      <button
                        onClick={submitResolution}
                        disabled={submittingRes || !resComment}
                        className="w-full bg-[#22C55E] text-white py-2 rounded-lg text-xs font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
                      >
                        {submittingRes ? 'Enregistrement...' : 'Créer le rapport'}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
