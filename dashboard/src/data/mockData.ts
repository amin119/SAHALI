export type ReportStatus = 'submitted' | 'received' | 'under_review' | 'in_progress' | 'resolved' | 'rejected';
export type Priority = 'critical' | 'high' | 'medium' | 'low';

export interface Report {
  id: string;
  code: string;
  category: string;
  address: string;
  city: string;
  status: ReportStatus;
  priority: Priority;
  assignedTo?: string;
  createdAt: string;
  description?: string;
}

export interface Agent {
  id: string;
  name: string;
  role: string;
  avatar: string;
  status: 'active' | 'on_leave' | 'busy';
  assigned: number;
  resolved: number;
  inProgress: number;
  performance: number;
  location: string;
}

export const REPORTS: Report[] = [
  { id: '1', code: 'CA-2026-88412', category: 'Déchets', address: 'Av. Habib Thameur', city: 'La Marsa', status: 'in_progress', priority: 'high', assignedTo: 'Sami Mejri', createdAt: 'Il y a 2h', description: 'Accumulation de déchets devant le centre commercial.' },
  { id: '2', code: 'CA-2026-88390', category: 'Éclairage', address: 'Ariana Center, Rue 12', city: 'Ariana', status: 'resolved', priority: 'medium', assignedTo: 'Hana Trabelsi', createdAt: 'Il y a 5h', description: 'Lampadaire défaillant — risque sécurité la nuit.' },
  { id: '3', code: 'CA-2026-88355', category: 'Sécurité', address: 'La Marsa Plage', city: 'La Marsa', status: 'received', priority: 'critical', assignedTo: undefined, createdAt: "Aujourd'hui", description: 'Balustrade effondrée sur la promenade.' },
  { id: '4', code: 'CA-2026-88321', category: 'Eau', address: 'Carthage Salambo', city: 'Carthage', status: 'received', priority: 'high', assignedTo: 'Kais Dhouib', createdAt: 'Hier', description: 'Fuite d\'eau importante sur la voirie.' },
  { id: '5', code: 'CA-2026-88300', category: 'Routes', address: 'Rue de la République', city: 'Ariana', status: 'in_progress', priority: 'medium', assignedTo: 'Meriem Gara', createdAt: 'Il y a 2j', description: 'Nid de poule profond ralentissant la circulation.' },
  { id: '6', code: 'CA-2026-88289', category: 'Environnement', address: 'Parc Saada', city: 'La Marsa', status: 'under_review', priority: 'low', assignedTo: 'Sami Mejri', createdAt: 'Il y a 3j', description: 'Arbres non taillés obstruant les trottoirs.' },
  { id: '7', code: 'CA-2026-88260', category: 'Transport', address: 'Arrêt Bus 78', city: 'Carthage', status: 'resolved', priority: 'low', assignedTo: 'Hana Trabelsi', createdAt: 'Il y a 4j', description: 'Abri bus vandalisé, vitre brisée.' },
  { id: '8', code: 'CA-2026-88244', category: 'Routes', address: 'Av. Bourguiba Goulette', city: 'La Goulette', status: 'resolved', priority: 'medium', assignedTo: 'Kais Dhouib', createdAt: 'Il y a 5j', description: 'Marquage au sol effacé à l\'intersection.' },
];

export const AGENTS: Agent[] = [
  { id: '1', name: 'Sami Mejri', role: 'Agent terrain', avatar: 'SM', status: 'active', assigned: 12, resolved: 8, inProgress: 4, performance: 94, location: 'La Marsa' },
  { id: '2', name: 'Hana Trabelsi', role: 'Superviseure', avatar: 'HT', status: 'active', assigned: 18, resolved: 14, inProgress: 4, performance: 88, location: 'Ariana' },
  { id: '3', name: 'Kais Dhouib', role: 'Agent terrain', avatar: 'KD', status: 'busy', assigned: 9, resolved: 6, inProgress: 3, performance: 82, location: 'Carthage' },
  { id: '4', name: 'Meriem Gara', role: 'Analyste', avatar: 'MG', status: 'active', assigned: 7, resolved: 5, inProgress: 2, performance: 75, location: 'La Marsa' },
  { id: '5', name: 'Youssef Ben Salem', role: 'Agent terrain', avatar: 'YB', status: 'on_leave', assigned: 0, resolved: 22, inProgress: 0, performance: 91, location: 'Sidi Bou Saïd' },
  { id: '6', name: 'Fatma Karoui', role: 'Agent terrain', avatar: 'FK', status: 'active', assigned: 5, resolved: 3, inProgress: 2, performance: 78, location: 'La Goulette' },
];

export const STATUS_LABELS: Record<ReportStatus, string> = {
  submitted:    'Soumis',
  received:     'Reçu',
  under_review: 'En examen',
  in_progress:  'En cours',
  resolved:     'Résolu',
  rejected:     'Rejeté',
};

export const STATUS_COLORS: Record<ReportStatus, string> = {
  submitted:    '#6366F1',
  received:     '#0EA5E9',
  under_review: '#F59E0B',
  in_progress:  '#F97316',
  resolved:     '#22C55E',
  rejected:     '#EF4444',
};

export const PRIORITY_COLORS: Record<Priority, string> = {
  critical: '#EF4444',
  high: '#F97316',
  medium: '#F59E0B',
  low: '#22C55E',
};

export const PRIORITY_LABELS: Record<Priority, string> = {
  critical: 'Critique',
  high: 'Haute',
  medium: 'Moyenne',
  low: 'Basse',
};

export const CATEGORIES = [
  { id: 1, slug: 'roads', label: 'Infrastructure routière', icon: 'road', color: '#0038AF', count: 342, sla: 168, enabled: true },
  { id: 2, slug: 'lighting', label: 'Éclairage public', icon: 'light', color: '#F59E0B', count: 198, sla: 72, enabled: true },
  { id: 3, slug: 'waste', label: 'Déchets & Propreté', icon: 'delete', color: '#22C55E', count: 280, sla: 168, enabled: true },
  { id: 4, slug: 'water', label: 'Eau & Assainissement', icon: 'water_drop', color: '#0EA5E9', count: 156, sla: 48, enabled: true },
  { id: 5, slug: 'safety', label: 'Sécurité publique', icon: 'security', color: '#EF4444', count: 145, sla: 24, enabled: true },
  { id: 6, slug: 'environment', label: 'Environnement', icon: 'park', color: '#10B981', count: 89, sla: 336, enabled: true },
  { id: 7, slug: 'transport', label: 'Transport', icon: 'directions_bus', color: '#8B5CF6', count: 74, sla: 168, enabled: false },
];

export const MUNICIPALITIES = [
  { id: 1, name: 'La Marsa', reports: 382, resolved: 341, rate: 89, tier: 'Premium', agents: 12 },
  { id: 2, name: 'Ariana', reports: 297, resolved: 256, rate: 86, tier: 'Standard', agents: 8 },
  { id: 3, name: 'Carthage', reports: 211, resolved: 189, rate: 90, tier: 'Premium', agents: 6 },
  { id: 4, name: 'Sidi Bou Saïd', reports: 156, resolved: 148, rate: 95, tier: 'Standard', agents: 4 },
  { id: 5, name: 'La Goulette', reports: 138, resolved: 118, rate: 85, tier: 'Basic', agents: 4 },
  { id: 6, name: 'Le Bardo', reports: 100, resolved: 82, rate: 82, tier: 'Basic', agents: 3 },
];

export const WEEKLY_DATA = [
  { day: 'Lun', submitted: 52, resolved: 38, pending: 14 },
  { day: 'Mar', submitted: 45, resolved: 32, pending: 13 },
  { day: 'Mer', submitted: 63, resolved: 54, pending: 9 },
  { day: 'Jeu', submitted: 58, resolved: 45, pending: 13 },
  { day: 'Ven', submitted: 71, resolved: 62, pending: 9 },
  { day: 'Sam', submitted: 34, resolved: 28, pending: 6 },
  { day: 'Dim', submitted: 22, resolved: 18, pending: 4 },
];
