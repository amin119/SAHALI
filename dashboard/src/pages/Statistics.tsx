import { useState, useEffect } from 'react'
import { api } from '../lib/api'

interface AdminStats {
  total_reports: number
  today_reports: number
  by_status: Record<string, number>
  avg_resolution_hours: number
}

const STATUS_META: Record<string, { label: string; color: string }> = {
  submitted:    { label: 'Soumis',         color: '#94A3B8' },
  received:     { label: 'Reçus',           color: '#0EA5E9' },
  under_review: { label: 'En examen',       color: '#F59E0B' },
  scheduled:    { label: 'Planifiés',       color: '#8B5CF6' },
  in_progress:  { label: 'En cours',        color: '#0038AF' },
  resolved:     { label: 'Résolus',         color: '#22C55E' },
  closed:       { label: 'Fermés',          color: '#64748B' },
  rejected:     { label: 'Rejetés',         color: '#EF4444' },
}

function KPICard({ label, value, icon, color, sub }: {
  label: string; value: string | number; icon: string; color: string; sub?: string
}) {
  return (
    <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-5">
      <div className="flex items-center justify-between mb-3">
        <p className="text-sm text-[#64748B] font-medium">{label}</p>
        <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ backgroundColor: `${color}18` }}>
          <span className="material-symbols-outlined" style={{ fontSize: 20, color }}>{icon}</span>
        </div>
      </div>
      <p className="text-3xl font-bold text-[#181c20] mb-1">{value}</p>
      {sub && <p className="text-xs text-[#94A3B8]">{sub}</p>}
    </div>
  )
}

function SkeletonCard() {
  return (
    <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-5 animate-pulse">
      <div className="flex items-center justify-between mb-3">
        <div className="h-4 bg-[#E2E8F0] rounded w-28" />
        <div className="w-9 h-9 rounded-xl bg-[#E2E8F0]" />
      </div>
      <div className="h-8 bg-[#E2E8F0] rounded w-20 mb-2" />
      <div className="h-3 bg-[#E2E8F0] rounded w-32" />
    </div>
  )
}

export default function Statistics() {
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    api.get<AdminStats>('/admin/stats')
      .then(setStats)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const byStatus = stats?.by_status ?? {}
  const total = Object.values(byStatus).reduce((s, v) => s + v, 0) || 1
  const resolved = (byStatus['resolved'] ?? 0) + (byStatus['closed'] ?? 0)
  const active = (byStatus['in_progress'] ?? 0) + (byStatus['scheduled'] ?? 0)
  const resolutionRate = stats ? Math.round((resolved / total) * 100) : 0

  const statusOrder = ['submitted', 'received', 'under_review', 'scheduled', 'in_progress', 'resolved', 'closed', 'rejected']
  const barData = statusOrder.map(key => ({
    key, ...STATUS_META[key],
    count: byStatus[key] ?? 0,
    pct: Math.round(((byStatus[key] ?? 0) / total) * 100),
  })).filter(d => d.count > 0)

  const maxCount = Math.max(...barData.map(d => d.count), 1)

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-[#0F172A] text-2xl font-bold">Statistiques</h2>
        <p className="text-[#64748B] text-sm mt-1">Tableau de bord analytique — données en temps réel</p>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-6">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      {/* KPI cards */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-5 mb-6">
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)
        ) : (
          <>
            <KPICard label="Total signalements" value={stats?.total_reports ?? 0} icon="assignment" color="#0038AF"
              sub={`+${stats?.today_reports ?? 0} aujourd'hui`} />
            <KPICard label="Taux de résolution" value={`${resolutionRate}%`} icon="check_circle" color="#22C55E"
              sub={`${resolved} résolus sur ${stats?.total_reports ?? 0}`} />
            <KPICard label="En cours de traitement" value={active} icon="pending" color="#F97316"
              sub="Interventions actives" />
            <KPICard label="Résolution moyenne" value={`${stats?.avg_resolution_hours ?? 0}h`}
              icon="schedule" color="#8B5CF6" sub="Délai moyen observé" />
          </>
        )}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-5 gap-5 mb-6">
        {/* Bar chart */}
        <div className="xl:col-span-3 bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-5">
          <h3 className="text-sm font-bold text-[#181c20] mb-5">Répartition par statut</h3>
          {loading ? (
            <div className="space-y-4">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="animate-pulse">
                  <div className="flex justify-between mb-1.5">
                    <div className="h-3 bg-[#E2E8F0] rounded w-24" />
                    <div className="h-3 bg-[#E2E8F0] rounded w-8" />
                  </div>
                  <div className="h-6 bg-[#E2E8F0] rounded-full" />
                </div>
              ))}
            </div>
          ) : (
            <div className="space-y-4">
              {barData.map(d => (
                <div key={d.key}>
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-sm text-[#64748B]">{d.label}</span>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-[#181c20]">{d.count}</span>
                      <span className="text-xs text-[#94A3B8]">({d.pct}%)</span>
                    </div>
                  </div>
                  <div className="relative h-7 bg-[#f1f4f9] rounded-full overflow-hidden">
                    <div className="h-full rounded-full transition-all duration-700"
                      style={{ width: `${(d.count / maxCount) * 100}%`, backgroundColor: d.color }} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Summary with SVG gauge */}
        <div className="xl:col-span-2 bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-5">
          <h3 className="text-sm font-bold text-[#181c20] mb-5">Vue d'ensemble</h3>
          {loading ? (
            <div className="flex flex-col items-center justify-center h-48 gap-3">
              <div className="w-36 h-36 rounded-full bg-[#E2E8F0] animate-pulse" />
            </div>
          ) : (
            <>
              <div className="flex flex-col items-center mb-6">
                <div className="relative w-36 h-36">
                  <svg viewBox="0 0 36 36" className="w-36 h-36 -rotate-90">
                    <circle cx="18" cy="18" r="15.9" fill="none" stroke="#f1f4f9" strokeWidth="3" />
                    <circle cx="18" cy="18" r="15.9" fill="none" stroke="#22C55E" strokeWidth="3"
                      strokeDasharray={`${resolutionRate} ${100 - resolutionRate}`}
                      strokeDashoffset="0" strokeLinecap="round" />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-3xl font-bold text-[#181c20]">{resolutionRate}%</span>
                    <span className="text-xs text-[#64748B]">résolus</span>
                  </div>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { label: 'À traiter', value: (byStatus['submitted'] ?? 0) + (byStatus['received'] ?? 0), color: '#0EA5E9' },
                  { label: 'En cours', value: active, color: '#F97316' },
                  { label: 'Résolus', value: resolved, color: '#22C55E' },
                  { label: 'Rejetés', value: byStatus['rejected'] ?? 0, color: '#EF4444' },
                ].map(s => (
                  <div key={s.label} className="p-3 rounded-xl text-center" style={{ backgroundColor: `${s.color}10` }}>
                    <p className="text-xl font-bold" style={{ color: s.color }}>{s.value}</p>
                    <p className="text-xs text-[#64748B]">{s.label}</p>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>

      {/* Status detail table */}
      <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-[#E2E8F0]">
          <h3 className="text-sm font-bold text-[#181c20]">Détail par statut</h3>
        </div>
        <table className="w-full text-left">
          <thead>
            <tr className="bg-[#f7f9fe] border-b border-[#E2E8F0]">
              {['Statut', 'Signalements', 'Part (%)', 'Indicateur'].map(h => (
                <th key={h} className="px-5 py-3 text-xs font-semibold text-[#64748B] uppercase tracking-wider">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E2E8F0]">
            {loading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 4 }).map((__, j) => (
                      <td key={j} className="px-5 py-3.5"><div className="h-4 bg-[#E2E8F0] rounded w-20" /></td>
                    ))}
                  </tr>
                ))
              : statusOrder.map(key => {
                  const meta = STATUS_META[key]
                  const count = byStatus[key] ?? 0
                  const pct = Math.round((count / total) * 100)
                  return (
                    <tr key={key} className="hover:bg-[#f7f9fe] transition-colors">
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full" style={{ backgroundColor: meta.color }} />
                          <span className="text-sm font-medium text-[#181c20]">{meta.label}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5 text-sm font-bold text-[#181c20]">{count}</td>
                      <td className="px-5 py-3.5 text-sm text-[#64748B]">{pct}%</td>
                      <td className="px-5 py-3.5 w-48">
                        <div className="w-full h-1.5 bg-[#f1f4f9] rounded-full overflow-hidden">
                          <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: meta.color }} />
                        </div>
                      </td>
                    </tr>
                  )
                })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
