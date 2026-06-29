import { useState, useEffect } from 'react'
import { api } from '../lib/api'
import type { Report } from '../types/api'
import { useLang } from '../context/LangContext'

const HOURS = Array.from({ length: 10 }, (_, i) => i + 8)

const STATUS_COLORS: Record<string, { bg: string; text: string }> = {
  received:     { bg: '#0EA5E918', text: '#0EA5E9' },
  under_review: { bg: '#F59E0B18', text: '#F59E0B' },
  in_progress:  { bg: '#0038AF18', text: '#0038AF' },
  resolved:     { bg: '#22C55E18', text: '#22C55E' },
}

const PRIORITY_COLOR: Record<string, string> = {
  low: '#22C55E', medium: '#F59E0B', high: '#F97316', critical: '#EF4444',
}

function getWeekDates(offset: number): Date[] {
  const now = new Date()
  const day = now.getDay() === 0 ? 7 : now.getDay()
  const monday = new Date(now)
  monday.setDate(now.getDate() - day + 1 + offset * 7)
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(monday)
    d.setDate(monday.getDate() + i)
    return d
  })
}

function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
}

export default function Calendar() {
  const { t, locale } = useLang()
  const [reports, setReports] = useState<Report[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [weekOffset, setWeekOffset] = useState(0)
  const [selectedReport, setSelectedReport] = useState<Report | null>(null)

  const DAYS = [t('day_mon'), t('day_tue'), t('day_wed'), t('day_thu'), t('day_fri'), t('day_sat'), t('day_sun')]

  useEffect(() => {
    api.get<{ items: Report[]; total: number }>('/reports', { page_size: '200' })
      .then(d => {
        const relevant = d.items.filter(r =>
          r.status === 'received' || r.status === 'under_review' || r.status === 'in_progress' || r.status === 'resolved'
        )
        setReports(relevant)
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const weekDates = getWeekDates(weekOffset)
  const today = new Date()

  function getEventsForDay(date: Date): Report[] {
    return reports.filter(r => sameDay(new Date(r.updated_at), date))
  }

  function getHourSlot(r: Report): number {
    return new Date(r.updated_at).getHours()
  }

  function monthLabel(): string {
    const months = weekDates.map(d => d.toLocaleDateString(locale, { month: 'long' }))
    const unique = [...new Set(months)]
    const year = weekDates[0].getFullYear()
    return `${unique.join(' / ')} ${year}`
  }

  const statusLabel = (s: string) => t(
    s === 'received' ? 'status_received' :
    s === 'under_review' ? 'status_under_review' :
    s === 'in_progress' ? 'status_in_progress' :
    s === 'resolved' ? 'status_resolved' : 'status_received'
  )

  const summaryStrip = [
    { key: 'under_review', label: t('status_under_review'), icon: 'search',       color: '#F59E0B' },
    { key: 'in_progress',  label: t('cal_in_progress'),     icon: 'pending',       color: '#0038AF' },
    { key: 'resolved_week',label: t('cal_done_week'),       icon: 'check_circle',  color: '#22C55E' },
    { key: 'total',        label: t('cal_total'),           icon: 'assignment',    color: '#F97316' },
  ]

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_calendar')}</h2>
          <p className="text-[#64748B] text-sm mt-1 capitalize">{monthLabel()}</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="hidden md:flex items-center gap-3">
            {Object.entries(STATUS_COLORS).map(([k, v]) => (
              <div key={k} className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: v.text }} />
                <span className="text-xs text-[#64748B]">{statusLabel(k)}</span>
              </div>
            ))}
          </div>
          <div className="flex items-center gap-1">
            <button onClick={() => setWeekOffset(0)}
              className="px-3 py-1.5 text-sm bg-white border border-[#E2E8F0] rounded-lg text-[#64748B] hover:bg-[#f7f9fe] transition-colors">
              {t('week_today')}
            </button>
            <button onClick={() => setWeekOffset(w => w - 1)}
              className="w-8 h-8 flex items-center justify-center bg-white border border-[#E2E8F0] rounded-lg text-[#64748B] hover:bg-[#f7f9fe] transition-colors">
              <span className="material-symbols-outlined" style={{ fontSize: 18 }}>chevron_left</span>
            </button>
            <button onClick={() => setWeekOffset(w => w + 1)}
              className="w-8 h-8 flex items-center justify-center bg-white border border-[#E2E8F0] rounded-lg text-[#64748B] hover:bg-[#f7f9fe] transition-colors">
              <span className="material-symbols-outlined" style={{ fontSize: 18 }}>chevron_right</span>
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-6">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
        {/* Day headers */}
        <div className="grid border-b border-[#E2E8F0]" style={{ gridTemplateColumns: '60px repeat(7, 1fr)' }}>
          <div className="p-3 border-r border-[#E2E8F0]" />
          {weekDates.map((d, i) => {
            const isToday = sameDay(d, today)
            return (
              <div key={i} className={`p-3 text-center border-r border-[#E2E8F0] last:border-r-0 ${isToday ? 'bg-[#0038AF08]' : ''}`}>
                <p className="text-xs font-semibold text-[#64748B]">{DAYS[i]}</p>
                <div className={`w-7 h-7 rounded-full flex items-center justify-center mx-auto mt-1 text-sm font-bold
                  ${isToday ? 'bg-[#0038AF] text-white' : 'text-[#181c20]'}`}>
                  {d.getDate()}
                </div>
              </div>
            )
          })}
        </div>

        {/* Time grid */}
        <div className="overflow-y-auto" style={{ maxHeight: 480 }}>
          {loading ? (
            <div className="p-8 flex items-center justify-center">
              <div className="text-center">
                <div className="w-12 h-12 rounded-full border-4 border-[#0038AF] border-t-transparent animate-spin mx-auto mb-3" />
                <p className="text-sm text-[#64748B]">{t('cal_loading')}</p>
              </div>
            </div>
          ) : (
            HOURS.map(hour => (
              <div key={hour} className="grid border-b border-[#E2E8F0] last:border-b-0"
                style={{ gridTemplateColumns: '60px repeat(7, 1fr)', minHeight: 56 }}>
                <div className="px-3 py-2 border-r border-[#E2E8F0] flex items-start">
                  <span className="text-xs text-[#94A3B8]">{hour.toString().padStart(2, '0')}:00</span>
                </div>
                {weekDates.map((d, di) => {
                  const isToday = sameDay(d, today)
                  const events = getEventsForDay(d).filter(r => getHourSlot(r) === hour)
                  return (
                    <div key={di} className={`p-1.5 border-r border-[#E2E8F0] last:border-r-0 min-h-14 ${isToday ? 'bg-[#0038AF04]' : ''}`}>
                      {events.map(r => {
                        const sm = STATUS_COLORS[r.status] ?? STATUS_COLORS.in_progress
                        const pc = PRIORITY_COLOR[r.priority] ?? '#94A3B8'
                        return (
                          <button key={r.id} onClick={() => setSelectedReport(r === selectedReport ? null : r)}
                            className="w-full text-left px-2 py-1 rounded-lg mb-1 text-xs font-medium transition-all hover:opacity-90"
                            style={{ backgroundColor: sm.bg, color: sm.text }}>
                            <div className="flex items-center gap-1 mb-0.5">
                              <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: pc }} />
                              <span className="truncate font-mono text-[10px] opacity-70">{r.tracking_code}</span>
                            </div>
                            <span className="truncate block leading-tight">{r.title}</span>
                          </button>
                        )
                      })}
                    </div>
                  )
                })}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Summary strip */}
      <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
        {summaryStrip.map(s => {
          const value = loading ? '—' :
            s.key === 'under_review' ? reports.filter(r => r.status === 'under_review').length :
            s.key === 'in_progress' ? reports.filter(r => r.status === 'in_progress').length :
            s.key === 'resolved_week' ? reports.filter(r => r.status === 'resolved' && weekDates.some(d => sameDay(d, new Date(r.updated_at)))).length :
            reports.length
          return (
            <div key={s.key} className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4 flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: `${s.color}18` }}>
                <span className="material-symbols-outlined" style={{ fontSize: 20, color: s.color }}>{s.icon}</span>
              </div>
              <div>
                <p className="text-xl font-bold text-[#181c20]">{value}</p>
                <p className="text-xs text-[#64748B]">{s.label}</p>
              </div>
            </div>
          )
        })}
      </div>

      {/* Event detail popup */}
      {selectedReport && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/30"
          onClick={e => { if (e.target === e.currentTarget) setSelectedReport(null) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
            <div className="flex items-start justify-between mb-4">
              <div>
                <p className="text-xs font-mono text-[#94A3B8] mb-1">{selectedReport.tracking_code}</p>
                <h3 className="text-base font-bold text-[#181c20]">{selectedReport.title}</h3>
                {selectedReport.city && <p className="text-sm text-[#64748B] mt-0.5">{selectedReport.city}</p>}
              </div>
              <button onClick={() => setSelectedReport(null)} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>close</span>
              </button>
            </div>
            {selectedReport.description && (
              <p className="text-sm text-[#64748B] bg-[#f7f9fe] p-3 rounded-xl mb-4">{selectedReport.description}</p>
            )}
            <div className="flex items-center gap-2">
              {(() => {
                const sm = STATUS_COLORS[selectedReport.status] ?? STATUS_COLORS.in_progress
                return (
                  <span className="px-2.5 py-1 rounded-full text-xs font-semibold"
                    style={{ backgroundColor: sm.bg, color: sm.text }}>{statusLabel(selectedReport.status)}</span>
                )
              })()}
              <span className="px-2.5 py-1 rounded-full text-xs font-semibold"
                style={{ backgroundColor: `${PRIORITY_COLOR[selectedReport.priority] ?? '#94A3B8'}18`, color: PRIORITY_COLOR[selectedReport.priority] ?? '#94A3B8' }}>
                {selectedReport.priority}
              </span>
              <span className="text-xs text-[#94A3B8] ml-auto">
                {new Date(selectedReport.updated_at).toLocaleString(locale, { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
