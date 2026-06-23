import { useState, useEffect, useCallback } from 'react'
import { api } from '../lib/api'
import type { Report, ReportStatus, Category } from '../types/api'
import { useReportEvents } from '../hooks/useReportEvents'
import StatusBadge from '../components/ui/StatusBadge'
import { PRIORITY_COLORS, PRIORITY_LABELS } from '../data/mockData'

const STATUS_LABELS: Record<ReportStatus, string> = {
  submitted: 'Soumis',
  received: 'Reçu',
  under_review: 'En révision',
  scheduled: 'Planifié',
  in_progress: 'En cours',
  resolved: 'Résolu',
  closed: 'Fermé',
  rejected: 'Rejeté',
}

const NEXT_STATUSES: Partial<Record<ReportStatus, ReportStatus[]>> = {
  submitted: ['received', 'rejected'],
  received: ['under_review'],
  under_review: ['scheduled', 'rejected'],
  scheduled: ['in_progress'],
  in_progress: ['resolved', 'under_review'],
  resolved: ['closed'],
}

const ALL_STATUSES: ReportStatus[] = [
  'submitted', 'received', 'under_review', 'scheduled', 'in_progress', 'resolved', 'closed', 'rejected',
]

const PAGE_SIZE = 20

export default function Reports() {
  const [reports, setReports] = useState<Report[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState<ReportStatus | ''>('')
  const [selected, setSelected] = useState<string[]>([])
  const [detailReport, setDetailReport] = useState<Report | null>(null)

  const [categories, setCategories] = useState<Record<number, Category>>({})
  const [updatingStatus, setUpdatingStatus] = useState(false)
  const [statusNote, setStatusNote] = useState('')
  const [pendingStatus, setPendingStatus] = useState<ReportStatus | null>(null)

  useEffect(() => {
    api.get<Category[]>('/categories')
      .then(cats => {
        const map: Record<number, Category> = {}
        // flatten tree (roots + children)
        cats.forEach(c => {
          map[c.id] = c
          c.children?.forEach(child => { map[child.id] = child })
        })
        setCategories(map)
      })
      .catch(() => {})
  }, [])

  const fetchReports = useCallback(() => {
    setLoading(true)
    setError(null)
    const params: Record<string, string | number | undefined> = {
      page,
      page_size: PAGE_SIZE,
    }
    if (filterStatus) params.status = filterStatus

    api.get<{ items: Report[]; total: number }>('/reports', params)
      .then(data => {
        setReports(data.items ?? [])
        setTotal(data.total ?? 0)
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [page, filterStatus])

  useEffect(() => {
    fetchReports()
  }, [fetchReports])

  useReportEvents(fetchReports)

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

  const totalPages = Math.ceil(total / PAGE_SIZE)

  return (
    <div className="flex gap-6 h-full">
      {/* Main Panel */}
      <div className="flex-1 min-w-0">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
          <div>
            <h2 className="text-[#0F172A] text-2xl font-bold">Signalements</h2>
            <p className="text-[#64748B] text-sm mt-1">
              {loading ? 'Chargement...' : `${total.toLocaleString('fr-FR')} signalements au total`}
            </p>
          </div>
          <div className="flex items-center gap-3">
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

        {/* Bulk action bar */}
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

        {/* Error */}
        {error && (
          <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
            <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
            <span className="text-sm text-red-600">{error}</span>
            <button onClick={fetchReports} className="ml-auto text-[#0038AF] text-sm hover:underline">Réessayer</button>
          </div>
        )}

        {/* Table */}
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
                        <td key={j} className="px-4 py-3.5">
                          <div className="h-4 bg-[#E2E8F0] rounded w-20" />
                        </td>
                      ))}
                    </tr>
                  ))
                : filtered.map(r => (
                    <tr
                      key={r.id}
                      onClick={() => setDetailReport(detailReport?.id === r.id ? null : r)}
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
                        <button className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-[#eceef3] transition-colors" onClick={e => e.stopPropagation()}>
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

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between mt-4">
            <span className="text-sm text-[#64748B]">
              Page {page} sur {totalPages} · {total.toLocaleString('fr-FR')} résultats
            </span>
            <div className="flex items-center gap-2">
              <button
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
                className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe] transition-colors"
              >
                ← Précédent
              </button>
              <button
                disabled={page >= totalPages}
                onClick={() => setPage(p => p + 1)}
                className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe] transition-colors"
              >
                Suivant →
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Detail Panel */}
      {detailReport && (
        <div className="w-80 flex-shrink-0 bg-white rounded-xl border border-[#E2E8F0] shadow-sm h-fit sticky top-24">
          <div className="px-5 py-4 border-b border-[#E2E8F0] flex items-center justify-between">
            <h4 className="text-[#181c20] font-semibold text-sm">Détail du signalement</h4>
            <button onClick={() => setDetailReport(null)} className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-[#f1f4f9] transition-colors">
              <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 18 }}>close</span>
            </button>
          </div>
          <div className="p-5 space-y-4">
            <div>
              <p className="text-[#94A3B8] text-xs mb-1">Code de suivi</p>
              <p className="font-mono text-sm font-medium text-[#181c20]">{detailReport.tracking_code}</p>
            </div>
            <div>
              <p className="text-[#94A3B8] text-xs mb-1">Titre</p>
              <p className="text-sm text-[#181c20]">{detailReport.title}</p>
            </div>
            <div>
              <p className="text-[#94A3B8] text-xs mb-1">Statut</p>
              <StatusBadge status={detailReport.status} />
            </div>
            <div>
              <p className="text-[#94A3B8] text-xs mb-1">Catégorie</p>
              <p className="text-sm text-[#181c20]">
                {categories[detailReport.category_id]?.label_fr ?? `Catégorie #${detailReport.category_id}`}
              </p>
            </div>
            <div>
              <p className="text-[#94A3B8] text-xs mb-1">Adresse</p>
              <p className="text-sm text-[#181c20]">{detailReport.address}, {detailReport.city}</p>
            </div>
            {detailReport.priority && (
              <div>
                <p className="text-[#94A3B8] text-xs mb-1">Priorité</p>
                <span
                  className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-xs font-bold uppercase"
                  style={{ backgroundColor: `${PRIORITY_COLORS[detailReport.priority]}18`, color: PRIORITY_COLORS[detailReport.priority] }}
                >
                  {PRIORITY_LABELS[detailReport.priority]}
                </span>
              </div>
            )}
            {detailReport.description && (
              <div>
                <p className="text-[#94A3B8] text-xs mb-1">Description</p>
                <p className="text-sm text-[#64748B] leading-relaxed">{detailReport.description}</p>
              </div>
            )}
            <div>
              <p className="text-[#94A3B8] text-xs mb-1">Créé le</p>
              <p className="text-sm text-[#181c20]">
                {new Date(detailReport.created_at).toLocaleDateString('fr-FR', { dateStyle: 'long' })}
              </p>
            </div>

            {/* Status transition */}
            {NEXT_STATUSES[detailReport.status] && (
              <div className="pt-2 border-t border-[#E2E8F0]">
                <p className="text-[#94A3B8] text-xs mb-2">Changer le statut</p>
                {pendingStatus ? (
                  <div className="space-y-2">
                    <p className="text-xs text-[#64748B]">
                      Passer à <strong>{STATUS_LABELS[pendingStatus]}</strong>
                    </p>
                    <textarea
                      value={statusNote}
                      onChange={e => setStatusNote(e.target.value)}
                      placeholder="Note (optionnel)"
                      rows={2}
                      className="w-full bg-[#f1f4f9] border-0 rounded-lg px-3 py-2 text-xs outline-none focus:ring-2 focus:ring-[#0038AF]/20 resize-none"
                    />
                    <div className="flex gap-2">
                      <button
                        onClick={() => updateStatus(detailReport.id, pendingStatus)}
                        disabled={updatingStatus}
                        className="flex-1 bg-[#0038AF] text-white py-2 rounded-lg text-xs font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
                      >
                        {updatingStatus ? 'Mise à jour...' : 'Confirmer'}
                      </button>
                      <button
                        onClick={() => { setPendingStatus(null); setStatusNote('') }}
                        className="flex-1 border border-[#E2E8F0] text-[#64748B] py-2 rounded-lg text-xs font-medium hover:bg-[#f7f9fe] transition-colors"
                      >
                        Annuler
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="flex flex-col gap-1.5">
                    {(NEXT_STATUSES[detailReport.status] ?? []).map(s => (
                      <button
                        key={s}
                        onClick={() => setPendingStatus(s)}
                        className="w-full text-left px-3 py-2 rounded-lg border border-[#E2E8F0] text-xs font-medium text-[#181c20] hover:bg-[#f7f9fe] hover:border-[#0038AF]/30 transition-colors flex items-center justify-between"
                      >
                        {STATUS_LABELS[s]}
                        <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 14 }}>arrow_forward</span>
                      </button>
                    ))}
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
