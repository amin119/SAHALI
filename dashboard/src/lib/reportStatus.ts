import type { Report, ReportStatus } from '../types/api'
import type { StepperStep } from '../components/ui/Stepper'

export const STATUS_LABELS: Record<ReportStatus, string> = {
  submitted:    'Nouveau',
  received:     'Reçu',
  under_review: 'En examen',
  in_progress:  'En cours',
  resolved:     'Résolu',
  rejected:     'Rejeté',
}

export const NEXT_STATUSES: Partial<Record<ReportStatus, ReportStatus[]>> = {
  submitted:    ['received', 'rejected'],
  received:     ['under_review', 'rejected'],
  under_review: ['in_progress', 'rejected'],
  in_progress:  ['resolved', 'rejected'],
}

export const ALL_STATUSES: ReportStatus[] = ['submitted', 'received', 'under_review', 'in_progress', 'resolved', 'rejected']

// The report's journey, in order — drives the Stepper. Rejection is shown separately (see Stepper's `rejected` prop)
// rather than as a sixth step, since a rejected report didn't "arrive" anywhere further along this line.
export const JOURNEY_STEPS: StepperStep[] = [
  { key: 'submitted',    label: 'Soumis',    icon: 'flag' },
  { key: 'received',     label: 'Reçu',      icon: 'move_to_inbox' },
  { key: 'under_review', label: 'En examen', icon: 'search' },
  { key: 'in_progress',  label: 'En cours',  icon: 'engineering' },
  { key: 'resolved',     label: 'Résolu',    icon: 'check_circle' },
]

export function displayCity(r: Pick<Report, 'city' | 'city_ar'>, lang: string): string | null {
  return lang === 'ar' ? (r.city_ar || r.city || null) : (r.city || r.city_ar || null)
}

export function displayAddress(r: Pick<Report, 'address' | 'address_ar'>, lang: string): string | null {
  return lang === 'ar' ? (r.address_ar || r.address || null) : (r.address || r.address_ar || null)
}
