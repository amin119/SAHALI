import { useState, useEffect } from 'react'
import { api } from '../lib/api'
import type { Report, ReportStatus } from '../types/api'

const STATUS_COLOR: Record<ReportStatus, string> = {
  submitted:    '#94A3B8',
  received:     '#0EA5E9',
  under_review: '#F59E0B',
  scheduled:    '#8B5CF6',
  in_progress:  '#0038AF',
  resolved:     '#22C55E',
  closed:       '#64748B',
  rejected:     '#EF4444',
}

const STATUS_LABELS: Record<ReportStatus, string> = {
  submitted:    'Soumis',
  received:     'Reçu',
  under_review: 'En examen',
  scheduled:    'Planifié',
  in_progress:  'En cours',
  resolved:     'Résolu',
  closed:       'Fermé',
  rejected:     'Rejeté',
}

interface Pin {
  id: string
  tracking_code: string
  title: string
  status: ReportStatus
  priority: string
  city: string | null
  x: number
  y: number
}

interface AdminStats {
  total_reports: number
  today_reports: number
  by_status: Record<string, number>
  avg_resolution_hours: number
}

function lngToX(lng: number): number {
  return Math.min(100, Math.max(0, ((lng - 9) / (11.5 - 9)) * 100))
}

function latToY(lat: number): number {
  return Math.min(100, Math.max(0, ((37.5 - lat) / (37.5 - 34.5)) * 100))
}

const PRIORITY_COLOR: Record<string, string> = {
  low: '#22C55E', medium: '#F59E0B', high: '#F97316', critical: '#EF4444',
}

export default function Map() {
  const [pins, setPins] = useState<Pin[]>([])
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<Pin | null>(null)
  const [filterStatus, setFilterStatus] = useState<ReportStatus | 'all'>('all')

  useEffect(() => {
    Promise.all([
      api.get<{ items: Report[]; total: number }>('/reports', { page_size: '200' }),
      api.get<AdminStats>('/admin/stats'),
    ])
      .then(([rData, sData]) => {
        setStats(sData)
        const validPins: Pin[] = []
        rData.items.forEach((r: Report) => {
          if (r.lat != null && r.lng != null) {
            validPins.push({
              id: r.id,
              tracking_code: r.tracking_code,
              title: r.title,
              status: r.status,
              priority: r.priority ?? 'medium',
              city: r.city,
              x: lngToX(r.lng),
              y: latToY(r.lat),
            })
          }
        })
        setPins(validPins)
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const displayed = filterStatus === 'all' ? pins : pins.filter(p => p.status === filterStatus)
  const byStatus = stats?.by_status ?? {}

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">Carte</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? 'Chargement...' : `${pins.length} signalements géolocalisés`}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <select value={filterStatus} onChange={e => setFilterStatus(e.target.value as ReportStatus | 'all')}
            className="px-3 py-2 text-sm bg-white border border-[#E2E8F0] rounded-xl text-[#181c20] focus:outline-none focus:border-[#0038AF]">
            <option value="all">Tous les statuts</option>
            {(Object.keys(STATUS_LABELS) as ReportStatus[]).map(s => (
              <option key={s} value={s}>{STATUS_LABELS[s]}</option>
            ))}
          </select>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-6">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      <div className="flex gap-5">
        {/* Map area */}
        <div className="flex-1 min-w-0">
          <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden" style={{ height: 520 }}>
            {loading ? (
              <div className="w-full h-full bg-[#f1f4f9] animate-pulse flex items-center justify-center">
                <div className="text-center">
                  <span className="material-symbols-outlined text-[#94A3B8]" style={{ fontSize: 48 }}>map</span>
                  <p className="text-sm text-[#94A3B8] mt-2">Chargement de la carte...</p>
                </div>
              </div>
            ) : (
              <div className="relative w-full h-full"
                style={{
                  backgroundImage: `
                    radial-gradient(circle at 30% 70%, #dbeafe44 0%, transparent 50%),
                    radial-gradient(circle at 70% 30%, #dcfce744 0%, transparent 50%),
                    linear-gradient(135deg, #f0f9ff 0%, #f7fee7 50%, #fefce8 100%)
                  `,
                }}
                onClick={() => setSelected(null)}>

                {/* Tunisia outline hint */}
                <div className="absolute inset-4 rounded-xl border-2 border-dashed border-[#CBD5E1] opacity-30" />
                <div className="absolute top-4 left-4 text-xs text-[#94A3B8] font-semibold">Tunisie — vue nationale</div>

                {/* City labels */}
                {[
                  { name: 'Tunis', lat: 36.85, lng: 10.22 },
                  { name: 'Sfax', lat: 34.74, lng: 10.76 },
                  { name: 'Sousse', lat: 35.83, lng: 10.64 },
                  { name: 'Bizerte', lat: 37.27, lng: 9.86 },
                  { name: 'Gabès', lat: 33.88, lng: 10.10 },
                ].map(c => (
                  <span key={c.name} className="absolute text-[10px] text-[#94A3B8] font-semibold pointer-events-none select-none"
                    style={{ left: `${lngToX(c.lng)}%`, top: `${latToY(c.lat)}%`, transform: 'translate(-50%, -150%)' }}>
                    {c.name}
                  </span>
                ))}

                {/* Pins */}
                {displayed.map(pin => {
                  const color = STATUS_COLOR[pin.status]
                  const isSelected = selected?.id === pin.id
                  return (
                    <button key={pin.id}
                      onClick={e => { e.stopPropagation(); setSelected(isSelected ? null : pin) }}
                      className="absolute transition-transform hover:scale-125 focus:outline-none"
                      style={{
                        left: `${pin.x}%`, top: `${pin.y}%`,
                        transform: `translate(-50%, -50%) scale(${isSelected ? 1.5 : 1})`,
                        zIndex: isSelected ? 20 : 10,
                      }}>
                      <div className="w-3.5 h-3.5 rounded-full border-2 border-white shadow-md transition-all"
                        style={{ backgroundColor: color }} />
                    </button>
                  )
                })}

                {/* Selected popup */}
                {selected && (
                  <div className="absolute z-30 bg-white rounded-xl shadow-xl border border-[#E2E8F0] p-4 w-56"
                    style={{
                      left: `${Math.min(selected.x, 65)}%`,
                      top: `${Math.max(selected.y - 5, 5)}%`,
                      transform: 'translate(-50%, -100%)',
                    }}>
                    <div className="flex items-start justify-between mb-2">
                      <span className="text-xs font-mono text-[#94A3B8]">{selected.tracking_code}</span>
                      <div className="w-2.5 h-2.5 rounded-full flex-shrink-0 mt-0.5"
                        style={{ backgroundColor: STATUS_COLOR[selected.status] }} />
                    </div>
                    <p className="text-sm font-bold text-[#181c20] mb-1 line-clamp-2">{selected.title}</p>
                    {selected.city && <p className="text-xs text-[#64748B]">{selected.city}</p>}
                    <div className="flex items-center gap-2 mt-2">
                      <span className="text-xs px-1.5 py-0.5 rounded"
                        style={{ backgroundColor: `${STATUS_COLOR[selected.status]}18`, color: STATUS_COLOR[selected.status] }}>
                        {STATUS_LABELS[selected.status]}
                      </span>
                      <span className="text-xs px-1.5 py-0.5 rounded"
                        style={{ backgroundColor: `${PRIORITY_COLOR[selected.priority] ?? '#94A3B8'}18`, color: PRIORITY_COLOR[selected.priority] ?? '#94A3B8' }}>
                        {selected.priority}
                      </span>
                    </div>
                    <div className="absolute bottom-[-8px] left-1/2 -translate-x-1/2 w-4 h-4 bg-white border-r border-b border-[#E2E8F0] rotate-45" />
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Legend */}
          <div className="mt-4 bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4 flex flex-wrap gap-4">
            {(Object.keys(STATUS_LABELS) as ReportStatus[]).map(s => (
              <button key={s} onClick={() => setFilterStatus(filterStatus === s ? 'all' : s)}
                className={`flex items-center gap-1.5 text-xs transition-opacity ${filterStatus !== 'all' && filterStatus !== s ? 'opacity-40' : ''}`}>
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: STATUS_COLOR[s] }} />
                <span className="text-[#64748B]">{STATUS_LABELS[s]}</span>
                <span className="font-bold text-[#181c20]">{byStatus[s] ?? 0}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Sidebar stats */}
        <div className="w-56 flex-shrink-0 space-y-4">
          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4">
            <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-3">Résumé</p>
            {loading ? (
              <div className="space-y-3 animate-pulse">
                {Array.from({ length: 4 }).map((_, i) => (
                  <div key={i} className="h-10 bg-[#E2E8F0] rounded-lg" />
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {[
                  { label: 'Total', value: stats?.total_reports ?? 0, color: '#0038AF' },
                  { label: 'Aujourd\'hui', value: stats?.today_reports ?? 0, color: '#F97316' },
                  { label: 'Affichés', value: displayed.length, color: '#8B5CF6' },
                  { label: 'Moy. résolution', value: `${stats?.avg_resolution_hours ?? 0}h`, color: '#22C55E' },
                ].map(s => (
                  <div key={s.label} className="flex items-center justify-between p-2.5 rounded-lg"
                    style={{ backgroundColor: `${s.color}10` }}>
                    <span className="text-xs text-[#64748B]">{s.label}</span>
                    <span className="text-sm font-bold" style={{ color: s.color }}>{s.value}</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4">
            <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-3">Par statut</p>
            {loading ? (
              <div className="space-y-2 animate-pulse">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="h-5 bg-[#E2E8F0] rounded" />
                ))}
              </div>
            ) : (
              <div className="space-y-2">
                {(Object.keys(STATUS_LABELS) as ReportStatus[])
                  .filter(s => (byStatus[s] ?? 0) > 0)
                  .map(s => (
                    <div key={s} className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full" style={{ backgroundColor: STATUS_COLOR[s] }} />
                        <span className="text-xs text-[#64748B] truncate">{STATUS_LABELS[s]}</span>
                      </div>
                      <span className="text-xs font-bold text-[#181c20]">{byStatus[s] ?? 0}</span>
                    </div>
                  ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
