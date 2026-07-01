import { useState, useEffect, useCallback } from 'react'
import { api } from '../lib/api'
import type { Report, ReportStatus } from '../types/api'
import StatusBadge from '../components/ui/StatusBadge'
import { useLang } from '../context/LangContext'

const NEXT_STATUSES: Record<ReportStatus, ReportStatus[]> = {
  submitted:    ['received'],
  received:     ['under_review', 'rejected'],
  under_review: ['in_progress', 'rejected'],
  in_progress:  ['resolved', 'rejected'],
  resolved:     [],
  rejected:     [],
}

const PRIORITY_COLORS: Record<string, string> = {
  low: '#22C55E', medium: '#F59E0B', high: '#F97316', critical: '#EF4444',
}

function CardSkeleton() {
  return (
    <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4 mb-3 animate-pulse">
      <div className="h-4 bg-[#E2E8F0] rounded w-3/4 mb-2" />
      <div className="h-3 bg-[#E2E8F0] rounded w-1/2 mb-3" />
      <div className="flex gap-2">
        <div className="h-5 bg-[#E2E8F0] rounded-full w-16" />
        <div className="h-5 bg-[#E2E8F0] rounded-full w-16" />
      </div>
    </div>
  )
}

export default function Interventions() {
  const { t } = useLang()
  const [reports, setReports] = useState<Report[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<Report | null>(null)
  const [transitioning, setTransitioning] = useState(false)
  const [note, setNote] = useState('')

  const columns = [
    { id: 'reception',  label: t('int_reception'),       statuses: ['received'] as ReportStatus[],    color: '#0EA5E9' },
    { id: 'examen',     label: t('status_under_review'),  statuses: ['under_review'] as ReportStatus[], color: '#F59E0B' },
    { id: 'en_cours',   label: t('status_in_progress'),   statuses: ['in_progress'] as ReportStatus[],  color: '#0038AF' },
    { id: 'termines',   label: t('int_terminated'),        statuses: ['resolved'] as ReportStatus[],     color: '#22C55E' },
  ]

  const priorityLabel = (p: string) => t(
    p === 'low' ? 'priority_low' :
    p === 'medium' ? 'priority_medium' :
    p === 'high' ? 'priority_high' :
    p === 'critical' ? 'priority_critical' : 'priority_medium'
  )

  const statusLabel = (s: ReportStatus) => t(
    s === 'received' ? 'status_received' :
    s === 'under_review' ? 'status_under_review' :
    s === 'in_progress' ? 'status_in_progress' :
    s === 'resolved' ? 'status_resolved' :
    s === 'rejected' ? 'status_rejected' : 'status_received'
  )

  const load = useCallback(() => {
    setLoading(true)
    api.get<{ items: Report[]; total: number }>('/reports', { page_size: '200' })
      .then(d => setReports(d.items))
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => { load() }, [load])

  async function transition(reportId: string, newStatus: ReportStatus) {
    setTransitioning(true)
    try {
      const updated = await api.patch<Report>(`/reports/${reportId}/status`, { status: newStatus, note: note || undefined })
      setReports(prev => prev.map(r => r.id === reportId ? updated : r))
      setSelected(updated)
      setNote('')
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Erreur'
      setError(msg)
    } finally {
      setTransitioning(false)
    }
  }

  const groupedByColumn = columns.map(col => ({
    ...col,
    cards: reports.filter(r => (col.statuses as string[]).includes(r.status)),
  }))

  const nextStatuses = selected ? (NEXT_STATUSES[selected.status as ReportStatus] ?? []) : []

  return (
    <div className="flex flex-col h-full">
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_interventions')}</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? t('loading') : `${reports.length} ${t('reports_title').toLowerCase()}`}
          </p>
        </div>
        <button onClick={load} className="flex items-center gap-2 px-4 py-2 bg-white border border-[#E2E8F0] rounded-xl text-sm font-medium text-[#64748B] hover:bg-[#f7f9fe] transition-colors">
          <span className="material-symbols-outlined" style={{ fontSize: 18 }}>refresh</span>
          {t('refresh')}
        </button>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
          <button onClick={() => setError(null)} className="ml-auto text-red-400 hover:text-red-600">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>close</span>
          </button>
        </div>
      )}

      <div className="flex gap-4 flex-1 overflow-x-auto pb-4">
        {groupedByColumn.map(col => (
          <div key={col.id} className="flex-shrink-0 w-72">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: col.color }} />
                <span className="text-sm font-bold text-[#181c20]">{col.label}</span>
              </div>
              <span className="text-xs px-2 py-0.5 rounded-full font-bold"
                style={{ backgroundColor: `${col.color}18`, color: col.color }}>
                {loading ? '…' : col.cards.length}
              </span>
            </div>
            <div className="space-y-3 max-h-[calc(100vh-280px)] overflow-y-auto pr-1">
              {loading
                ? Array.from({ length: 3 }).map((_, i) => <CardSkeleton key={i} />)
                : col.cards.map(r => {
                    const pm = { label: priorityLabel(r.priority), color: PRIORITY_COLORS[r.priority] ?? '#F59E0B' }
                    const isSelected = selected?.id === r.id
                    return (
                      <div key={r.id} onClick={() => setSelected(isSelected ? null : r)}
                        className={`bg-white rounded-xl border shadow-sm p-4 cursor-pointer transition-all hover:shadow-md
                          ${isSelected ? 'border-[#0038AF] ring-1 ring-[#0038AF]' : 'border-[#E2E8F0]'}`}>
                        <div className="flex items-start justify-between mb-1.5">
                          <p className="text-xs font-mono text-[#94A3B8]">{r.tracking_code}</p>
                          <span className="text-xs font-bold px-1.5 py-0.5 rounded"
                            style={{ backgroundColor: `${pm.color}18`, color: pm.color }}>
                            {pm.label}
                          </span>
                        </div>
                        <p className="text-sm font-semibold text-[#181c20] mb-1 line-clamp-2">{r.title}</p>
                        <p className="text-xs text-[#64748B] mb-3 truncate">{r.city ?? '—'}</p>
                        <StatusBadge status={r.status} />
                      </div>
                    )
                  })}
            </div>
          </div>
        ))}
      </div>

      {/* Transition panel */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/30"
          onClick={e => { if (e.target === e.currentTarget) setSelected(null) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-4 border-b border-[#E2E8F0] flex items-center justify-between">
              <h3 className="text-base font-bold text-[#181c20]">{t('int_detail')}</h3>
              <button onClick={() => setSelected(null)} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>close</span>
              </button>
            </div>
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <p className="text-xs font-mono text-[#94A3B8] mb-1">{selected.tracking_code}</p>
                  <h4 className="text-base font-bold text-[#181c20]">{selected.title}</h4>
                  {selected.city && <p className="text-sm text-[#64748B] mt-0.5">{selected.city}</p>}
                </div>
                <StatusBadge status={selected.status} />
              </div>

              {selected.description && (
                <p className="text-sm text-[#64748B] mb-4 bg-[#f7f9fe] p-3 rounded-xl">{selected.description}</p>
              )}

              {nextStatuses.length > 0 && (
                <div className="mt-4">
                  <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-3">{t('change_status')}</p>
                  <div className="space-y-2 mb-4">
                    {nextStatuses.map(ns => (
                      <button key={ns} onClick={() => transition(selected.id, ns)}
                        disabled={transitioning}
                        className="w-full flex items-center justify-between px-4 py-2.5 rounded-xl border border-[#E2E8F0] hover:border-[#0038AF] hover:bg-[#0038AF08] transition-all text-sm font-medium text-[#181c20] disabled:opacity-50">
                        <span>{statusLabel(ns)}</span>
                        {transitioning
                          ? <span className="material-symbols-outlined text-[#94A3B8] animate-spin" style={{ fontSize: 16 }}>progress_activity</span>
                          : <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 16 }}>arrow_forward</span>
                        }
                      </button>
                    ))}
                  </div>
                  <textarea
                    value={note}
                    onChange={e => setNote(e.target.value)}
                    placeholder={t('note_optional_int')}
                    className="w-full text-sm border border-[#E2E8F0] rounded-xl px-4 py-3 text-[#181c20] placeholder-[#94A3B8] resize-none focus:outline-none focus:border-[#0038AF]"
                    rows={2}
                  />
                </div>
              )}

              {nextStatuses.length === 0 && (
                <p className="text-sm text-[#94A3B8] text-center py-4">
                  {t('int_final_state')}
                </p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
