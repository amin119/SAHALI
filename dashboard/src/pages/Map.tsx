import { useState, useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { api } from '../lib/api'
import type { Report, ReportStatus } from '../types/api'
import StatusBadge from '../components/ui/StatusBadge'
import { useLang } from '../context/LangContext'

// Fix Leaflet default icon path broken by Vite bundling
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl:       'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl:     'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
})

const STATUS_COLOR: Record<ReportStatus, string> = {
  submitted:    '#94A3B8',
  received:     '#0EA5E9',
  under_review: '#F59E0B',
  in_progress:  '#0038AF',
  resolved:     '#22C55E',
  rejected:     '#EF4444',
}

interface AdminStats {
  total_reports: number
  today_reports: number
  by_status: Record<string, number>
  avg_resolution_hours: number
}

function makeCircleIcon(color: string) {
  return L.divIcon({
    className: '',
    html: `<div style="width:14px;height:14px;border-radius:50%;background:${color};border:2px solid white;box-shadow:0 1px 4px rgba(0,0,0,.3)"></div>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7],
  })
}

export default function Map() {
  const { t } = useLang()
  const mapRef = useRef<L.Map | null>(null)
  const markersRef = useRef<L.Marker[]>([])
  const mapContainerRef = useRef<HTMLDivElement>(null)

  const [reports, setReports] = useState<Report[]>([])
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<Report | null>(null)
  const [filterStatus, setFilterStatus] = useState<ReportStatus | 'all'>('all')

  const STATUS_LABELS: Record<ReportStatus, string> = {
    submitted:    t('status_submitted'),
    received:     t('status_received'),
    under_review: t('status_under_review'),
    in_progress:  t('status_in_progress'),
    resolved:     t('status_resolved'),
    rejected:     t('status_rejected'),
  }

  // Init Leaflet map once
  useEffect(() => {
    if (!mapContainerRef.current || mapRef.current) return

    const map = L.map(mapContainerRef.current, {
      center: [36.5, 10.2],
      zoom: 8,
      zoomControl: true,
    })

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      maxZoom: 19,
    }).addTo(map)

    mapRef.current = map

    return () => {
      map.remove()
      mapRef.current = null
    }
  }, [])

  // Load data
  useEffect(() => {
    Promise.all([
      api.get<{ items: Report[]; total: number }>('/reports', { page_size: '500' }),
      api.get<AdminStats>('/admin/stats'),
    ])
      .then(([rData, sData]) => {
        setStats(sData)
        setReports(rData.items ?? [])
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  // Update markers when reports or filter changes
  useEffect(() => {
    const map = mapRef.current
    if (!map) return

    // Remove existing markers
    markersRef.current.forEach(m => m.remove())
    markersRef.current = []

    const toShow = filterStatus === 'all'
      ? reports
      : reports.filter(r => r.status === filterStatus)

    toShow.forEach(r => {
      if (r.lat == null || r.lng == null) return
      const marker = L.marker([r.lat, r.lng], { icon: makeCircleIcon(STATUS_COLOR[r.status]) })
      marker.bindPopup(`
        <div style="min-width:180px;font-family:sans-serif">
          <p style="font-size:10px;color:#94A3B8;margin:0 0 4px">${r.tracking_code}</p>
          <p style="font-size:13px;font-weight:600;color:#181c20;margin:0 0 6px;line-height:1.3">${r.title}</p>
          ${r.city ? `<p style="font-size:11px;color:#64748B;margin:0">${r.city}</p>` : ''}
        </div>
      `, { maxWidth: 220 })
      marker.on('click', () => setSelected(r))
      marker.addTo(map)
      markersRef.current.push(marker)
    })
  }, [reports, filterStatus])

  const displayed = filterStatus === 'all' ? reports.filter(r => r.lat != null) : reports.filter(r => r.status === filterStatus && r.lat != null)
  const byStatus = stats?.by_status ?? {}

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('map_title')}</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? t('loading') : `${displayed.length} ${t('map_subtitle')}`}
          </p>
        </div>
        <select
          value={filterStatus}
          onChange={e => setFilterStatus(e.target.value as ReportStatus | 'all')}
          className="px-3 py-2 text-sm bg-white border border-[#E2E8F0] rounded-xl text-[#181c20] focus:outline-none focus:border-[#0038AF]"
        >
          <option value="all">{t('map_all_statuses')}</option>
          {(Object.keys(STATUS_LABELS) as ReportStatus[]).map(s => (
            <option key={s} value={s}>{STATUS_LABELS[s]}</option>
          ))}
        </select>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-6">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      <div className="flex gap-5">
        {/* Map */}
        <div className="flex-1 min-w-0">
          <div className="rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden" style={{ height: 520 }}>
            {loading && (
              <div className="w-full h-full bg-[#f1f4f9] flex items-center justify-center">
                <p className="text-sm text-[#94A3B8]">{t('loading')}</p>
              </div>
            )}
            <div ref={mapContainerRef} style={{ width: '100%', height: '100%', display: loading ? 'none' : 'block' }} />
          </div>

          {/* Legend */}
          <div className="mt-4 bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4 flex flex-wrap gap-4">
            {(Object.keys(STATUS_LABELS) as ReportStatus[]).map(s => (
              <button
                key={s}
                onClick={() => setFilterStatus(filterStatus === s ? 'all' : s)}
                className={`flex items-center gap-1.5 text-xs transition-opacity ${filterStatus !== 'all' && filterStatus !== s ? 'opacity-40' : ''}`}
              >
                <span className="w-3 h-3 rounded-full" style={{ backgroundColor: STATUS_COLOR[s] }} />
                <span className="text-[#64748B]">{STATUS_LABELS[s]}</span>
                <span className="font-bold text-[#181c20]">{byStatus[s] ?? 0}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Sidebar */}
        <div className="w-56 flex-shrink-0 space-y-4">
          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4">
            <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-3">{t('map_summary')}</p>
            {loading ? (
              <div className="space-y-3 animate-pulse">
                {Array.from({ length: 4 }).map((_, i) => <div key={i} className="h-10 bg-[#E2E8F0] rounded-lg" />)}
              </div>
            ) : (
              <div className="space-y-3">
                {[
                  { label: t('map_total'),    value: stats?.total_reports ?? 0,        color: '#0038AF' },
                  { label: t('map_today'),    value: stats?.today_reports ?? 0,        color: '#F97316' },
                  { label: t('map_displayed'),value: displayed.length,                 color: '#8B5CF6' },
                  { label: t('map_avg'),      value: `${stats?.avg_resolution_hours ?? 0}h`, color: '#22C55E' },
                ].map(s => (
                  <div key={s.label} className="flex items-center justify-between p-2.5 rounded-lg" style={{ backgroundColor: `${s.color}10` }}>
                    <span className="text-xs text-[#64748B]">{s.label}</span>
                    <span className="text-sm font-bold" style={{ color: s.color }}>{s.value}</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4">
            <p className="text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-3">{t('map_by_status')}</p>
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
          </div>

          {/* Selected report card */}
          {selected && (
            <div className="bg-white rounded-xl border border-[#0038AF]/30 shadow-sm p-4">
              <div className="flex items-start justify-between mb-2">
                <p className="text-xs font-mono text-[#94A3B8]">{selected.tracking_code}</p>
                <button onClick={() => setSelected(null)} className="text-[#94A3B8] hover:text-[#181c20]">
                  <span className="material-symbols-outlined" style={{ fontSize: 14 }}>close</span>
                </button>
              </div>
              <p className="text-sm font-semibold text-[#181c20] mb-1 line-clamp-2">{selected.title}</p>
              {selected.city && <p className="text-xs text-[#64748B] mb-2">{selected.city}</p>}
              <StatusBadge status={selected.status} />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
