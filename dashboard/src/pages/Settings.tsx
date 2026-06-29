import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { useLang } from '../context/LangContext'

type SectionKey = 'profile' | 'notifications' | 'sla' | 'security' | 'integrations'

export default function Settings() {
  const { user } = useAuth()
  const { t, locale } = useLang()
  const [activeSection, setActiveSection] = useState<SectionKey>('profile')
  const [smsEnabled, setSmsEnabled] = useState(true)
  const [pushEnabled, setPushEnabled] = useState(true)
  const [emailEnabled, setEmailEnabled] = useState(false)
  const [slaAlert, setSlaAlert] = useState(true)

  const sections: { key: SectionKey; label: string }[] = [
    { key: 'profile',       label: t('section_profile') },
    { key: 'notifications', label: t('section_notif') },
    { key: 'sla',           label: t('section_sla') },
    { key: 'security',      label: t('section_security') },
    { key: 'integrations',  label: t('section_integ') },
  ]

  const roleLabel = user ? t(
    user.role === 'admin' ? 'role_admin' :
    user.role === 'supervisor' ? 'role_supervisor' :
    user.role === 'analyst' ? 'role_analyst' :
    user.role === 'field_agent' ? 'role_field_agent' :
    user.role === 'citizen' ? 'role_citizen' : 'role_field_agent'
  ) : '—'

  function initials(name: string) {
    return name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
  }

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_settings')}</h2>
        <p className="text-[#64748B] text-sm mt-1">{t('settings_sub')}</p>
      </div>

      <div className="flex gap-6">
        {/* Sidebar nav */}
        <div className="w-56 flex-shrink-0">
          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
            {sections.map(s => (
              <button key={s.key} onClick={() => setActiveSection(s.key)}
                className={`w-full text-left px-4 py-3 text-sm font-medium transition-colors border-b border-[#E2E8F0] last:border-b-0
                  ${activeSection === s.key
                    ? 'bg-[#0038AF]/5 text-[#0038AF] border-l-2 border-l-[#0038AF]'
                    : 'text-[#64748B] hover:bg-[#f7f9fe] hover:text-[#181c20]'}`}>
                {s.label}
              </button>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 space-y-5">
          {activeSection === 'profile' && (
            <>
              <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
                <h4 className="text-[#181c20] font-semibold text-base mb-5">{t('personal_info')}</h4>
                <div className="flex items-center gap-5 mb-6 pb-6 border-b border-[#E2E8F0]">
                  <div className="w-16 h-16 rounded-full bg-[#0038AF] flex items-center justify-center text-white text-2xl font-bold">
                    {user ? initials(user.full_name) : '…'}
                  </div>
                  <div>
                    <p className="text-base font-bold text-[#181c20]">{user?.full_name ?? '—'}</p>
                    <p className="text-sm text-[#64748B]">{roleLabel}</p>
                    <span className={`inline-block mt-1 text-xs px-2 py-0.5 rounded-full font-medium
                      ${user?.is_active ? 'bg-[#22C55E18] text-[#22C55E]' : 'bg-red-50 text-red-400'}`}>
                      {user?.is_active ? t('agent_active') : t('agent_inactive')}
                    </span>
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_full_name_s')}</label>
                    <input defaultValue={user?.full_name ?? ''}
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_email_s')}</label>
                    <input defaultValue={user?.email ?? ''} type="email"
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_phone_s')}</label>
                    <input defaultValue={user?.phone ?? ''} type="tel"
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_pref_lang')}</label>
                    <select defaultValue={user?.preferred_language ?? 'fr'}
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]">
                      <option value="fr">{t('lang_fr')}</option>
                      <option value="ar">{t('lang_ar')}</option>
                      <option value="en">English</option>
                    </select>
                  </div>
                </div>
                <div className="mt-4 pt-4 border-t border-[#E2E8F0]">
                  <p className="text-xs text-[#94A3B8]">
                    {t('member_since_s')} {user ? new Date(user.created_at).toLocaleDateString(locale, { day: '2-digit', month: 'long', year: 'numeric' }) : '—'}
                  </p>
                </div>
              </div>
            </>
          )}

          {activeSection === 'notifications' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
              <h4 className="text-[#181c20] font-semibold text-base mb-5">{t('notif_channels')}</h4>
              <div className="space-y-4">
                {[
                  { label: t('notif_push_lbl'), desc: t('notif_push_desc'), val: pushEnabled, set: setPushEnabled },
                  { label: t('notif_sms_lbl'),  desc: t('notif_sms_desc'),  val: smsEnabled,  set: setSmsEnabled },
                  { label: t('notif_email_lbl'),desc: t('notif_email_desc'),val: emailEnabled, set: setEmailEnabled },
                  { label: t('notif_sla_lbl'),  desc: t('notif_sla_desc'),  val: slaAlert,    set: setSlaAlert },
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

          {activeSection === 'sla' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
              <h4 className="text-[#181c20] font-semibold text-base mb-2">{t('sla_config_title')}</h4>
              <p className="text-[#94A3B8] text-sm mb-5">{t('sla_config_desc')}</p>
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
                      <span className="text-xs text-[#64748B]">{t('sla_hours')}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeSection !== 'profile' && activeSection !== 'notifications' && activeSection !== 'sla' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-8 text-center">
              <span className="material-symbols-outlined text-[#94A3B8] mb-3 block" style={{ fontSize: 40 }}>construction</span>
              <p className="text-[#64748B] text-sm">
                {sections.find(s => s.key === activeSection)?.label} — {t('under_dev')}
              </p>
            </div>
          )}

          <div className="flex justify-end gap-3">
            <button className="px-6 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe]">
              {t('btn_cancel_s')}
            </button>
            <button className="px-6 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-medium shadow-md hover:opacity-90 transition-opacity">
              {t('btn_save_s')}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
