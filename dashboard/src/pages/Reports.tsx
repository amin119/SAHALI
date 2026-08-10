import { useState, useEffect, useCallback } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { api } from '../lib/api'
import type { Report, ReportStatus } from '../types/api'
import { useReportEvents } from '../hooks/useReportEvents'
import StatusBadge, { PriorityBadge } from '../components/ui/StatusBadge'
import { useLang } from '../context/LangContext'
import Button from '../components/ui/Button'
import Card from '../components/ui/Card'
import { TextField, SelectField } from '../components/ui/TextField'
import DataTable, { type Column } from '../components/ui/DataTable'
import Pagination from '../components/ui/Pagination'
import PageHeader from '../components/ui/PageHeader'
import SelectionBar from '../components/ui/SelectionBar'
import ErrorBanner from '../components/ui/ErrorBanner'
import { STATUS_LABELS, ALL_STATUSES, displayCity, displayAddress } from '../lib/reportStatus'

const PAGE_SIZE = 20

export default function Reports() {
  const { lang } = useLang()
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

  // Jump straight to a report's own page when navigated from a notification (?report=ID)
  useEffect(() => {
    const targetId = searchParams.get('report')
    if (!targetId) return
    navigate(`/reports/${targetId}`, { replace: true })
  }, [searchParams, navigate])

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
      <span className="w-7 h-7 flex items-center justify-center rounded-md">
        <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 16 }}>chevron_right</span>
      </span>
    ) },
  ]

  return (
    <div>
      <PageHeader
        title="Signalements"
        subtitle={loading ? 'Chargement...' : `${total.toLocaleString('fr-FR')} signalements`}
        actions={<span data-tour="reports-export"><Button variant="secondary" icon="download" onClick={exportCsv}>Exporter CSV</Button></span>}
      />

      <Card className="p-4 mb-4 flex flex-wrap items-center gap-3" data-tour="reports-filters">
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

      <div data-tour="reports-table">
      <DataTable
        columns={columns}
        rows={filtered}
        rowKey={r => r.id}
        loading={loading}
        onRowClick={r => navigate(`/reports/${r.id}`)}
        selectable
        selected={selected}
        onToggleSelect={toggleSelect}
        onToggleSelectAll={checked => setSelected(checked ? filtered.map(r => r.id) : [])}
        emptyMessage="Aucun signalement trouvé"
      />
      </div>

      <Pagination page={page} totalPages={totalPages} total={total} onChange={setPage} />
    </div>
  )
}
