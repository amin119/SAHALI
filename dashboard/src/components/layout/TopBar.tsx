import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'
import { api } from '../../lib/api'
import type { Notification } from '../../types/api'
import { useReportEvents } from '../../hooks/useReportEvents'
import { useLang } from '../../context/LangContext'

interface TopBarProps {
  title: string
  subtitle?: string
}

export default function TopBar({ title, subtitle }: TopBarProps) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const { t } = useLang()
  const [search, setSearch] = useState('')
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [showNotifs, setShowNotifs] = useState(false)

  const fetchNotifications = useCallback(() => {
    api.get<Notification[]>('/notifications')
      .then(setNotifications)
      .catch(() => {})
  }, [])

  useEffect(() => { fetchNotifications() }, [fetchNotifications])

  useReportEvents(fetchNotifications)

  const unreadCount = notifications.filter(n => !n.is_read).length

  const initials = user?.full_name
    .split(' ')
    .map(w => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase() ?? '??'

  const roleLabel = user ? t(
    user.role === 'admin' ? 'role_admin' :
    user.role === 'supervisor' ? 'role_supervisor' :
    user.role === 'analyst' ? 'role_analyst' :
    user.role === 'field_agent' ? 'role_field_agent' :
    user.role === 'citizen' ? 'role_citizen' : 'role_field_agent'
  ) : ''

  async function handleNotifClick(n: Notification) {
    await api.patch(`/notifications/${n.id}/read`).catch(() => {})
    setNotifications(prev => prev.map(x => x.id === n.id ? { ...x, is_read: true } : x))
    setShowNotifs(false)
    if (n.report_id) {
      navigate(`/reports?report=${n.report_id}`)
    }
  }

  return (
    <header
      className="sticky top-0 z-40 flex items-center justify-between px-8 bg-white border-b border-[#E2E8F0]"
      style={{ height: 64, marginLeft: 260 }}
    >
      {/* Left: search */}
      <div className="flex items-center gap-6">
        <div className="relative w-80">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#747686]" style={{ fontSize: 18 }}>search</span>
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            type="text"
            placeholder={t('topbar_search')}
            className="w-full bg-[#f1f4f9] border-0 rounded-lg pl-9 pr-4 py-2 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20"
          />
        </div>
        {(title || subtitle) && (
          <div className="hidden xl:block">
            <h2 className="text-[#0F172A] font-bold text-base leading-none">{title}</h2>
            {subtitle && <p className="text-[#64748B] text-xs mt-0.5">{subtitle}</p>}
          </div>
        )}
      </div>

      {/* Right: actions + user */}
      <div className="flex items-center gap-2">
        <button className="w-9 h-9 flex items-center justify-center rounded-full hover:bg-[#f1f4f9] transition-colors">
          <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>language</span>
        </button>

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => setShowNotifs(v => !v)}
            className="w-9 h-9 flex items-center justify-center rounded-full hover:bg-[#f1f4f9] transition-colors relative"
          >
            <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>notifications</span>
            {unreadCount > 0 && (
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-[#ba1a1a] rounded-full border-2 border-white" />
            )}
          </button>

          {showNotifs && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowNotifs(false)} />
              <div className="absolute right-0 top-11 w-80 bg-white rounded-xl shadow-lg border border-[#E2E8F0] z-50 overflow-hidden">
                <div className="px-4 py-3 border-b border-[#E2E8F0] flex items-center justify-between">
                  <span className="font-semibold text-sm text-[#0F172A]">{t('notif_title')}</span>
                  {unreadCount > 0 && (
                    <span className="text-xs bg-[#0038AF] text-white px-2 py-0.5 rounded-full">{unreadCount}</span>
                  )}
                </div>
                <div className="max-h-72 overflow-y-auto divide-y divide-[#E2E8F0]">
                  {notifications.length === 0 ? (
                    <p className="text-sm text-[#94A3B8] text-center py-6">{t('notif_empty')}</p>
                  ) : (
                    notifications.slice(0, 10).map(n => (
                      <button
                        key={n.id}
                        onClick={() => handleNotifClick(n)}
                        className={`w-full text-left px-4 py-3 hover:bg-[#f7f9fe] transition-colors ${!n.is_read ? 'bg-[#f0f4ff]' : ''}`}
                      >
                        <div className="flex items-start gap-2">
                          <span className="material-symbols-outlined text-[#0038AF] flex-shrink-0 mt-0.5" style={{ fontSize: 14 }}>
                            {n.report_id ? 'flag' : 'notifications'}
                          </span>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-[#0F172A] truncate">{n.title}</p>
                            <p className="text-xs text-[#64748B] mt-0.5 line-clamp-2">{n.body}</p>
                            {n.report_id && (
                              <p className="text-[10px] text-[#0038AF] mt-1 font-medium">{t('notif_view')}</p>
                            )}
                          </div>
                        </div>
                      </button>
                    ))
                  )}
                </div>
              </div>
            </>
          )}
        </div>

        <button className="w-9 h-9 flex items-center justify-center rounded-full hover:bg-[#f1f4f9] transition-colors">
          <span className="material-symbols-outlined text-[#64748B]" style={{ fontSize: 20 }}>help</span>
        </button>

        {/* User + logout */}
        <div className="flex items-center gap-3 pl-4 border-l border-[#E2E8F0]">
          <div className="text-right">
            <p className="text-[#181c20] text-sm font-bold leading-none">{user?.full_name ?? '—'}</p>
            <p className="text-[#64748B] text-[10px] uppercase tracking-wider mt-0.5">{roleLabel}</p>
          </div>
          <div className="w-9 h-9 rounded-full bg-[#0038AF] flex items-center justify-center text-white text-sm font-bold border-2 border-[#b6c4ff]">
            {initials}
          </div>
          <button
            onClick={logout}
            title={t('btn_logout')}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-red-50 transition-colors"
          >
            <span className="material-symbols-outlined text-[#94A3B8] hover:text-red-400" style={{ fontSize: 18 }}>logout</span>
          </button>
        </div>
      </div>
    </header>
  )
}
