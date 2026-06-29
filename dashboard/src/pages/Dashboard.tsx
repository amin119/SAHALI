import { useState, useEffect, useCallback } from 'react'
import { api } from '../lib/api'
import type { AdminStats, Report } from '../types/api'
import StatusBadge from '../components/ui/StatusBadge'
import { useReportEvents } from '../hooks/useReportEvents'
import { useLang } from '../context/LangContext'

const RANGE_TABS = ['7j', '30j', '3m', '1an']

function pending(stats: AdminStats): number {
  const s = stats.by_status
  return (s.submitted ?? 0) + (s.received ?? 0) + (s.under_review ?? 0) + (s.in_progress ?? 0)
}

function resolved(stats: AdminStats): number {
  return stats.by_status.resolved ?? 0
}

function KpiSkeleton() {
  return (
    <div className="bg-white rounded-xl p-5 shadow-sm border border-[#E2E8F0] animate-pulse">
      <div className="w-10 h-10 bg-[#E2E8F0] rounded-lg mb-4" />
      <div className="h-3 bg-[#E2E8F0] rounded w-24 mb-2" />
      <div className="h-8 bg-[#E2E8F0] rounded w-20" />
    </div>
  )
}

export default function Dashboard() {
  const { t, locale } = useLang()
  const [rangeTab, setRangeTab] = useState('7j')
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [recentReports, setRecentReports] = useState<Report[]>([])
  const [statsError, setStatsError] = useState<string | null>(null)

  const fetchAll = useCallback(() => {
    api.get<AdminStats>('/admin/stats')
      .then(setStats)
      .catch(e => setStatsError(e.message))
    api.get<{ items: Report[] }>('/reports', { page: '1', page_size: '5' })
      .then(data => setRecentReports(data.items ?? []))
      .catch(() => {})
  }, [])

  useEffect(() => { fetchAll() }, [fetchAll])

  useReportEvents(fetchAll)

  const kpiCards = stats
    ? [
        {
          label: t('kpi_total'),
          value: stats.total_reports.toLocaleString(locale),
          delta: `+${stats.today_reports} ${t('kpi_today')}`,
          deltaUp: true,
          icon: 'report_problem',
          color: '#0038AF',
          sub: null,
        },
        {
          label: t('kpi_pending'),
          value: pending(stats).toLocaleString(locale),
          delta: `${stats.by_status.submitted ?? 0} ${t('kpi_new')}`,
          deltaUp: false,
          icon: 'pending_actions',
          color: '#F59E0B',
          sub: `${t('kpi_avg_res')} ${stats.avg_resolution_hours}h`,
        },
        {
          label: t('kpi_resolved'),
          value: resolved(stats).toLocaleString(locale),
          delta: stats.total_reports > 0
            ? `${Math.round((resolved(stats) / stats.total_reports) * 100)}%`
            : '—',
          deltaUp: true,
          icon: 'check_circle',
          color: '#22C55E',
          sub: null,
        },
        {
          label: t('kpi_rejected_lbl'),
          value: (stats.by_status.rejected ?? 0).toLocaleString(locale),
          delta: stats.total_reports > 0
            ? `${Math.round(((stats.by_status.rejected ?? 0) / stats.total_reports) * 100)}%`
            : '—',
          deltaUp: false,
          icon: 'cancel',
          color: '#EF4444',
          sub: null,
        },
      ]
    : null

  const statusDistribution = stats
    ? [
        { label: t('dist_submitted'), count: stats.by_status.submitted ?? 0, color: '#0038AF' },
        { label: t('dist_in_progress'), count: stats.by_status.in_progress ?? 0, color: '#F59E0B' },
        { label: t('dist_resolved'), count: resolved(stats), color: '#22C55E' },
        { label: t('dist_rejected'), count: stats.by_status.rejected ?? 0, color: '#EF4444' },
      ]
    : []

  const totalDistrib = statusDistribution.reduce((s, c) => s + c.count, 0)

  const tableHeaders = [t('col_code'), t('col_title'), t('col_city'), t('col_status'), t('col_priority'), t('col_date')]

  return (
    <div>
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_dashboard')}</h2>
        </div>
        <div className="flex items-center gap-3">
          <div className="bg-white border border-[#E2E8F0] px-4 py-2 rounded-xl flex items-center gap-2 shadow-sm">
            <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 16 }}>calendar_today</span>
            <span className="text-sm font-medium text-[#181c20]">
              {new Date().toLocaleDateString(locale, { day: 'numeric', month: 'long', year: 'numeric' })}
            </span>
          </div>
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
            className="bg-[#0038AF] text-white px-5 py-2 rounded-xl flex items-center gap-2 shadow-md hover:opacity-90 transition-opacity text-sm font-medium"
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>download</span>
            {t('dash_export')}
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-6">
        {statsError && (
          <div className="col-span-full flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3">
            <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
            <span className="text-sm text-red-600">{statsError}</span>
          </div>
        )}
        {kpiCards
          ? kpiCards.map(k => (
              <div key={k.label} className="bg-white rounded-xl p-5 shadow-sm border border-[#E2E8F0] relative overflow-hidden">
                <div className="flex justify-between items-start mb-4">
                  <div className="p-2 rounded-lg" style={{ backgroundColor: `${k.color}18` }}>
                    <span className="material-symbols-outlined" style={{ fontSize: 22, color: k.color }}>{k.icon}</span>
                  </div>
                  <span
                    className="text-xs font-semibold px-2 py-0.5 rounded-full"
                    style={{ backgroundColor: `${k.deltaUp ? '#22C55E' : '#F59E0B'}18`, color: k.deltaUp ? '#22C55E' : '#F59E0B' }}
                  >
                    {k.delta}
                  </span>
                </div>
                <p className="text-[#64748B] text-xs uppercase tracking-wider font-semibold mb-1">{k.label}</p>
                <h3 className="text-[#181c20] font-bold" style={{ fontSize: 32 }}>{k.value}</h3>
                {k.sub && (
                  <p className="text-[#94A3B8] text-xs mt-3 flex items-center gap-1">
                    <span className="material-symbols-outlined" style={{ fontSize: 13 }}>schedule</span>
                    {k.sub}
                  </p>
                )}
              </div>
            ))
          : Array.from({ length: 4 }).map((_, i) => <KpiSkeleton key={i} />)}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-12 gap-6 mb-6">
        {/* Status Breakdown */}
        <div className="col-span-12 xl:col-span-8 bg-white rounded-xl p-6 shadow-sm border border-[#E2E8F0]">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h4 className="text-[#181c20] font-semibold text-base">{t('dist_title')}</h4>
              <p className="text-[#94A3B8] text-xs mt-0.5">{t('dist_subtitle')}</p>
            </div>
            <div className="flex bg-[#f1f4f9] p-1 rounded-lg gap-1">
              {RANGE_TABS.map(tab => (
                <button
                  key={tab}
                  onClick={() => setRangeTab(tab)}
                  className={`px-3 py-1.5 rounded-md text-xs font-medium transition-all
                    ${rangeTab === tab ? 'bg-white shadow-sm text-[#0038AF]' : 'text-[#64748B] hover:text-[#181c20]'}`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>
          {stats ? (
            <div className="space-y-4">
              {statusDistribution.map(s => (
                <div key={s.label}>
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="text-sm text-[#181c20]">{s.label}</span>
                    <span className="text-xs font-bold" style={{ color: s.color }}>
                      {s.count.toLocaleString(locale)}
                    </span>
                  </div>
                  <div className="w-full h-3 bg-[#f1f4f9] rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{ width: totalDistrib > 0 ? `${(s.count / totalDistrib) * 100}%` : '0%', backgroundColor: s.color }}
                    />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="space-y-4 animate-pulse">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i}>
                  <div className="h-3 bg-[#E2E8F0] rounded w-24 mb-2" />
                  <div className="h-3 bg-[#E2E8F0] rounded-full w-full" />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Donut Chart */}
        <div className="col-span-12 xl:col-span-4 bg-white rounded-xl p-6 shadow-sm border border-[#E2E8F0] flex flex-col">
          <h4 className="text-[#181c20] font-semibold text-base mb-4">{t('dist_donut')}</h4>
          {stats && totalDistrib > 0 ? (
            <>
              <div className="flex items-center justify-center mb-6">
                <div className="relative w-36 h-36">
                  <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                    <circle cx="18" cy="18" r="15.9" fill="none" stroke="#e0e2e7" strokeWidth="3.5" />
                    {(() => {
                      let offset = 0
                      return statusDistribution.map(c => {
                        const pct = (c.count / totalDistrib) * 100
                        const el = (
                          <circle
                            key={c.label}
                            cx="18" cy="18" r="15.9"
                            fill="none"
                            stroke={c.color}
                            strokeWidth="3.5"
                            strokeDasharray={`${pct} ${100 - pct}`}
                            strokeDashoffset={-offset}
                          />
                        )
                        offset += pct
                        return el
                      })
                    })()}
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-2xl font-bold text-[#181c20]">{totalDistrib.toLocaleString(locale)}</span>
                    <span className="text-xs text-[#94A3B8]">{t('dist_total')}</span>
                  </div>
                </div>
              </div>
              <div className="space-y-2.5 flex-1">
                {statusDistribution.map(c => (
                  <div key={c.label} className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <span className="w-2 h-2 rounded-full" style={{ backgroundColor: c.color }} />
                      <span className="text-xs text-[#64748B]">{c.label}</span>
                    </div>
                    <span className="text-xs font-semibold text-[#181c20]">{c.count}</span>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center">
              <div className="w-36 h-36 rounded-full bg-[#f1f4f9] animate-pulse" />
            </div>
          )}
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        {/* SLA / Resolution rate */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-[#E2E8F0] flex flex-col items-center justify-center">
          <h4 className="text-[#181c20] font-semibold text-base mb-4 self-start">{t('rate_title')}</h4>
          {stats ? (() => {
            const rate = stats.total_reports > 0
              ? Math.round((resolved(stats) / stats.total_reports) * 100)
              : 0
            const dashLen = 125.6
            const dashOffset = dashLen * (1 - rate / 100)
            return (
              <>
                <div className="relative mt-2">
                  <svg viewBox="0 0 100 60" className="w-44">
                    <path d="M10,50 A40,40 0 0,1 90,50" fill="none" stroke="#e0e2e7" strokeWidth="10" strokeLinecap="round" />
                    <path
                      d="M10,50 A40,40 0 0,1 90,50"
                      fill="none"
                      stroke={rate >= 85 ? '#22C55E' : rate >= 70 ? '#F59E0B' : '#EF4444'}
                      strokeWidth="10"
                      strokeLinecap="round"
                      strokeDasharray={dashLen}
                      strokeDashoffset={dashOffset}
                    />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-end pb-2">
                    <span className="text-3xl font-bold" style={{ color: rate >= 85 ? '#22C55E' : rate >= 70 ? '#F59E0B' : '#EF4444' }}>
                      {rate}%
                    </span>
                    <span className="text-xs text-[#94A3B8]">{t('rate_target')}</span>
                  </div>
                </div>
                <div
                  className="flex items-center gap-2 mt-4 px-4 py-2 rounded-lg"
                  style={{ backgroundColor: `${rate >= 85 ? '#22C55E' : '#F59E0B'}18` }}
                >
                  <span
                    className="material-symbols-outlined"
                    style={{ fontSize: 16, color: rate >= 85 ? '#22C55E' : '#F59E0B' }}
                  >
                    {rate >= 85 ? 'verified' : 'warning'}
                  </span>
                  <span className="text-xs font-medium" style={{ color: rate >= 85 ? '#22C55E' : '#F59E0B' }}>
                    {rate >= 85 ? t('rate_excellent') : t('rate_below')}
                  </span>
                </div>
              </>
            )
          })() : (
            <div className="w-44 h-28 bg-[#f1f4f9] rounded animate-pulse" />
          )}
        </div>

        {/* Avg resolution time */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-[#E2E8F0]">
          <h4 className="text-[#181c20] font-semibold text-base mb-5">{t('avg_time_title')}</h4>
          {stats ? (
            <div className="flex flex-col items-center justify-center h-28 gap-2">
              <span className="text-5xl font-bold text-[#0038AF]">{stats.avg_resolution_hours}h</span>
              <span className="text-sm text-[#64748B]">{t('avg_time_per')}</span>
            </div>
          ) : (
            <div className="h-28 bg-[#f1f4f9] rounded animate-pulse" />
          )}
        </div>
      </div>

      {/* Recent Reports Table */}
      <div className="bg-white rounded-xl shadow-sm border border-[#E2E8F0] overflow-hidden">
        <div className="px-6 py-4 border-b border-[#E2E8F0] flex items-center justify-between">
          <h4 className="text-[#181c20] font-semibold text-base">{t('recent_title')}</h4>
          <a href="/reports" className="text-[#0038AF] text-sm font-medium hover:underline">{t('see_all')}</a>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-[#f7f9fe]">
                {tableHeaders.map(h => (
                  <th key={h} className="px-5 py-3 text-xs font-semibold text-[#64748B] uppercase tracking-wider border-b border-[#E2E8F0]">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2E8F0]">
              {recentReports.length > 0
                ? recentReports.map(r => (
                    <tr key={r.id} className="hover:bg-[#f7f9fe] transition-colors">
                      <td className="px-5 py-3.5 text-xs font-mono text-[#181c20]">{r.tracking_code}</td>
                      <td className="px-5 py-3.5 text-sm text-[#181c20] max-w-48 truncate">{r.title}</td>
                      <td className="px-5 py-3.5 text-sm text-[#64748B]">{r.city}</td>
                      <td className="px-5 py-3.5"><StatusBadge status={r.status} /></td>
                      <td className="px-5 py-3.5 text-xs text-[#64748B] capitalize">{r.priority ?? '—'}</td>
                      <td className="px-5 py-3.5 text-xs text-[#94A3B8]">
                        {new Date(r.created_at).toLocaleDateString(locale)}
                      </td>
                    </tr>
                  ))
                : Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      {Array.from({ length: 6 }).map((__, j) => (
                        <td key={j} className="px-5 py-3.5">
                          <div className="h-4 bg-[#E2E8F0] rounded w-24" />
                        </td>
                      ))}
                    </tr>
                  ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
