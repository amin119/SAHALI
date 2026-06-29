import { NavLink, useLocation } from 'react-router-dom'
import { useLang, type TranslationKey } from '../../context/LangContext'

const NAV_ITEMS: { path: string; icon: string; labelKey: TranslationKey }[] = [
  { path: '/dashboard',      icon: 'dashboard',      labelKey: 'nav_dashboard' },
  { path: '/map',            icon: 'map',            labelKey: 'nav_map' },
  { path: '/reports',        icon: 'report_problem', labelKey: 'nav_reports' },
  { path: '/interventions',  icon: 'engineering',    labelKey: 'nav_interventions' },
  { path: '/calendar',       icon: 'calendar_today', labelKey: 'nav_calendar' },
  { path: '/teams',          icon: 'groups',         labelKey: 'nav_teams' },
  { path: '/municipalities', icon: 'location_city',  labelKey: 'nav_municipalities' },
  { path: '/categories',     icon: 'category',       labelKey: 'nav_categories' },
  { path: '/statistics',     icon: 'insert_chart',   labelKey: 'nav_statistics' },
]

export default function Sidebar() {
  const location = useLocation()
  const { lang, setLang, t } = useLang()

  return (
    <aside
      style={{ width: 260, backgroundColor: '#131b2e' }}
      className="fixed left-0 top-0 h-screen flex flex-col z-50 shadow-xl"
    >
      {/* Logo */}
      <div className="px-6 py-5 mb-1">
        <h1 className="text-white text-xl font-bold tracking-tight">Sahali</h1>
        <p className="text-[#3f465c] text-xs mt-0.5">سهلي — Municipalité</p>
      </div>

      {/* Language toggle */}
      <div className="px-4 mb-3">
        <div className="flex rounded-lg bg-[#0d1520] p-0.5 gap-0.5">
          {(['fr', 'ar'] as const).map(l => (
            <button
              key={l}
              onClick={() => setLang(l)}
              className={`flex-1 py-1.5 rounded-md text-xs font-semibold transition-all ${
                lang === l ? 'bg-[#0038AF] text-white shadow' : 'text-[#3f465c] hover:text-white'
              }`}
            >
              {l === 'fr' ? t('lang_fr') : t('lang_ar')}
            </button>
          ))}
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto px-2 space-y-0.5">
        {NAV_ITEMS.map(({ path, icon, labelKey }) => {
          const isActive = location.pathname === path
          return (
            <NavLink
              key={path}
              to={path}
              className={`flex items-center gap-3 px-4 py-3 rounded-sm transition-all duration-150 text-sm font-medium
                ${isActive
                  ? 'bg-[#0038AF] text-white border-l-4 border-[#b6c4ff] translate-x-0.5'
                  : 'text-[#3f465c] hover:bg-[#525d71]/40 hover:text-white'
                }`}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 20 }}>{icon}</span>
              <span>{t(labelKey)}</span>
            </NavLink>
          )
        })}
      </nav>

      {/* Bottom */}
      <div className="border-t border-white/5 px-2 pt-2 pb-4 space-y-0.5">
        <NavLink
          to="/settings"
          className={({ isActive }) =>
            `flex items-center gap-3 px-4 py-3 rounded-sm transition-all duration-150 text-sm font-medium
              ${isActive
                ? 'bg-[#0038AF] text-white border-l-4 border-[#b6c4ff] translate-x-0.5'
                : 'text-[#3f465c] hover:bg-[#525d71]/40 hover:text-white'
              }`
          }
        >
          <span className="material-symbols-outlined" style={{ fontSize: 20 }}>settings</span>
          <span>{t('nav_settings')}</span>
        </NavLink>

        <div className="flex items-center gap-3 px-4 py-3 mt-1">
          <div className="w-9 h-9 rounded-lg bg-[#0038AF] flex items-center justify-center flex-shrink-0">
            <span className="material-symbols-outlined text-white" style={{ fontSize: 18 }}>location_city</span>
          </div>
          <div>
            <p className="text-white text-xs font-semibold">{t('sidebar_city')}</p>
            <p className="text-[#3f465c] text-[10px]">{t('sidebar_admin')}</p>
          </div>
        </div>
      </div>
    </aside>
  )
}
