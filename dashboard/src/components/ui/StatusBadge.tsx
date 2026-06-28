import type { ReportStatus } from '../../types/api'

const STATUS_LABELS: Record<ReportStatus, string> = {
  submitted:    'Nouveau',
  received:     'Reçu',
  under_review: 'En examen',
  in_progress:  'En cours',
  resolved:     'Résolu',
  rejected:     'Rejeté',
}

const STATUS_COLORS: Record<ReportStatus, string> = {
  submitted:    '#8B5CF6',
  received:     '#0EA5E9',
  under_review: '#F59E0B',
  in_progress:  '#F97316',
  resolved:     '#22C55E',
  rejected:     '#EF4444',
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
