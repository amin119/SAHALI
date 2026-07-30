import { useEffect } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

// Citizens and field agents do their work in the mobile app — the web
// dashboard has nothing for them, so they never get past this gate.
const DASHBOARD_ROLES = ['admin', 'analyst']

export default function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth()
  const authorized = user != null && DASHBOARD_ROLES.includes(user.role)

  useEffect(() => {
    if (user && !authorized) logout()
  }, [user, authorized, logout])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#f7f9fe' }}>
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-[#0038AF] border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-[#64748B]">Chargement...</span>
        </div>
      </div>
    )
  }

  if (!user) return <Navigate to="/login" replace />
  if (!authorized) return <Navigate to="/login?blocked=1" replace />
  return <>{children}</>
}
