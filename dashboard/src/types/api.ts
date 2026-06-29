export type UserRole = 'citizen' | 'field_agent' | 'analyst' | 'supervisor' | 'admin'

export interface User {
  id: string
  full_name: string
  email?: string
  phone?: string
  role: UserRole
  preferred_language: string
  is_active: boolean
  created_at: string
}

export interface UserBrief {
  id: string
  full_name: string
  role: UserRole
}

export type ReportStatus =
  | 'submitted'
  | 'received'
  | 'under_review'
  | 'in_progress'
  | 'resolved'
  | 'rejected'

export type Priority = 'low' | 'medium' | 'high' | 'critical'

export interface Report {
  id: string
  tracking_code: string
  citizen_id: string
  category_id: number
  title: string
  description?: string
  photo_url?: string
  thumbnail_url?: string
  photo_urls?: string[]
  lat?: number
  lng?: number
  address: string | null
  city: string | null
  ward?: string | null
  status: ReportStatus
  priority: Priority
  assigned_to?: string
  analyzed_by?: string
  is_duplicate: boolean
  created_at: string
  updated_at: string
  resolved_at?: string
}

export interface ReportListOut {
  items: Report[]
  total: number
  page: number
  page_size: number
}

export interface Assignment {
  id: string
  agent: UserBrief
  assigned_by_user: UserBrief
  note?: string
  is_active: boolean
  created_at: string
}

export interface ResolutionReport {
  id: string
  comment: string
  materials?: string
  photo_url?: string
  resolved_by_user: UserBrief
  created_at: string
}

export interface StatusHistoryEntry {
  id: string
  from_status: string | null
  to_status: string
  note?: string
  changed_by: string
  changed_by_name?: string
  created_at: string
}

export interface AdminStats {
  total_reports: number
  today_reports: number
  by_status: Partial<Record<ReportStatus, number>>
  avg_resolution_hours: number
}

export interface Category {
  id: number
  parent_id: number | null
  slug: string
  label_fr: string
  label_ar: string
  label_en: string
  icon: string | null
  sla_hours: number | null
  default_department_id: number | null
  children: Category[]
}

export interface Notification {
  id: string
  user_id: string
  report_id?: string | null
  title: string
  body: string
  is_read: boolean
  created_at: string
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  page_size: number
}
