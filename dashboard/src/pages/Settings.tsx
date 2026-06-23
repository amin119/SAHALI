import { useState } from 'react'
import { useAuth } from '../context/AuthContext'

const SECTIONS = ['Mon profil', 'Notifications', 'Seuils SLA', 'Sécurité', 'Intégrations']

const ROLE_LABELS: Record<string, string> = {
  admin: 'Administrateur', supervisor: 'Superviseur',
  analyst: 'Analyste', field_agent: 'Agent terrain', citizen: 'Citoyen',
}

export default function Settings() {
  const { user } = useAuth()
  const [activeSection, setActiveSection] = useState('Mon profil')
  const [smsEnabled, setSmsEnabled] = useState(true)
  const [pushEnabled, setPushEnabled] = useState(true)
  const [emailEnabled, setEmailEnabled] = useState(false)
  const [slaAlert, setSlaAlert] = useState(true)

  function initials(name: string) {
    return name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
  }

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-[#0F172A] text-2xl font-bold">Paramètres</h2>
        <p className="text-[#64748B] text-sm mt-1">Configuration de votre compte et de la plateforme.</p>
      </div>

      <div className="flex gap-6">
        {/* Sidebar nav */}
        <div className="w-56 flex-shrink-0">
          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
            {SECTIONS.map(s => (
              <button key={s} onClick={() => setActiveSection(s)}
                className={`w-full text-left px-4 py-3 text-sm font-medium transition-colors border-b border-[#E2E8F0] last:border-b-0
                  ${activeSection === s
                    ? 'bg-[#0038AF]/5 text-[#0038AF] border-l-2 border-l-[#0038AF]'
                    : 'text-[#64748B] hover:bg-[#f7f9fe] hover:text-[#181c20]'}`}>
                {s}
              </button>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 space-y-5">
          {activeSection === 'Mon profil' && (
            <>
              <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
                <h4 className="text-[#181c20] font-semibold text-base mb-5">Informations personnelles</h4>
                <div className="flex items-center gap-5 mb-6 pb-6 border-b border-[#E2E8F0]">
                  <div className="w-16 h-16 rounded-full bg-[#0038AF] flex items-center justify-center text-white text-2xl font-bold">
                    {user ? initials(user.full_name) : '…'}
                  </div>
                  <div>
                    <p className="text-base font-bold text-[#181c20]">{user?.full_name ?? '—'}</p>
                    <p className="text-sm text-[#64748B]">{ROLE_LABELS[user?.role ?? ''] ?? user?.role ?? '—'}</p>
                    <span className={`inline-block mt-1 text-xs px-2 py-0.5 rounded-full font-medium
                      ${user?.is_active ? 'bg-[#22C55E18] text-[#22C55E]' : 'bg-red-50 text-red-400'}`}>
                      {user?.is_active ? 'Actif' : 'Inactif'}
                    </span>
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">Nom complet</label>
                    <input defaultValue={user?.full_name ?? ''}
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">Adresse e-mail</label>
                    <input defaultValue={user?.email ?? ''} type="email"
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">Téléphone</label>
                    <input defaultValue={user?.phone ?? ''} type="tel"
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">Langue préférée</label>
                    <select defaultValue={user?.preferred_language ?? 'fr'}
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                      <option value="fr">Français</option>
                      <option value="ar">العربية</option>
                      <option value="en">English</option>
                    </select>
                  </div>
                </div>
                <div className="mt-4 pt-4 border-t border-[#E2E8F0]">
                  <p className="text-xs text-[#94A3B8]">
                    Membre depuis {user ? new Date(user.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' }) : '—'}
                  </p>
                </div>
              </div>
            </>
          )}

          {activeSection === 'Notifications' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
              <h4 className="text-[#181c20] font-semibold text-base mb-5">Canaux de notification</h4>
              <div className="space-y-4">
                {[
                  { label: 'Notifications push', desc: 'Via Firebase Cloud Messaging (FCM)', val: pushEnabled, set: setPushEnabled },
                  { label: 'SMS', desc: 'Via Twilio ou opérateur local tunisien', val: smsEnabled, set: setSmsEnabled },
                  { label: 'Email', desc: 'Via SendGrid ou SMTP', val: emailEnabled, set: setEmailEnabled },
                  { label: 'Alertes SLA', desc: 'Notification si délai SLA dépassé', val: slaAlert, set: setSlaAlert },
                ].map(n => (
                  <div key={n.label} className="flex items-center justify-between p-4 rounded-xl bg-[#f7f9fe] border border-[#E2E8F0]">
                    <div>
                      <p className="text-sm font-semibold text-[#181c20]">{n.label}</p>
                      <p className="text-xs text-[#94A3B8] mt-0.5">{n.desc}</p>
                    </div>
                    <button onClick={() => n.set(!n.val)}
                      className="w-11 h-6 rounded-full relative transition-colors"
                      style={{ backgroundColor: n.val ? '#0038AF' : '#E2E8F0' }}>
                      <span className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-all ${n.val ? 'left-6' : 'left-1'}`} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeSection === 'Seuils SLA' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
              <h4 className="text-[#181c20] font-semibold text-base mb-2">Configuration des SLA</h4>
              <p className="text-[#94A3B8] text-sm mb-5">Délais cibles de résolution par catégorie de signalement.</p>
              <div className="space-y-4">
                {[
                  { cat: 'Sécurité & Urgences', sla: 24, color: '#EF4444' },
                  { cat: 'Eau & Assainissement', sla: 48, color: '#0EA5E9' },
                  { cat: 'Éclairage public', sla: 72, color: '#F59E0B' },
                  { cat: 'Infrastructure routière', sla: 168, color: '#0038AF' },
                  { cat: 'Déchets & Propreté', sla: 168, color: '#22C55E' },
                  { cat: 'Environnement', sla: 336, color: '#10B981' },
                ].map(s => (
                  <div key={s.cat} className="flex items-center gap-4 p-3 rounded-xl bg-[#f7f9fe] border border-[#E2E8F0]">
                    <span className="w-3 h-3 rounded-full flex-shrink-0" style={{ backgroundColor: s.color }} />
                    <span className="text-sm font-medium text-[#181c20] flex-1">{s.cat}</span>
                    <div className="flex items-center gap-2">
                      <input type="number" defaultValue={s.sla}
                        className="w-20 bg-white border border-[#E2E8F0] rounded-lg px-3 py-1.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 text-center" />
                      <span className="text-xs text-[#64748B]">heures</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {!['Mon profil', 'Notifications', 'Seuils SLA'].includes(activeSection) && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-8 text-center">
              <span className="material-symbols-outlined text-[#94A3B8] mb-3 block" style={{ fontSize: 40 }}>construction</span>
              <p className="text-[#64748B] text-sm">Section "{activeSection}" — en cours de développement</p>
            </div>
          )}

          <div className="flex justify-end gap-3">
            <button className="px-6 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe]">
              Annuler
            </button>
            <button className="px-6 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-medium shadow-md hover:opacity-90 transition-opacity">
              Enregistrer les modifications
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
