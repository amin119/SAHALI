import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from './Sidebar'
import TopBar from './TopBar'
import { useAuth } from '../../context/AuthContext'

const PAGE_TITLES: Record<string, { title: string; subtitle?: (name: string) => string }> = {
  '/dashboard': {
    title: 'Tableau de bord',
    subtitle: name => `Bienvenue, ${name} 👋 Voici l'état de la municipalité aujourd'hui.`,
  },
  '/map': { title: 'Carte en direct', subtitle: () => 'Visualisation en temps réel des signalements actifs.' },
  '/reports': { title: 'Signalements', subtitle: () => 'Gestion et suivi de tous les signalements citoyens.' },
  '/interventions': { title: 'Interventions', subtitle: () => 'Gestion et planification des équipes de terrain.' },
  '/calendar': { title: 'Calendrier', subtitle: () => 'Planning des interventions programmées.' },
  '/teams': { title: 'Équipes & Agents', subtitle: () => 'Gestion des agents et équipes municipales.' },
  '/municipalities': { title: 'Municipalités', subtitle: () => "Vue d'ensemble des municipalités partenaires." },
  '/categories': { title: 'Catégories', subtitle: () => 'Configuration des catégories de signalements.' },
  '/statistics': { title: 'Statistiques & Rapports', subtitle: () => 'Analyse des performances et indicateurs clés.' },
  '/settings': { title: 'Paramètres', subtitle: () => 'Configuration de la plateforme municipale.' },
}

export default function Layout() {
  const location = useLocation()
  const { user } = useAuth()
  const firstName = user?.full_name.split(' ')[0] ?? ''
  const entry = PAGE_TITLES[location.pathname] ?? { title: 'Sahali' }
  const subtitle = entry.subtitle?.(firstName)

  return (
    <div className="flex min-h-screen" style={{ backgroundColor: '#f7f9fe' }}>
      <Sidebar />
      <div style={{ marginLeft: 260, flex: 1, minWidth: 0 }}>
        <TopBar title={entry.title} subtitle={subtitle} />
        <main className="p-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
