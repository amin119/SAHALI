import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import PrivateRoute from './components/PrivateRoute'
import Layout from './components/layout/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Reports from './pages/Reports'
import Interventions from './pages/Interventions'
import Calendar from './pages/Calendar'
import Map from './pages/Map'
import Teams from './pages/Teams'
import Municipalities from './pages/Municipalities'
import Categories from './pages/Categories'
import Statistics from './pages/Statistics'
import Settings from './pages/Settings'

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
            <Route path="map" element={<Map />} />
            <Route path="reports" element={<Reports />} />
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
