import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from './Sidebar'
import TopBar from './TopBar'
import { useAuth } from '../../context/AuthContext'
import { useLang, type TranslationKey } from '../../context/LangContext'

type SubtitleKey = TranslationKey | null

const SUBTITLE_KEYS: Record<string, SubtitleKey> = {
  '/map':            'sub_map',
  '/reports':        'sub_reports',
  '/interventions':  'sub_interventions',
  '/calendar':       'sub_calendar',
  '/teams':          'sub_teams',
  '/municipalities': 'sub_municipalities',
  '/categories':     'sub_categories',
  '/statistics':     'sub_statistics',
  '/settings':       'sub_settings',
}

const TITLE_KEYS: Record<string, TranslationKey> = {
  '/dashboard':      'nav_dashboard',
  '/map':            'nav_map',
  '/reports':        'nav_reports',
  '/interventions':  'nav_interventions',
  '/calendar':       'nav_calendar',
  '/teams':          'nav_teams',
  '/municipalities': 'nav_municipalities',
  '/categories':     'nav_categories',
  '/statistics':     'nav_statistics',
  '/settings':       'nav_settings',
}

export default function Layout() {
  const location = useLocation()
  const { user } = useAuth()
  const { t, lang } = useLang()
  const firstName = user?.full_name.split(' ')[0] ?? ''

  const titleKey = TITLE_KEYS[location.pathname]
  const title = titleKey ? t(titleKey) : 'Sahali'

  const subtitleKey = SUBTITLE_KEYS[location.pathname]
  let subtitle: string | undefined
  if (location.pathname === '/dashboard') {
    subtitle = lang === 'ar'
      ? `مرحباً، ${firstName} — نظرة عامة على البلدية`
      : `Bienvenue, ${firstName} — vue d'ensemble de la municipalité`
  } else if (subtitleKey) {
    subtitle = t(subtitleKey)
  }

  return (
    <div className="flex min-h-screen" style={{ backgroundColor: '#f7f9fe' }}>
      <Sidebar />
      <div style={{ marginLeft: 260, flex: 1, minWidth: 0 }}>
        <TopBar title={title} subtitle={subtitle} />
        <main className="p-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
