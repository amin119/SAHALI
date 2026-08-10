import { useState } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import Sidebar from './Sidebar'
import TopBar from './TopBar'
import { useAuth } from '../../context/AuthContext'
import { useLang, type TranslationKey } from '../../context/LangContext'

const ONBOARDING_SEEN_KEY = 'sahali_onboarding_seen_v1'

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
  '/help':           'sub_help',
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
  '/help':           'nav_help',
}

export default function Layout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { t, lang } = useLang()
  const firstName = user?.full_name.split(' ')[0] ?? ''
  const [navOpen, setNavOpen] = useState(false)
  const [showWelcome, setShowWelcome] = useState(
    () => typeof localStorage !== 'undefined' && !localStorage.getItem(ONBOARDING_SEEN_KEY)
  )

  function dismissWelcome() {
    localStorage.setItem(ONBOARDING_SEEN_KEY, '1')
    setShowWelcome(false)
  }

  function openHelp() {
    dismissWelcome()
    navigate('/help')
  }

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
      <Sidebar open={navOpen} onClose={() => setNavOpen(false)} />
      <div className="flex-1 min-w-0 lg:ml-[260px]">
        <TopBar title={title} subtitle={subtitle} onMenuClick={() => setNavOpen(true)} />
        <main className="p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>

      {showWelcome && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 text-center">
            <div className="w-14 h-14 bg-[#0038AF] rounded-2xl flex items-center justify-center mx-auto mb-4">
              <span className="material-symbols-outlined text-white" style={{ fontSize: 28 }}>waving_hand</span>
            </div>
            <h3 className="text-[#181c20] font-bold text-lg mb-2">
              {lang === 'ar' ? `مرحباً${firstName ? '، ' + firstName : ''}` : `Bienvenue${firstName ? ', ' + firstName : ''}`}
            </h3>
            <p className="text-sm text-[#64748B] mb-6">
              {lang === 'ar'
                ? 'قبل أن تبدأ، يمكنك الاطلاع بسرعة على ما تفعله كل صفحة في هذه المنصة.'
                : 'Avant de commencer, jetez un œil rapide à ce que fait chaque page de la plateforme.'}
            </p>
            <div className="flex gap-2">
              <button onClick={dismissWelcome}
                className="flex-1 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe] transition-colors">
                {lang === 'ar' ? 'لاحقاً' : 'Plus tard'}
              </button>
              <button onClick={openHelp}
                className="flex-1 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity">
                {lang === 'ar' ? 'اكتشف المنصة' : 'Découvrir la plateforme'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
