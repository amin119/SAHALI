import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { api } from '../lib/api'
import type { Report, Category, User, Assignment, ResolutionReport, StatusHistoryEntry, UserListOut, ReportStatus } from '../types/api'
import { useReportEvents } from '../hooks/useReportEvents'
import { useLang } from '../context/LangContext'
import { STATUS_LABELS, NEXT_STATUSES, JOURNEY_STEPS, displayCity, displayAddress } from '../lib/reportStatus'
import StatusBadge, { PriorityBadge } from '../components/ui/StatusBadge'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import { TextField, TextArea } from '../components/ui/TextField'
import InfoRow from '../components/ui/InfoRow'
import MediaGrid from '../components/ui/MediaGrid'
import Timeline from '../components/ui/Timeline'
import EmptyState from '../components/ui/EmptyState'
import Stepper from '../components/ui/Stepper'

export default function ReportDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { t, lang } = useLang()

  const [report, setReport] = useState<Report | null>(null)
  const [notFound, setNotFound] = useState(false)
  const [loading, setLoading] = useState(true)

  const [assignments, setAssignments] = useState<Assignment[]>([])
  const [history, setHistory] = useState<StatusHistoryEntry[]>([])
  const [resolution, setResolution] = useState<ResolutionReport | null>(null)
  const [categories, setCategories] = useState<Record<number, Category>>({})
  const [staffUsers, setStaffUsers] = useState<User[]>([])

  const [selectedAgents, setSelectedAgents] = useState<string[]>([])
  const [assignNote, setAssignNote] = useState('')
  const [assigning, setAssigning] = useState(false)

  const [updatingStatus, setUpdatingStatus] = useState(false)
  const [statusNote, setStatusNote] = useState('')
  const [pendingStatus, setPendingStatus] = useState<ReportStatus | null>(null)

  const [resComment, setResComment] = useState('')
  const [resMaterials, setResMaterials] = useState('')
  const [submittingRes, setSubmittingRes] = useState(false)

  const fetchReport = useCallback(() => {
    if (!id) return
    setNotFound(false)
    api.get<Report>(`/reports/${id}`)
      .then(setReport)
      .catch(() => { setNotFound(true); setLoading(false) })
  }, [id])

  useEffect(() => { setLoading(true); fetchReport() }, [fetchReport])
  useReportEvents(fetchReport)

  useEffect(() => {
    api.get<Category[]>('/categories')
      .then(cats => {
        const map: Record<number, Category> = {}
        cats.forEach(c => { map[c.id] = c; c.children?.forEach(child => { map[child.id] = child }) })
        setCategories(map)
      })
      .catch(() => {})
    api.get<UserListOut>('/admin/users', { page_size: 200 })
      .then(data => setStaffUsers((data.items ?? []).filter(u => ['field_agent', 'analyst', 'supervisor'].includes(u.role))))
      .catch(() => {})
  }, [])

  useEffect(() => {
    if (!report) return
    Promise.all([
      api.get<Assignment[]>(`/reports/${report.id}/assignments`).catch(() => []),
      api.get<StatusHistoryEntry[]>(`/reports/${report.id}/history`).catch(() => []),
      report.status === 'resolved'
        ? api.get<ResolutionReport>(`/reports/${report.id}/resolution-report`).catch(() => null)
        : Promise.resolve(null),
    ]).then(([a, h, r]) => {
      setAssignments(a ?? [])
      setHistory(h ?? [])
      setResolution(r)
      setSelectedAgents((a ?? []).filter(x => x.is_active).map(x => x.agent.id))
    }).finally(() => setLoading(false))
  }, [report?.id, report?.status])

  async function updateStatus(newStatus: ReportStatus) {
    if (!report) return
    setUpdatingStatus(true)
    try {
      const updated = await api.patch<Report>(`/reports/${report.id}/status`, {
        status: newStatus,
        note: statusNote || undefined,
      })
      setReport(updated)
      setPendingStatus(null)
      setStatusNote('')
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Erreur lors de la mise à jour')
    } finally {
      setUpdatingStatus(false)
    }
  }

  async function submitAssignment() {
    if (!report || selectedAgents.length === 0) return
    setAssigning(true)
    try {
      const newAssignments = await api.post<Assignment[]>(`/reports/${report.id}/assign`, {
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
    if (!report || !resComment) return
    setSubmittingRes(true)
    try {
      const rr = await api.post<ResolutionReport>(`/reports/${report.id}/resolution-report`, {
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

  if (notFound) {
    return (
      <div className="max-w-2xl mx-auto">
        <EmptyState icon="search_off" message="Signalement introuvable" />
        <div className="flex justify-center mt-4">
          <Button variant="secondary" icon="arrow_back" onClick={() => navigate('/reports')}>Retour aux signalements</Button>
        </div>
      </div>
    )
  }

  if (loading || !report) {
    return (
      <div className="max-w-3xl mx-auto space-y-6 animate-pulse">
        <div className="h-4 bg-[#E2E8F0] rounded w-40" />
        <div className="h-9 bg-[#E2E8F0] rounded w-72" />
        <div className="h-28 bg-[#E2E8F0] rounded-xl" />
        <div className="h-64 bg-[#E2E8F0] rounded-xl" />
      </div>
    )
  }

  const activeAssignments = assignments.filter(a => a.is_active)
  const pastAssignments = assignments.filter(a => !a.is_active)

  return (
    <div className="max-w-3xl mx-auto">
      <button
        onClick={() => navigate('/reports')}
        className="flex items-center gap-1.5 text-[#64748B] hover:text-[#181c20] text-sm font-medium mb-4 transition-colors"
      >
        <span className="material-symbols-outlined" style={{ fontSize: 18 }}>arrow_back</span>
        Retour aux signalements
      </button>

      <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3 mb-6">
        <div>
          <p className="text-xs font-mono text-[#94A3B8]">{report.tracking_code}</p>
          <h2 className="text-[#0F172A] text-2xl font-bold mt-1">{report.title}</h2>
        </div>
        <div className="flex items-center gap-2 flex-shrink-0">
          <StatusBadge status={report.status} />
          {report.priority && <PriorityBadge priority={report.priority} />}
        </div>
      </div>

      {/* Le parcours du signalement — la première chose à regarder */}
      <Card className="shadow-sm mb-6">
        <Stepper
          size="md"
          steps={JOURNEY_STEPS}
          currentIndex={Math.max(0, JOURNEY_STEPS.findIndex(s => s.key === report.status))}
          rejected={report.status === 'rejected'}
          rejectedLabel="Ce signalement a été rejeté"
        />
      </Card>

      {/* L'action à faire maintenant — la chose la plus importante de la page pour le personnel */}
      {NEXT_STATUSES[report.status] && (
        <Card className="shadow-sm p-6 mb-6">
          <p className="text-[#181c20] font-semibold text-base mb-3">{t('change_status')}</p>
          {pendingStatus ? (
            <div className="space-y-3">
              <p className="text-sm text-[#64748B]">{t('move_to')} <strong className="text-[#181c20]">{STATUS_LABELS[pendingStatus]}</strong></p>
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
                  disabled={updatingStatus || (pendingStatus === 'rejected' && !statusNote.trim())}
                  onClick={() => updateStatus(pendingStatus)}
                >
                  {updatingStatus ? t('loading') : t('btn_confirm')}
                </Button>
                <Button variant="secondary" onClick={() => { setPendingStatus(null); setStatusNote('') }}>
                  {t('btn_cancel')}
                </Button>
              </div>
            </div>
          ) : (
            <div className="flex flex-col sm:flex-row gap-2">
              {(NEXT_STATUSES[report.status] ?? []).map(s => (
                <button
                  key={s}
                  onClick={() => setPendingStatus(s)}
                  className={`flex-1 text-left px-4 py-3 rounded-lg border text-sm font-medium flex items-center justify-between transition-colors ${
                    s === 'rejected'
                      ? 'border-red-100 text-red-600 hover:bg-red-50'
                      : 'border-[#E2E8F0] text-[#181c20] hover:bg-[#f7f9fe] hover:border-[#0038AF]/30'
                  }`}
                >
                  {STATUS_LABELS[s]}
                  <span className="material-symbols-outlined" style={{ fontSize: 16, color: s === 'rejected' ? '#EF4444' : '#94A3B8' }}>arrow_forward</span>
                </button>
              ))}
            </div>
          )}
        </Card>
      )}

      {/* Détails du signalement */}
      <Card className="shadow-sm p-6 mb-6 space-y-4">
        <p className="text-[#181c20] font-semibold text-base">Détails du signalement</p>
        <InfoRow label="Catégorie">{categories[report.category_id]?.label_fr ?? `#${report.category_id}`}</InfoRow>
        <InfoRow label="Ville">{[displayAddress(report, lang), displayCity(report, lang)].filter(Boolean).join(', ') || '—'}</InfoRow>
        {report.lat != null && report.lng != null && (
          <InfoRow label="Coordonnées GPS">
            <a
              href={`https://www.google.com/maps?q=${report.lat},${report.lng}`}
              target="_blank" rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-[#f0f4ff] border border-[#0038AF]/20 hover:bg-[#e0e9ff] transition-colors group w-full sm:w-auto"
            >
              <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 16 }}>location_on</span>
              <span className="text-xs font-mono text-[#0038AF] flex-1">{report.lat.toFixed(6)}, {report.lng.toFixed(6)}</span>
              <span className="material-symbols-outlined text-[#0038AF] opacity-60 group-hover:opacity-100 transition-opacity" style={{ fontSize: 13 }}>open_in_new</span>
            </a>
          </InfoRow>
        )}
        {report.description && <InfoRow label="Description"><span className="text-[#64748B] leading-relaxed">{report.description}</span></InfoRow>}
        <MediaGrid photoUrls={report.photo_urls} photoUrl={report.photo_url} hint="Cliquer pour agrandir" />
        <InfoRow label="Soumis le">{new Date(report.created_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}</InfoRow>
        {report.resolved_at && (
          <InfoRow label="Résolu le">{new Date(report.resolved_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}</InfoRow>
        )}
      </Card>

      {/* Équipe assignée */}
      <Card className="shadow-sm p-6 mb-6 space-y-4">
        <p className="text-[#181c20] font-semibold text-base">{t('tab_assignment')}</p>
        {activeAssignments.length > 0 && (
          <div className="space-y-2">
            {activeAssignments.map(a => (
              <div key={a.id} className="flex items-center gap-2 px-3 py-2 bg-[#f7f9fe] rounded-lg">
                <div className="w-8 h-8 rounded-full bg-[#0038AF]/10 flex items-center justify-center">
                  <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 15 }}>person</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-[#181c20] truncate">{a.agent.full_name}</p>
                  <p className="text-xs text-[#94A3B8]">{t('assigned_by')} {a.assigned_by_user.full_name}</p>
                </div>
              </div>
            ))}
          </div>
        )}

        {report.status !== 'resolved' && report.status !== 'rejected' && (
          <div className={activeAssignments.length > 0 ? 'pt-3 border-t border-[#E2E8F0]' : ''}>
            <p className="text-[#94A3B8] text-xs font-medium mb-2">
              {activeAssignments.length > 0 ? t('reassign') : t('assign_agents')}
            </p>
            <div className="max-h-56 overflow-y-auto border border-[#E2E8F0] rounded-lg divide-y divide-[#E2E8F0] mb-2">
              {staffUsers.length === 0 ? (
                <EmptyState icon="group_off" message={t('no_agents')} size="sm" />
              ) : staffUsers.map(u => (
                <label key={u.id} className="flex items-center gap-2 px-3 py-2.5 hover:bg-[#f7f9fe] cursor-pointer">
                  <input
                    type="checkbox"
                    checked={selectedAgents.includes(u.id)}
                    onChange={e => setSelectedAgents(prev => e.target.checked ? [...prev, u.id] : prev.filter(id2 => id2 !== u.id))}
                    className="rounded"
                  />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[#181c20] truncate">{u.full_name}</p>
                    <p className="text-xs text-[#94A3B8] capitalize">{u.role.replace('_', ' ')}</p>
                  </div>
                  {selectedAgents.includes(u.id) && (
                    <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 16 }}>check_circle</span>
                  )}
                </label>
              ))}
            </div>
            <div className="mb-2">
              <TextField value={assignNote} onChange={e => setAssignNote(e.target.value)} placeholder={t('assign_note_placeholder')} />
            </div>
            <Button
              icon="group_add"
              disabled={assigning || selectedAgents.length === 0}
              onClick={submitAssignment}
            >
              {assigning ? t('assigning') : `${t('btn_assign')}${selectedAgents.length > 0 ? ` (${selectedAgents.length})` : ''}`}
            </Button>
          </div>
        )}

        {pastAssignments.length > 0 && (
          <div>
            <p className="text-[#94A3B8] text-xs font-medium mb-2">{t('assign_history')}</p>
            <div className="space-y-1.5">
              {pastAssignments.map(a => (
                <div key={a.id} className="flex items-center gap-2 px-2 py-1.5 rounded opacity-60">
                  <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 14 }}>person_off</span>
                  <p className="text-sm text-[#64748B]">{a.agent.full_name}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </Card>

      {/* Rapport de résolution — seulement pertinent une fois le signalement en cours ou terminé */}
      {(report.status === 'in_progress' || report.status === 'resolved') && (
        <Card className="shadow-sm p-6 mb-6 space-y-4">
          <p className="text-[#181c20] font-semibold text-base">{t('tab_report')}</p>
          {resolution ? (
            <>
              <InfoRow label="Résolu par">
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-full bg-green-100 flex items-center justify-center">
                    <span className="material-symbols-outlined text-green-600" style={{ fontSize: 14 }}>check</span>
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
              {report.resolved_at && (
                <InfoRow label="Date de résolution">
                  {new Date(report.resolved_at).toLocaleString('fr-FR', { dateStyle: 'long', timeStyle: 'short' })}
                </InfoRow>
              )}
              <p className="text-xs text-[#94A3B8]">
                Rapport créé le {new Date(resolution.created_at).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })}
              </p>
            </>
          ) : report.status === 'resolved' ? (
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
                  className="!bg-[#22C55E]"
                  disabled={submittingRes || !resComment}
                  onClick={submitResolution}
                >
                  {submittingRes ? 'Enregistrement...' : 'Créer le rapport'}
                </Button>
              </div>
            </div>
          ) : (
            <EmptyState icon="assignment_late" message="Disponible une fois le signalement résolu" size="sm" />
          )}
        </Card>
      )}

      {/* Historique détaillé */}
      <Card className="shadow-sm p-6">
        <p className="text-[#181c20] font-semibold text-base mb-4">{t('tab_history')}</p>
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
      </Card>
    </div>
  )
}
