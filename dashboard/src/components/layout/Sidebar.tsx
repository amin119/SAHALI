import { NavLink, useLocation } from 'react-router-dom'

const NAV_ITEMS = [
  { path: '/dashboard', icon: 'dashboard', label: 'Tableau de bord' },
  { path: '/map', icon: 'map', label: 'Carte en direct' },
  { path: '/reports', icon: 'report_problem', label: 'Signalements' },
  { path: '/interventions', icon: 'engineering', label: 'Interventions' },
  { path: '/calendar', icon: 'calendar_today', label: 'Calendrier' },
  { path: '/teams', icon: 'groups', label: 'Équipes & Agents' },
  { path: '/municipalities', icon: 'location_city', label: 'Municipalités' },
  { path: '/categories', icon: 'category', label: 'Catégories' },
  { path: '/statistics', icon: 'insert_chart', label: 'Statistiques' },
]

export default function Sidebar() {
  const location = useLocation()

  return (
    <aside
      style={{ width: 260, backgroundColor: '#131b2e' }}
      className="fixed left-0 top-0 h-screen flex flex-col z-50 shadow-xl"
    >
      {/* Logo */}
      <div className="px-6 py-6 mb-2">
        <h1 className="text-white text-xl font-bold tracking-tight">Sahali</h1>
        <p className="text-[#3f465c] text-xs mt-1">Municipalité de La Marsa</p>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto px-2 space-y-0.5">
        {NAV_ITEMS.map(({ path, icon, label }) => {
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
              <span>{label}</span>
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
          <span>Paramètres</span>
        </NavLink>

        {/* Municipality badge */}
        <div className="flex items-center gap-3 px-4 py-3 mt-2">
          <div className="w-9 h-9 rounded-lg bg-[#0038AF] flex items-center justify-center flex-shrink-0">
            <span className="material-symbols-outlined text-white" style={{ fontSize: 18 }}>location_city</span>
          </div>
          <div>
            <p className="text-white text-xs font-semibold">La Marsa</p>
            <p className="text-[#3f465c] text-[10px]">Administration</p>
          </div>
        </div>
      </div>
    </aside>
  )
}
