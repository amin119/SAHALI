import { useState, useEffect, useCallback } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { api } from '../lib/api'
import type { Report, ReportStatus, Category, User, Assignment, ResolutionReport, StatusHistoryEntry, UserListOut } from '../types/api'
import { useReportEvents } from '../hooks/useReportEvents'
import StatusBadge, { PriorityBadge } from '../components/ui/StatusBadge'
import { useLang } from '../context/LangContext'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import { TextField, TextArea, SelectField } from '../components/ui/TextField'
import DataTable, { type Column } from '../components/ui/DataTable'
import Pagination from '../components/ui/Pagination'
import PageHeader from '../components/ui/PageHeader'
import SelectionBar from '../components/ui/SelectionBar'
import ErrorBanner from '../components/ui/ErrorBanner'
import Tabs, { type TabItem } from '../components/ui/Tabs'
import InfoRow from '../components/ui/InfoRow'
import MediaGrid from '../components/ui/MediaGrid'
import Timeline from '../components/ui/Timeline'
import EmptyState from '../components/ui/EmptyState'

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

function displayCity(r: Pick<Report, 'city' | 'city_ar'>, lang: string): string | null {
  return lang === 'ar' ? (r.city_ar || r.city || null) : (r.city || r.city_ar || null)
}

function displayAddress(r: Pick<Report, 'address' | 'address_ar'>, lang: string): string | null {
  return lang === 'ar' ? (r.address_ar || r.address || null) : (r.address || r.address_ar || null)
}

export default function Reports() {
  const { t, lang } = useLang()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [reports, setReports] = useState<Report[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState<ReportStatus | ''>(
    () => (searchParams.get('status') as ReportStatus | null) ?? ''
  )
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
    api.get<UserListOut>('/admin/users', { page_size: 200 })
      .then(data => setStaffUsers((data.items ?? []).filter(u => ['field_agent', 'analyst', 'supervisor'].includes(u.role))))
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
    const found = reports.find(r => r.id === targetId)
    if (found) {
      openDetail(found)
      navigate('/reports', { replace: true })
      return
    }
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
          (r.address ?? '').toLowerCase().includes(q) ||
          (r.city_ar ?? '').toLowerCase().includes(q) ||
          (r.address_ar ?? '').toLowerCase().includes(q)
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

  async function exportCsv() {
    const base = import.meta.env.VITE_API_URL ?? 'http://localhost:8000'
    const token = localStorage.getItem('access_token')
    const res = await fetch(`${base}/v1/admin/reports/export`, { headers: { Authorization: `Bearer ${token}` } })
    if (!res.ok) return
    const blob = await res.blob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url; a.download = 'signalements.csv'; a.click()
    URL.revokeObjectURL(url)
  }

  const totalPages = Math.ceil(total / PAGE_SIZE)

  const tabs: TabItem<DetailTab>[] = [
    { key: 'info',        label: t('tab_info'),       icon: 'info' },
    { key: 'history',     label: t('tab_history'),    icon: 'history' },
    { key: 'assignation', label: t('tab_assignment'), icon: 'group', badge: assignments.filter(a => a.is_active).length },
    { key: 'rapport',     label: t('tab_report'),     icon: 'assignment' },
  ]

  const columns: Column<Report>[] = [
    { key: 'code', header: 'Code', render: r => <span className="text-xs font-mono text-[#181c20] font-medium">{r.tracking_code}</span> },
    { key: 'title', header: 'Titre', render: r => <span className="text-sm text-[#181c20] block max-w-48 truncate">{r.title}</span> },
    { key: 'city', header: 'Ville', render: r => (
      <div>
        <p className="text-sm text-[#181c20]">{displayCity(r, lang)}</p>
        <p className="text-xs text-[#94A3B8] truncate max-w-32">{displayAddress(r, lang)}</p>
      </div>
    ) },
    { key: 'priority', header: 'Priorité', render: r => r.priority ? <PriorityBadge priority={r.priority} /> : <span className="text-xs text-[#94A3B8]">—</span> },
    { key: 'status', header: 'Statut', render: r => <StatusBadge status={r.status} /> },
    { key: 'date', header: 'Date', render: r => <span className="text-xs text-[#94A3B8]">{new Date(r.created_at).toLocaleDateString('fr-FR')}</span> },
    { key: 'actions', header: '', render: () => (
      <button className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-[#eceef3]" onClick={e => e.stopPropagation()}>
        <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 16 }}>more_vert</span>
      </button>
    ) },
  ]

  return (
    <div className="flex flex-col lg:flex-row gap-6 h-full">
      {/* Main Panel */}
      <div className="flex-1 min-w-0">
        <PageHeader
          title="Signalements"
          subtitle={loading ? 'Chargement...' : `${total.toLocaleString('fr-FR')} signalements`}
          actions={<Button variant="secondary" icon="download" onClick={exportCsv}>Exporter CSV</Button>}
        />

        <Card className="p-4 mb-4 flex flex-wrap items-center gap-3">
          <div className="flex-1 min-w-48">
            <TextField icon="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher par code, titre, ville..." />
          </div>
          <SelectField
            value={filterStatus}
            onChange={v => { setFilterStatus(v as ReportStatus | ''); setPage(1) }}
            placeholder="Tous les statuts"
            options={ALL_STATUSES.map(s => ({ value: s, label: STATUS_LABELS[s] }))}
          />
        </Card>

        <SelectionBar count={selected.length} onClear={() => setSelected([])} />
        {error && <ErrorBanner message={error} onRetry={fetchReports} />}

        <DataTable
          columns={columns}
          rows={filtered}
          rowKey={r => r.id}
          loading={loading}
          onRowClick={openDetail}
          isRowActive={r => detailReport?.id === r.id}
          selectable
          selected={selected}
          onToggleSelect={toggleSelect}
          onToggleSelectAll={checked => setSelected(checked ? filtered.map(r => r.id) : [])}
          emptyMessage="Aucun signalement trouvé"
        />

        <Pagination page={page} totalPages={totalPages} total={total} onChange={setPage} />
      </div>

      {/* Detail Panel — full-screen overlay below lg (a fixed side panel would
          crush the table on a phone-width screen), a sticky side panel at lg+ */}
      {detailReport && (
        <div className="fixed inset-0 z-50 bg-white flex flex-col
          lg:static lg:inset-auto lg:z-auto lg:w-96 lg:flex-shrink-0 lg:rounded-xl lg:border lg:border-[#E2E8F0] lg:shadow-sm lg:sticky lg:top-24 lg:max-h-[calc(100vh-7rem)] overflow-hidden">
          <div className="px-5 py-4 border-b border-[#E2E8F0] flex items-center justify-between flex-shrink-0">
            <div>
              <p className="text-xs font-mono text-[#94A3B8]">{detailReport.tracking_code}</p>
              <h4 className="text-[#181c20] font-semibold text-sm leading-tight mt-0.5">{detailReport.title}</h4>
            </div>
            <button onClick={() => setDetailReport(null)} className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-[#f1f4f9] ml-2 flex-shrink-0">
              <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 18 }}>close</span>
            </button>
          </div>

          <Tabs tabs={tabs} active={activeTab} onChange={setActiveTab} />

          <div className="flex-1 overflow-y-auto">
            {detailLoading && (
              <div className="flex items-center justify-center py-8 text-[#94A3B8]"><span className="text-xs">Chargement...</span></div>
            )}

            {!detailLoading && activeTab === 'info' && (
              <div className="p-5 space-y-4">
                <div className="flex items-center gap-2">
                  <StatusBadge status={detailReport.status} />
                  {detailReport.priority && <PriorityBadge priority={detailReport.priority} />}
                </div>
                <InfoRow label="Catégorie">{categories[detailReport.category_id]?.label_fr ?? `#${detailReport.category_id}`}</InfoRow>
                <InfoRow label="Ville">{[displayAddress(detailReport, lang), displayCity(detailReport, lang)].filter(Boolean).join(', ') || '—'}</InfoRow>
                {detailReport.lat != null && detailReport.lng != null && (
                  <InfoRow label="Coordonnées GPS">
                    <a
                      href={`https://www.google.com/maps?q=${detailReport.lat},${detailReport.lng}`}
                      target="_blank" rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-[#f0f4ff] border border-[#0038AF]/20 hover:bg-[#e0e9ff] transition-colors group w-full"
                    >
                      <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 16 }}>location_on</span>
                      <span className="text-xs font-mono text-[#0038AF] flex-1">{detailReport.lat.toFixed(6)}, {detailReport.lng.toFixed(6)}</span>
                      <span className="material-symbols-outlined text-[#0038AF] opacity-60 group-hover:opacity-100 transition-opacity" style={{ fontSize: 13 }}>open_in_new</span>
                    </a>
                  </InfoRow>
                )}
                {detailReport.description && <InfoRow label="Description"><span className="text-[#64748B] leading-relaxed">{detailReport.description}</span></InfoRow>}
                <MediaGrid photoUrls={detailReport.photo_urls} photoUrl={detailReport.photo_url} hint="Cliquer pour agrandir" />
                <InfoRow label="Soumis le">{new Date(detailReport.created_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}</InfoRow>
                {detailReport.resolved_at && (
                  <InfoRow label="Résolu le">{new Date(detailReport.resolved_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}</InfoRow>
                )}

                {NEXT_STATUSES[detailReport.status] && (
                  <div className="pt-3 border-t border-[#E2E8F0]">
                    <p className="text-[#94A3B8] text-xs mb-2 font-medium">{t('change_status')}</p>
                    {pendingStatus ? (
                      <div className="space-y-2">
                        <p className="text-xs text-[#64748B]">{t('move_to')} <strong>{STATUS_LABELS[pendingStatus]}</strong></p>
                        <TextArea
                          label={pendingStatus === 'rejected' ? t('rejection_reason') : t('note_optional')}
                          value={statusNote}
                          onChange={e => setStatusNote(e.target.value)}
                          placeholder={pendingStatus === 'rejected' ? t('rejection_placeholder') : t('note_optional')}
                          rows={pendingStatus === 'rejected' ? 3 : 2}
                          error={pendingStatus === 'rejected' && !statusNote ? 'Le motif de rejet est obligatoire' : undefined}
                        />
                        <div className="flex gap-2">
                          <Button
                            variant={pendingStatus === 'rejected' ? 'danger' : 'primary'}
                            size="sm"
                            fullWidth
                            disabled={updatingStatus || (pendingStatus === 'rejected' && !statusNote.trim())}
                            onClick={() => updateStatus(detailReport.id, pendingStatus)}
                          >
                            {updatingStatus ? t('loading') : t('btn_confirm')}
                          </Button>
                          <Button variant="secondary" size="sm" fullWidth onClick={() => { setPendingStatus(null); setStatusNote('') }}>
                            {t('btn_cancel')}
                          </Button>
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

            {!detailLoading && activeTab === 'history' && (
              <div className="p-5">
                <p className="text-[#94A3B8] text-xs font-medium mb-3">Historique des statuts</p>
                <Timeline
                  emptyMessage="Aucun historique"
                  items={history.map(h => ({
                    id: h.id,
                    icon: h.to_status === 'resolved' ? 'check_circle' : h.to_status === 'rejected' ? 'cancel' : 'circle',
                    title: STATUS_LABELS[h.to_status as ReportStatus] ?? h.to_status,
                    subtitle: h.changed_by_name ? `par ${h.changed_by_name}` : undefined,
                    note: h.note ?? undefined,
                    date: new Date(h.created_at).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' }),
                  }))}
                />
              </div>
            )}

            {!detailLoading && activeTab === 'assignation' && (
              <div className="p-5 space-y-4">
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

                {detailReport.status !== 'resolved' && detailReport.status !== 'rejected' && (
                  <div className="pt-2 border-t border-[#E2E8F0]">
                    <p className="text-[#94A3B8] text-xs font-medium mb-2">
                      {assignments.filter(a => a.is_active).length > 0 ? t('reassign') : t('assign_agents')}
                    </p>
                    <div className="max-h-48 overflow-y-auto border border-[#E2E8F0] rounded-lg divide-y divide-[#E2E8F0] mb-2">
                      {staffUsers.length === 0 ? (
                        <EmptyState icon="group_off" message={t('no_agents')} size="sm" />
                      ) : staffUsers.map(u => (
                        <label key={u.id} className="flex items-center gap-2 px-3 py-2.5 hover:bg-[#f7f9fe] cursor-pointer">
                          <input
                            type="checkbox"
                            checked={selectedAgents.includes(u.id)}
                            onChange={e => setSelectedAgents(prev => e.target.checked ? [...prev, u.id] : prev.filter(id => id !== u.id))}
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
                    <div className="mb-2">
                      <TextField value={assignNote} onChange={e => setAssignNote(e.target.value)} placeholder={t('assign_note_placeholder')} />
                    </div>
                    <Button
                      icon="group_add"
                      fullWidth
                      size="sm"
                      disabled={assigning || selectedAgents.length === 0}
                      onClick={submitAssignment}
                    >
                      {assigning ? t('assigning') : `${t('btn_assign')}${selectedAgents.length > 0 ? ` (${selectedAgents.length})` : ''}`}
                    </Button>
                  </div>
                )}

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

            {!detailLoading && activeTab === 'rapport' && (
              <div className="p-5 space-y-4">
                {detailReport.status !== 'resolved' ? (
                  <EmptyState icon="assignment_late" message="Disponible une fois le signalement résolu" size="sm" />
                ) : resolution ? (
                  <>
                    <InfoRow label="Résolu par">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-green-100 flex items-center justify-center">
                          <span className="material-symbols-outlined text-green-600" style={{ fontSize: 12 }}>check</span>
                        </div>
                        <span className="font-medium">{resolution.resolved_by_user.full_name}</span>
                      </div>
                    </InfoRow>
                    <InfoRow label="Rapport d'intervention">
                      <p className="bg-[#f7f9fe] rounded-lg p-3 leading-relaxed">{resolution.comment}</p>
                    </InfoRow>
                    {resolution.materials && <InfoRow label="Matériaux utilisés"><span className="text-[#64748B]">{resolution.materials}</span></InfoRow>}
                    <MediaGrid
                      photoUrls={resolution.photo_urls}
                      photoUrl={resolution.photo_url}
                      videoUrl={resolution.video_url ?? undefined}
                      voiceNoteUrl={resolution.voice_note_url ?? undefined}
                    />
                    {assignments.filter(a => a.is_active).length > 0 && (
                      <InfoRow label="Équipe">
                        <div className="flex flex-wrap gap-1.5">
                          {assignments.filter(a => a.is_active).map(a => (
                            <span key={a.id} className="text-xs bg-[#f1f4f9] text-[#64748B] px-2 py-0.5 rounded-full">{a.agent.full_name}</span>
                          ))}
                        </div>
                      </InfoRow>
                    )}
                    {detailReport.resolved_at && (
                      <InfoRow label="Date de résolution">
                        {new Date(detailReport.resolved_at).toLocaleString('fr-FR', { dateStyle: 'long', timeStyle: 'short' })}
                      </InfoRow>
                    )}
                    <p className="text-[10px] text-[#94A3B8]">
                      Rapport créé le {new Date(resolution.created_at).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}
                    </p>
                  </>
                ) : (
                  <div>
                    <p className="text-[#94A3B8] text-xs font-medium mb-3">Créer le rapport de résolution</p>
                    <div className="space-y-3">
                      <TextArea
                        label="Compte-rendu d'intervention *"
                        value={resComment}
                        onChange={e => setResComment(e.target.value)}
                        placeholder="Décrivez les actions réalisées..."
                        rows={4}
                      />
                      <TextField
                        label="Matériaux utilisés"
                        value={resMaterials}
                        onChange={e => setResMaterials(e.target.value)}
                        placeholder="Ex: 2 m³ de béton, signalétique..."
                      />
                      <Button
                        fullWidth
                        size="sm"
                        className="!bg-[#22C55E]"
                        disabled={submittingRes || !resComment}
                        onClick={submitResolution}
                      >
                        {submittingRes ? 'Enregistrement...' : 'Créer le rapport'}
                      </Button>
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
