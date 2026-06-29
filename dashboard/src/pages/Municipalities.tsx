import { useState, useEffect } from 'react'
import { api } from '../lib/api'
import { useLang } from '../context/LangContext'

interface Municipality {
  id: number
  name: string
  subscription_tier: string | null
  total_reports: number
  resolved_reports: number
  open_reports: number
  agent_count: number
  resolution_rate: number
}

const TIER_STYLE: Record<string, { bg: string; text: string }> = {
  premium:  { bg: '#F59E0B18', text: '#F59E0B' },
  pro:      { bg: '#F59E0B18', text: '#F59E0B' },
  standard: { bg: '#0038AF18', text: '#0038AF' },
  basic:    { bg: '#22C55E18', text: '#22C55E' },
}

function tierStyle(tier: string | null) {
  if (!tier) return { bg: '#E2E8F018', text: '#94A3B8' }
  return TIER_STYLE[tier.toLowerCase()] ?? { bg: '#E2E8F018', text: '#94A3B8' }
}

function Skeleton() {
  return (
    <tr className="animate-pulse">
      {Array.from({ length: 7 }).map((_, j) => (
        <td key={j} className="px-5 py-4"><div className="h-4 bg-[#E2E8F0] rounded w-20" /></td>
      ))}
    </tr>
  )
}

export default function Municipalities() {
  const { t } = useLang()
  const [municipalities, setMunicipalities] = useState<Municipality[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedId, setSelectedId] = useState<number | null>(null)

  useEffect(() => {
    api.get<Municipality[]>('/admin/municipalities')
      .then(setMunicipalities)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const totalReports = municipalities.reduce((s, m) => s + m.total_reports, 0)
  const avgResolution = municipalities.length
    ? Math.round(municipalities.reduce((s, m) => s + m.resolution_rate, 0) / municipalities.length)
    : 0
  const totalAgents = municipalities.reduce((s, m) => s + m.agent_count, 0)
  const detail = municipalities.find(m => m.id === selectedId)

  const tableHeaders = [
    t('col_muni'), t('col_subscription'), t('col_reports_count'),
    t('col_open_reports'), t('stat_resolved_n'), t('col_agents_m'), t('col_rate'),
  ]

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_municipalities')}</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? t('loading') : `${municipalities.length} ${t('muni_registered')}`}
          </p>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-6">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      {/* Summary strip */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        {[
          { label: t('nav_municipalities'), value: loading ? '—' : municipalities.length, icon: 'location_city', color: '#0038AF' },
          { label: t('muni_total_reports'), value: loading ? '—' : totalReports, icon: 'assignment', color: '#F97316' },
          { label: t('muni_avg_resolution'), value: loading ? '—' : `${avgResolution}%`, icon: 'check_circle', color: '#22C55E' },
          { label: t('muni_field_agents'), value: loading ? '—' : totalAgents, icon: 'badge', color: '#8B5CF6' },
        ].map(kpi => (
          <div key={kpi.label} className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4">
            <div className="flex items-center justify-between mb-2">
              <p className="text-xs text-[#64748B]">{kpi.label}</p>
              <div className="w-8 h-8 rounded-xl flex items-center justify-center" style={{ backgroundColor: `${kpi.color}18` }}>
                <span className="material-symbols-outlined" style={{ fontSize: 18, color: kpi.color }}>{kpi.icon}</span>
              </div>
            </div>
            <p className="text-2xl font-bold text-[#181c20]">{kpi.value}</p>
          </div>
        ))}
      </div>

      <div className="flex gap-6">
        <div className="flex-1 min-w-0 bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-[#f7f9fe] border-b border-[#E2E8F0]">
                {tableHeaders.map(h => (
                  <th key={h} className="px-5 py-3 text-xs font-semibold text-[#64748B] uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2E8F0]">
              {loading
                ? Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} />)
                : municipalities.map(m => {
                    const ts = tierStyle(m.subscription_tier)
                    const isSelected = selectedId === m.id
                    const rateColor = m.resolution_rate >= 70 ? '#22C55E' : m.resolution_rate >= 40 ? '#F97316' : '#EF4444'
                    return (
                      <tr key={m.id} onClick={() => setSelectedId(isSelected ? null : m.id)}
                        className={`cursor-pointer transition-colors hover:bg-[#f7f9fe]
                          ${isSelected ? 'bg-[#0038AF08]' : ''}`}>
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl bg-[#0038AF18] flex items-center justify-center flex-shrink-0">
                              <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 18 }}>location_city</span>
                            </div>
                            <span className="text-sm font-bold text-[#181c20]">{m.name}</span>
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          <span className="px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: ts.bg, color: ts.text }}>
                            {m.subscription_tier ?? 'N/A'}
                          </span>
                        </td>
                        <td className="px-5 py-4 text-sm font-bold text-[#0038AF]">{m.total_reports}</td>
                        <td className="px-5 py-4 text-sm text-[#F97316] font-semibold">{m.open_reports}</td>
                        <td className="px-5 py-4 text-sm text-[#22C55E] font-semibold">{m.resolved_reports}</td>
                        <td className="px-5 py-4 text-sm text-[#64748B]">{m.agent_count}</td>
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-2">
                            <div className="w-16 h-1.5 bg-[#f1f4f9] rounded-full overflow-hidden">
                              <div className="h-full rounded-full" style={{ width: `${m.resolution_rate}%`, backgroundColor: rateColor }} />
                            </div>
                            <span className="text-xs font-bold" style={{ color: rateColor }}>{m.resolution_rate}%</span>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
            </tbody>
          </table>
        </div>

        {/* Detail panel */}
        {detail && (() => {
          const ts = tierStyle(detail.subscription_tier)
          const rateColor = detail.resolution_rate >= 70 ? '#22C55E' : detail.resolution_rate >= 40 ? '#F97316' : '#EF4444'
          return (
            <div className="w-64 flex-shrink-0 bg-white rounded-xl border border-[#E2E8F0] shadow-sm h-fit sticky top-24">
              <div className="px-5 py-4 border-b border-[#E2E8F0] flex items-center justify-between">
                <h4 className="text-[#181c20] font-semibold text-sm">{t('muni_detail')}</h4>
                <button onClick={() => setSelectedId(null)} className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                  <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 18 }}>close</span>
                </button>
              </div>
              <div className="p-5">
                <div className="flex flex-col items-center mb-5 text-center">
                  <div className="w-16 h-16 rounded-2xl bg-[#0038AF18] flex items-center justify-center mb-3">
                    <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 32 }}>location_city</span>
                  </div>
                  <p className="text-base font-bold text-[#181c20]">{detail.name}</p>
                  <span className="mt-2 px-2.5 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: ts.bg, color: ts.text }}>
                    {detail.subscription_tier ?? 'N/A'}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3 mb-4">
                  {[
                    { label: t('col_reports_count'), value: detail.total_reports, color: '#0038AF' },
                    { label: t('col_open_reports'),  value: detail.open_reports,  color: '#F97316' },
                    { label: t('stat_resolved_n'),   value: detail.resolved_reports, color: '#22C55E' },
                    { label: t('col_agents_m'),      value: detail.agent_count,   color: '#8B5CF6' },
                  ].map(s => (
                    <div key={s.label} className="text-center p-3 rounded-xl" style={{ backgroundColor: `${s.color}10` }}>
                      <p className="text-xl font-bold" style={{ color: s.color }}>{s.value}</p>
                      <p className="text-xs text-[#64748B]">{s.label}</p>
                    </div>
                  ))}
                </div>

                <div>
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="text-xs font-semibold text-[#64748B]">{t('muni_detail_rate')}</span>
                    <span className="text-sm font-bold" style={{ color: rateColor }}>{detail.resolution_rate}%</span>
                  </div>
                  <div className="w-full h-2 bg-[#f1f4f9] rounded-full overflow-hidden">
                    <div className="h-full rounded-full" style={{ width: `${detail.resolution_rate}%`, backgroundColor: rateColor }} />
                  </div>
                </div>
              </div>
            </div>
          )
        })()}
      </div>
    </div>
  )
}
