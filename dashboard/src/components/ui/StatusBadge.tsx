import type { Priority, ReportStatus } from '../../types/api'
import { useLang } from '../../context/LangContext'
import { PRIORITY_COLORS, PRIORITY_LABELS } from '../../data/mockData'
import Badge from './Badge'

const STATUS_COLORS: Record<ReportStatus, string> = {
  submitted:    '#8B5CF6',
  received:     '#0EA5E9',
  under_review: '#F59E0B',
  in_progress:  '#F97316',
  resolved:     '#22C55E',
  rejected:     '#EF4444',
}

export default function StatusBadge({ status }: { status: ReportStatus | string }) {
  const { t } = useLang()
  const color = STATUS_COLORS[status as ReportStatus] ?? '#94A3B8'
  const labelMap: Record<string, ReturnType<typeof t>> = {
    submitted:    t('status_submitted'),
    received:     t('status_received'),
    under_review: t('status_under_review'),
    in_progress:  t('status_in_progress'),
    resolved:     t('status_resolved'),
    rejected:     t('status_rejected'),
  }
  return <Badge label={labelMap[status] ?? status} color={color} dot />
}

export function PriorityBadge({ priority }: { priority: Priority }) {
  return <Badge label={PRIORITY_LABELS[priority]} color={PRIORITY_COLORS[priority]} />
}
