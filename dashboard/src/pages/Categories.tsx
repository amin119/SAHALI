import { useState, useEffect } from 'react'
import { api } from '../lib/api'

interface Category {
  id: number
  slug: string
  label_fr: string
  icon: string | null
  sla_hours: number | null
  parent_id: number | null
  children: Category[]
}

const CAT_COLORS: Record<string, string> = {
  infrastructure: '#0038AF', lighting: '#F59E0B', waste: '#22C55E',
  environment: '#10B981', water_sanitation: '#0EA5E9', transport: '#8B5CF6', safety: '#EF4444',
}

function rootColor(slug: string): string {
  const root = slug.split('.')[0]
  return CAT_COLORS[root] ?? '#64748B'
}

function Skeleton() {
  return (
    <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-5 animate-pulse">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#E2E8F0]" />
          <div>
            <div className="h-4 bg-[#E2E8F0] rounded w-32 mb-1" />
            <div className="h-3 bg-[#E2E8F0] rounded w-20" />
          </div>
        </div>
        <div className="w-10 h-5 bg-[#E2E8F0] rounded-full" />
      </div>
      <div className="h-12 bg-[#E2E8F0] rounded-lg mb-4" />
      <div className="h-2 bg-[#E2E8F0] rounded-full" />
    </div>
  )
}

export default function Categories() {
  const [categories, setCategories] = useState<Category[]>([])
  const [enabled, setEnabled] = useState<Set<number>>(new Set())
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    api.get<Category[]>('/categories')
      .then(data => {
        setCategories(data)
        setEnabled(new Set(data.map(c => c.id)))
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  // flatten tree into display list: show parents and their children
  const displayCats: Category[] = []
  categories.forEach(parent => {
    displayCats.push(parent)
    parent.children?.forEach(child => displayCats.push(child))
  })

  function toggleEnabled(id: number) {
    setEnabled(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function slaLabel(hours: number | null) {
    if (!hours) return 'Standard'
    if (hours <= 24) return 'Critique'
    if (hours <= 48) return 'Haute'
    if (hours <= 72) return 'Moyenne'
    return 'Standard'
  }

  function slaColor(hours: number | null) {
    if (!hours || hours > 72) return { bg: '#22C55E18', text: '#22C55E' }
    if (hours <= 24) return { bg: '#EF444418', text: '#EF4444' }
    if (hours <= 48) return { bg: '#F9731618', text: '#F97316' }
    return { bg: '#F59E0B18', text: '#F59E0B' }
  }

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-6 gap-4">
        <div>
          <h2 className="text-[#0F172A] text-2xl font-bold">Catégories</h2>
          <p className="text-[#64748B] text-sm mt-1">
            {loading ? 'Chargement...' : `${displayCats.length} catégories configurées`}
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
      {!loading && categories.length > 0 && (
        <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-4 mb-6 flex items-center gap-6 overflow-x-auto">
          <div className="flex-shrink-0">
            <p className="text-xs text-[#64748B] uppercase tracking-wider font-semibold">Catégories racines</p>
            <p className="text-3xl font-bold text-[#181c20]">{categories.length}</p>
          </div>
          <div className="h-12 w-px bg-[#E2E8F0] flex-shrink-0" />
          {categories.map(c => {
            const color = rootColor(c.slug)
            return (
              <div key={c.id} className="flex-shrink-0 text-center min-w-20">
                <div className="flex items-center gap-1.5 mb-1 justify-center">
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
                  <span className="text-xs text-[#64748B] truncate max-w-20">{c.label_fr.split(' ')[0]}</span>
                </div>
                <p className="text-xs font-bold text-[#181c20]">{c.sla_hours ?? '—'}h SLA</p>
              </div>
            )
          })}
        </div>
      )}

      {/* Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
        {loading
          ? Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} />)
          : displayCats.map(cat => {
              const color = rootColor(cat.slug)
              const isEnabled = enabled.has(cat.id)
              const slaMeta = slaColor(cat.sla_hours)
              const isChild = cat.parent_id !== null

              return (
                <div key={cat.id}
                  className={`bg-white rounded-xl border shadow-sm p-5 transition-all hover:shadow-md
                    ${isEnabled ? 'border-[#E2E8F0]' : 'border-[#E2E8F0] opacity-60'}
                    ${isChild ? 'ml-4 border-l-4' : ''}`}
                  style={isChild ? { borderLeftColor: color } : {}}>

                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl flex items-center justify-center"
                        style={{ backgroundColor: `${color}18` }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 20, color }}>
                          {cat.icon ?? 'category'}
                        </span>
                      </div>
                      <div>
                        <p className="text-sm font-bold text-[#181c20]">{cat.label_fr}</p>
                        <p className="text-xs text-[#94A3B8] font-mono">{cat.slug}</p>
                      </div>
                    </div>
                    <button
                      onClick={() => toggleEnabled(cat.id)}
                      className="w-10 h-5 rounded-full relative transition-colors flex-shrink-0"
                      style={{ backgroundColor: isEnabled ? color : '#E2E8F0' }}>
                      <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white shadow-sm transition-all
                        ${isEnabled ? 'left-5' : 'left-0.5'}`} />
                    </button>
                  </div>

                  <div className="flex items-center gap-4 mb-4">
                    <div className="flex-1 text-center p-2.5 rounded-lg bg-[#f1f4f9]">
                      <p className="text-xl font-bold text-[#181c20]">{cat.sla_hours ?? '—'}h</p>
                      <p className="text-[10px] text-[#64748B]">SLA cible</p>
                    </div>
                    <div className="flex-1 text-center p-2.5 rounded-lg" style={{ backgroundColor: `${color}10` }}>
                      <p className="text-xl font-bold" style={{ color }}>
                        {cat.children?.length > 0 ? cat.children.length : '—'}
                      </p>
                      <p className="text-[10px] text-[#64748B]">
                        {cat.children?.length > 0 ? 'sous-catégories' : 'sous-catég.'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-xs px-2 py-0.5 rounded-full font-semibold"
                      style={{ backgroundColor: slaMeta.bg, color: slaMeta.text }}>
                      Priorité {slaLabel(cat.sla_hours)}
                    </span>
                    <span className="text-xs text-[#94A3B8]">
                      {cat.parent_id ? 'Sous-catégorie' : 'Catégorie racine'}
                    </span>
                  </div>
                </div>
              )
            })}
      </div>
    </div>
  )
}
