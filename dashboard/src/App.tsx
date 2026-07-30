import { Suspense, lazy } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import PrivateRoute from './components/PrivateRoute'
import Layout from './components/layout/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Reports from './pages/Reports'
import ReportDetail from './pages/ReportDetail'
import Interventions from './pages/Interventions'
import Calendar from './pages/Calendar'
import Teams from './pages/Teams'
import Municipalities from './pages/Municipalities'
import Categories from './pages/Categories'
import Statistics from './pages/Statistics'
import Settings from './pages/Settings'

// Leaflet (map tiles + its CSS) is the single heaviest dependency in the
// dashboard — lazy-loading it means every other page's users stop paying to
// download and parse it, and it only comes down when someone actually opens the map.
const Map = lazy(() => import('./pages/Map'))

function PageFallback() {
  return (
    <div className="flex items-center justify-center h-64">
      <div className="w-8 h-8 border-2 border-[#E2E8F0] border-t-[#0038AF] rounded-full animate-spin" />
    </div>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={
              <PrivateRoute>
                <Layout />
              </PrivateRoute>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="map" element={<Suspense fallback={<PageFallback />}><Map /></Suspense>} />
            <Route path="reports" element={<Reports />} />
            <Route path="reports/:id" element={<ReportDetail />} />
            <Route path="interventions" element={<Interventions />} />
            <Route path="calendar" element={<Calendar />} />
            <Route path="teams" element={<Teams />} />
            <Route path="municipalities" element={<Municipalities />} />
            <Route path="categories" element={<Categories />} />
            <Route path="statistics" element={<Statistics />} />
            <Route path="settings" element={<Settings />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
