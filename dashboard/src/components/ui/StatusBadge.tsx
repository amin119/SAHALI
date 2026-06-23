import type { ReportStatus } from '../../types/api'

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

const STATUS_COLORS: Record<ReportStatus, string> = {
  submitted: '#6366F1',
  received: '#0EA5E9',
  under_review: '#F59E0B',
  scheduled: '#8B5CF6',
  in_progress: '#F97316',
  resolved: '#22C55E',
  closed: '#64748B',
  rejected: '#EF4444',
}

export default function StatusBadge({ status }: { status: ReportStatus }) {
  const color = STATUS_COLORS[status] ?? '#94A3B8'
  const label = STATUS_LABELS[status] ?? status
  return (
    <span
      className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold"
      style={{ backgroundColor: `${color}18`, color }}
    >
      <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: color }} />
      {label}
    </span>
  )
}
