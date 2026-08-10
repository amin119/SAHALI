import { useState, useEffect, useCallback, Suspense, lazy } from 'react'
import { api } from '../lib/api'
import type { Municipality, MunicipalityListOut, User } from '../types/api'
import { useLang } from '../context/LangContext'

// Leaflet is heavy — only load it when the add/edit modal with the location
// picker is actually opened, not on every visit to this page.
const LocationPicker = lazy(() => import('../components/ui/LocationPicker'))

const PAGE_SIZE = 20

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
      {Array.from({ length: 8 }).map((_, j) => (
        <td key={j} className="px-5 py-4"><div className="h-4 bg-[#E2E8F0] rounded w-20" /></td>
      ))}
    </tr>
  )
}

interface MuniForm {
  name: string
  subscription_tier: string
  logo_url: string
  lat: number | null
  lng: number | null
}

const EMPTY_FORM: MuniForm = { name: '', subscription_tier: '', logo_url: '', lat: null, lng: null }

export default function Municipalities() {
  const { t } = useLang()
  const [municipalities, setMunicipalities] = useState<Municipality[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedId, setSelectedId] = useState<number | null>(null)

  // Add / edit modal
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [form, setForm] = useState<MuniForm>(EMPTY_FORM)
  const [formError, setFormError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  // Delete confirm
  const [deleteTarget, setDeleteTarget] = useState<Municipality | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)

  // Agents working in the selected municipality
  const [agents, setAgents] = useState<User[]>([])
  const [agentsLoading, setAgentsLoading] = useState(false)

  // Debounce the search box before it hits the server
  useEffect(() => {
    const id = setTimeout(() => { setDebouncedSearch(search); setPage(1) }, 350)
    return () => clearTimeout(id)
  }, [search])

  const fetchMunicipalities = useCallback(() => {
    setLoading(true)
    setError(null)
    const params: Record<string, string | number | undefined> = { page, page_size: PAGE_SIZE }
    if (debouncedSearch) params.search = debouncedSearch
    api.get<MunicipalityListOut>('/admin/municipalities', params)
      .then(data => { setMunicipalities(data.items ?? []); setTotal(data.total ?? 0) })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [page, debouncedSearch])

  useEffect(() => { fetchMunicipalities() }, [fetchMunicipalities])

  useEffect(() => {
    if (selectedId == null) { setAgents([]); return }
    setAgentsLoading(true)
    api.get<User[]>(`/admin/municipalities/${selectedId}/agents`)
      .then(setAgents)
      .catch(() => setAgents([]))
      .finally(() => setAgentsLoading(false))
  }, [selectedId])

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const totalReports = municipalities.reduce((s, m) => s + m.total_reports, 0)
  const avgResolution = municipalities.length
    ? Math.round(municipalities.reduce((s, m) => s + m.resolution_rate, 0) / municipalities.length)
    : 0
  const totalAgents = municipalities.reduce((s, m) => s + m.agent_count, 0)
  const detail = municipalities.find(m => m.id === selectedId)

  const tableHeaders = [
    t('col_muni'), t('col_subscription'), t('col_reports_count'),
    t('col_open_reports'), t('stat_resolved_n'), t('col_agents_m'), t('col_rate'), t('col_actions'),
  ]

  function openAdd() {
    setEditingId(null)
    setForm(EMPTY_FORM)
    setFormError(null)
    setShowForm(true)
  }

  function openEdit(m: Municipality) {
    setEditingId(m.id)
    setForm({ name: m.name, subscription_tier: m.subscription_tier ?? '', logo_url: '', lat: m.lat, lng: m.lng })
    setFormError(null)
    setShowForm(true)
  }

  async function submitForm() {
    if (!form.name.trim()) { setFormError(t('required_fields_err')); return }
    setSubmitting(true)
    setFormError(null)
    try {
      const body = {
        name: form.name.trim(),
        subscription_tier: form.subscription_tier || null,
        logo_url: form.logo_url.trim() || null,
        lat: form.lat,
        lng: form.lng,
      }
      if (editingId != null) {
        await api.patch(`/admin/municipalities/${editingId}`, body)
      } else {
        await api.post('/admin/municipalities', body)
      }
      setShowForm(false)
      fetchMunicipalities()
    } catch (e: unknown) {
      setFormError(e instanceof Error ? e.message : t('err_creation'))
    } finally {
      setSubmitting(false)
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return
    setDeleting(true)
    setDeleteError(null)
    try {
      await api.delete(`/admin/municipalities/${deleteTarget.id}`)
      setDeleteTarget(null)
      if (selectedId === deleteTarget.id) setSelectedId(null)
      fetchMunicipalities()
    } catch (e: unknown) {
      setDeleteError(e instanceof Error ? e.message : t('err_creation'))
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_municipalities')}</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? t('loading') : `${total.toLocaleString()} ${t('muni_registered')}`}
          </p>
        </div>
        <button
          data-tour="muni-add"
          onClick={openAdd}
          className="flex items-center gap-2 px-4 py-2 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity">
          <span className="material-symbols-outlined" style={{ fontSize: 18 }}>add_location_alt</span>
          {t('btn_add_municipality')}
        </button>
      </div>

      {/* Search */}
      <div className="bg-white rounded-xl border border-[#E2E8F0] p-4 mb-4 flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-48">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#747686]" style={{ fontSize: 16 }}>search</span>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            type="text"
            placeholder={t('muni_search_placeholder')}
            className="w-full bg-[#f1f4f9] rounded-lg pl-9 pr-4 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 border-0"
          />
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-6">
          <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
          <span className="text-sm text-red-600">{error}</span>
        </div>
      )}

      {/* Summary strip (reflects the currently loaded page) */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        {[
          { label: t('nav_municipalities'), value: loading ? '—' : total, icon: 'location_city', color: '#0038AF' },
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
        <div className="flex-1 min-w-0" data-tour="muni-table">
          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
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
                  ? Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} />)
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
                          <td className="px-5 py-4" onClick={e => e.stopPropagation()}>
                            <div className="flex items-center gap-1">
                              <button onClick={() => openEdit(m)} title={t('btn_edit')}
                                className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-[#eceef3]">
                                <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 16 }}>edit</span>
                              </button>
                              <button onClick={() => { setDeleteTarget(m); setDeleteError(null) }} title={t('btn_delete')}
                                className="w-7 h-7 flex items-center justify-center rounded-md hover:bg-red-50">
                                <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>delete</span>
                              </button>
                            </div>
                          </td>
                        </tr>
                      )
                    })}
              </tbody>
            </table>
            {!loading && municipalities.length === 0 && (
              <div className="flex flex-col items-center justify-center py-16 text-[#94A3B8]">
                <span className="material-symbols-outlined mb-3" style={{ fontSize: 40 }}>search_off</span>
                <p className="text-sm">{t('no_municipalities_found')}</p>
              </div>
            )}
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-4">
              <span className="text-sm text-[#64748B]">
                {t('page_word')} {page} {t('of_word')} {totalPages} · {total.toLocaleString()} {t('results')}
              </span>
              <div className="flex items-center gap-2">
                <button disabled={page === 1} onClick={() => setPage(p => p - 1)}
                  className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe]">
                  {t('prev')}
                </button>
                <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}
                  className="px-3 py-1.5 rounded-lg bg-white border border-[#E2E8F0] text-sm disabled:opacity-40 hover:bg-[#f7f9fe]">
                  {t('next')}
                </button>
              </div>
            </div>
          )}
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

                <div className="mb-4">
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="text-xs font-semibold text-[#64748B]">{t('muni_detail_rate')}</span>
                    <span className="text-sm font-bold" style={{ color: rateColor }}>{detail.resolution_rate}%</span>
                  </div>
                  <div className="w-full h-2 bg-[#f1f4f9] rounded-full overflow-hidden">
                    <div className="h-full rounded-full" style={{ width: `${detail.resolution_rate}%`, backgroundColor: rateColor }} />
                  </div>
                </div>

                {detail.lat != null && detail.lng != null && (
                  <div className="mb-4">
                    <p className="text-xs font-semibold text-[#64748B] mb-1.5">{t('muni_location')}</p>
                    <a
                      href={`https://www.google.com/maps?q=${detail.lat},${detail.lng}`}
                      target="_blank" rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-[#f0f4ff] border border-[#0038AF]/20 hover:bg-[#e0e9ff] transition-colors group w-full"
                    >
                      <span className="material-symbols-outlined text-[#0038AF]" style={{ fontSize: 16 }}>location_on</span>
                      <span className="text-xs font-mono text-[#0038AF] flex-1">{detail.lat.toFixed(4)}, {detail.lng.toFixed(4)}</span>
                      <span className="material-symbols-outlined text-[#0038AF] opacity-60 group-hover:opacity-100 transition-opacity" style={{ fontSize: 13 }}>open_in_new</span>
                    </a>
                  </div>
                )}

                <div className="mb-4">
                  <p className="text-xs font-semibold text-[#64748B] mb-1.5">{t('muni_agents_list')}</p>
                  {agentsLoading ? (
                    <div className="space-y-1.5">
                      {[1, 2].map(i => <div key={i} className="h-8 bg-[#f1f4f9] rounded-lg animate-pulse" />)}
                    </div>
                  ) : agents.length === 0 ? (
                    <p className="text-xs text-[#94A3B8] text-center py-2">{t('muni_no_agents')}</p>
                  ) : (
                    <div className="space-y-1.5 max-h-40 overflow-y-auto">
                      {agents.map(a => (
                        <div key={a.id} className="flex items-center gap-2 px-2.5 py-1.5 bg-[#f7f9fe] rounded-lg">
                          <div className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${a.is_active ? 'bg-[#22C55E]' : 'bg-[#94A3B8]'}`} />
                          <span className="text-xs font-medium text-[#181c20] truncate flex-1">{a.full_name}</span>
                          <span className="text-[10px] text-[#94A3B8] capitalize flex-shrink-0">{a.role.replace('_', ' ')}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div className="flex gap-2">
                  <button onClick={() => openEdit(detail)}
                    className="flex-1 py-2 rounded-xl text-sm font-medium bg-[#f1f4f9] text-[#181c20] hover:bg-[#e2e8f0] transition-colors">
                    {t('btn_edit')}
                  </button>
                  <button onClick={() => { setDeleteTarget(detail); setDeleteError(null) }}
                    className="flex-1 py-2 rounded-xl text-sm font-medium bg-red-50 text-red-500 hover:bg-red-100 transition-colors">
                    {t('btn_delete')}
                  </button>
                </div>
              </div>
            </div>
          )
        })()}
      </div>

      {/* Add / Edit Modal */}
      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
          onClick={e => { if (e.target === e.currentTarget) setShowForm(false) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-5 border-b border-[#E2E8F0] flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-[#181c20]">
                  {editingId != null ? t('modal_edit_muni_title') : t('modal_add_muni_title')}
                </h3>
                <p className="text-xs text-[#64748B] mt-0.5">
                  {editingId != null ? t('modal_edit_muni_sub') : t('modal_add_muni_sub')}
                </p>
              </div>
              <button onClick={() => setShowForm(false)} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#f1f4f9]">
                <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>close</span>
              </button>
            </div>
            <div className="p-6 space-y-4">
              {formError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3">
                  <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
                  <span className="text-sm text-red-600">{formError}</span>
                </div>
              )}
              <div>
                <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_muni_name')}</label>
                <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                  placeholder="ex: Tunis"
                  className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_subscription_tier')}</label>
                <select value={form.subscription_tier} onChange={e => setForm(f => ({ ...f, subscription_tier: e.target.value }))}
                  className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                  <option value="">{t('tier_none')}</option>
                  <option value="basic">{t('tier_basic')}</option>
                  <option value="standard">{t('tier_standard')}</option>
                  <option value="pro">{t('tier_pro')}</option>
                  <option value="premium">{t('tier_premium')}</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider mb-1.5">{t('lbl_logo_url')}</label>
                <input value={form.logo_url} onChange={e => setForm(f => ({ ...f, logo_url: e.target.value }))}
                  placeholder="https://..."
                  className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
              </div>
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs font-semibold text-[#64748B] uppercase tracking-wider">{t('lbl_location')}</label>
                  <span className="text-[10px] font-mono text-[#94A3B8]">
                    {form.lat != null && form.lng != null ? `${form.lat.toFixed(4)}, ${form.lng.toFixed(4)}` : t('muni_location_unset')}
                  </span>
                </div>
                <p className="text-[10px] text-[#94A3B8] mb-2">{t('lbl_location_hint')}</p>
                <Suspense fallback={<div className="h-[220px] bg-[#f1f4f9] rounded-xl animate-pulse" />}>
                  <LocationPicker
                    lat={form.lat}
                    lng={form.lng}
                    onChange={(lat, lng) => setForm(f => ({ ...f, lat, lng }))}
                  />
                </Suspense>
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3">
              <button onClick={() => setShowForm(false)}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                {t('btn_cancel')}
              </button>
              <button onClick={submitForm} disabled={submitting}
                className="flex-1 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                {submitting ? t('creating') : t('btn_save')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete confirm */}
      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
          onClick={e => { if (e.target === e.currentTarget) setDeleteTarget(null) }}>
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-full bg-red-50 flex items-center justify-center flex-shrink-0">
                <span className="material-symbols-outlined text-red-500" style={{ fontSize: 20 }}>warning</span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#181c20]">{t('confirm_delete_muni_title')}</h3>
                <p className="text-xs text-[#64748B]">{deleteTarget.name}</p>
              </div>
            </div>
            <p className="text-sm text-[#64748B] mb-4">{t('confirm_delete_muni_body')}</p>
            {deleteError && (
              <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
                <span className="text-sm text-red-600">{deleteError}</span>
              </div>
            )}
            <div className="flex gap-3">
              <button onClick={() => setDeleteTarget(null)}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                {t('btn_cancel')}
              </button>
              <button onClick={confirmDelete} disabled={deleting}
                className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                {deleting ? t('deleting') : t('btn_delete')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
