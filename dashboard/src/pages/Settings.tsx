import { useState, useEffect } from 'react'
import { api } from '../lib/api'
import { useAuth } from '../context/AuthContext'
import { useLang } from '../context/LangContext'
import type { Category } from '../types/api'

type SectionKey = 'profile' | 'notifications' | 'sla' | 'security' | 'integrations'

const NOTIF_PREFS_KEY = 'sahali_notif_prefs'

interface NotifPrefs {
  push: boolean
  sms: boolean
  email: boolean
  slaAlert: boolean
}

const DEFAULT_NOTIF_PREFS: NotifPrefs = { push: true, sms: true, email: false, slaAlert: true }

function loadNotifPrefs(): NotifPrefs {
  try {
    const raw = localStorage.getItem(NOTIF_PREFS_KEY)
    if (!raw) return DEFAULT_NOTIF_PREFS
    return { ...DEFAULT_NOTIF_PREFS, ...JSON.parse(raw) }
  } catch {
    return DEFAULT_NOTIF_PREFS
  }
}

export default function Settings() {
  const { user, refreshUser } = useAuth()
  const { t, lang, locale } = useLang()
  const [activeSection, setActiveSection] = useState<SectionKey>('profile')
  const [toast, setToast] = useState<{ kind: 'ok' | 'err'; text: string } | null>(null)

  // ── Profile ──────────────────────────────────────────────────────────────
  const [profileForm, setProfileForm] = useState({ full_name: '', preferred_language: 'fr' })
  const [savingProfile, setSavingProfile] = useState(false)

  useEffect(() => {
    if (user) setProfileForm({ full_name: user.full_name, preferred_language: user.preferred_language })
  }, [user])

  async function saveProfile() {
    setSavingProfile(true)
    setToast(null)
    try {
      await api.patch('/users/me', {
        full_name: profileForm.full_name.trim(),
        preferred_language: profileForm.preferred_language,
      })
      await refreshUser()
      setToast({ kind: 'ok', text: t('saved_successfully') })
    } catch (e: unknown) {
      setToast({ kind: 'err', text: e instanceof Error ? e.message : t('save_failed') })
    } finally {
      setSavingProfile(false)
    }
  }

  // ── Notifications (persisted locally — no backend column for this yet) ──
  const [notifPrefs, setNotifPrefs] = useState<NotifPrefs>(loadNotifPrefs)

  function toggleNotifPref(key: keyof NotifPrefs) {
    setNotifPrefs(prev => {
      const next = { ...prev, [key]: !prev[key] }
      localStorage.setItem(NOTIF_PREFS_KEY, JSON.stringify(next))
      return next
    })
  }

  // ── SLA thresholds (real categories, real backend field) ────────────────
  const [categories, setCategories] = useState<Category[]>([])
  const [slaEdits, setSlaEdits] = useState<Record<number, string>>({})
  const [savingSla, setSavingSla] = useState(false)
  const [loadingCategories, setLoadingCategories] = useState(false)

  useEffect(() => {
    if (activeSection !== 'sla' || categories.length > 0) return
    setLoadingCategories(true)
    api.get<Category[]>('/categories/all')
      .then(cats => {
        setCategories(cats)
        const edits: Record<number, string> = {}
        cats.forEach(c => { edits[c.id] = String(c.sla_hours ?? '') })
        setSlaEdits(edits)
      })
      .catch(() => {})
      .finally(() => setLoadingCategories(false))
  }, [activeSection, categories.length])

  async function saveSla() {
    setSavingSla(true)
    setToast(null)
    try {
      const changed = categories.filter(c => String(c.sla_hours ?? '') !== slaEdits[c.id])
      await Promise.all(changed.map(c =>
        api.patch(`/categories/${c.id}`, { sla_hours: parseInt(slaEdits[c.id], 10) })
      ))
      setCategories(prev => prev.map(c => ({ ...c, sla_hours: parseInt(slaEdits[c.id], 10) || c.sla_hours })))
      setToast({ kind: 'ok', text: t('saved_successfully') })
    } catch (e: unknown) {
      setToast({ kind: 'err', text: e instanceof Error ? e.message : t('save_failed') })
    } finally {
      setSavingSla(false)
    }
  }

  // ── Security (change password) ───────────────────────────────────────────
  const [pwForm, setPwForm] = useState({ current: '', next: '', confirm: '' })
  const [pwError, setPwError] = useState<string | null>(null)
  const [changingPw, setChangingPw] = useState(false)

  async function submitChangePassword() {
    setPwError(null)
    if (pwForm.next.length < 8) { setPwError(t('password_too_short_err')); return }
    if (pwForm.next !== pwForm.confirm) { setPwError(t('password_mismatch_err')); return }
    setChangingPw(true)
    try {
      await api.post('/users/me/change-password', {
        current_password: pwForm.current,
        new_password: pwForm.next,
      })
      setPwForm({ current: '', next: '', confirm: '' })
      setToast({ kind: 'ok', text: t('password_changed') })
    } catch (e: unknown) {
      setPwError(e instanceof Error ? e.message : t('save_failed'))
    } finally {
      setChangingPw(false)
    }
  }

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

  function categoryLabel(c: Category): string {
    return lang === 'ar' ? c.label_ar : c.label_fr
  }

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-[#0F172A] text-2xl font-bold">{t('nav_settings')}</h2>
        <p className="text-[#64748B] text-sm mt-1">{t('settings_sub')}</p>
      </div>

      {toast && (
        <div className={`flex items-center gap-2 rounded-xl px-4 py-3 mb-4 border
          ${toast.kind === 'ok' ? 'bg-green-50 border-green-100' : 'bg-red-50 border-red-100'}`}>
          <span className="material-symbols-outlined" style={{ fontSize: 16, color: toast.kind === 'ok' ? '#22C55E' : '#EF4444' }}>
            {toast.kind === 'ok' ? 'check_circle' : 'error'}
          </span>
          <span className="text-sm" style={{ color: toast.kind === 'ok' ? '#22C55E' : '#EF4444' }}>{toast.text}</span>
          <button onClick={() => setToast(null)} className="ml-auto text-[#94A3B8]">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>close</span>
          </button>
        </div>
      )}

      <div className="flex gap-6">
        {/* Sidebar nav */}
        <div className="w-56 flex-shrink-0">
          <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm overflow-hidden">
            {sections.map(s => (
              <button key={s.key} onClick={() => { setActiveSection(s.key); setToast(null) }}
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
                    <input value={profileForm.full_name} onChange={e => setProfileForm(f => ({ ...f, full_name: e.target.value }))}
                      className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_email_s')}</label>
                    <input defaultValue={user?.email ?? ''} type="email" disabled
                      className="w-full bg-[#f1f4f9] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none text-[#94A3B8] cursor-not-allowed" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_phone_s')}</label>
                    <input defaultValue={user?.phone ?? ''} type="tel" disabled
                      className="w-full bg-[#f1f4f9] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none text-[#94A3B8] cursor-not-allowed" />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_pref_lang')}</label>
                    <select value={profileForm.preferred_language} onChange={e => setProfileForm(f => ({ ...f, preferred_language: e.target.value }))}
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
              <div className="flex justify-end gap-3">
                <button onClick={() => user && setProfileForm({ full_name: user.full_name, preferred_language: user.preferred_language })}
                  className="px-6 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe]">
                  {t('btn_cancel_s')}
                </button>
                <button onClick={saveProfile} disabled={savingProfile}
                  className="px-6 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-medium shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                  {savingProfile ? t('saving') : t('btn_save_s')}
                </button>
              </div>
            </>
          )}

          {activeSection === 'notifications' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
              <h4 className="text-[#181c20] font-semibold text-base mb-1">{t('notif_channels')}</h4>
              <p className="text-xs text-[#94A3B8] mb-5">{t('notif_local_note')}</p>
              <div className="space-y-4">
                {([
                  { key: 'push',     label: t('notif_push_lbl'),  desc: t('notif_push_desc') },
                  { key: 'sms',      label: t('notif_sms_lbl'),   desc: t('notif_sms_desc') },
                  { key: 'email',    label: t('notif_email_lbl'), desc: t('notif_email_desc') },
                  { key: 'slaAlert', label: t('notif_sla_lbl'),   desc: t('notif_sla_desc') },
                ] as { key: keyof NotifPrefs; label: string; desc: string }[]).map(n => (
                  <div key={n.key} className="flex items-center justify-between p-4 rounded-xl bg-[#f7f9fe] border border-[#E2E8F0]">
                    <div>
                      <p className="text-sm font-semibold text-[#181c20]">{n.label}</p>
                      <p className="text-xs text-[#94A3B8] mt-0.5">{n.desc}</p>
                    </div>
                    <button onClick={() => toggleNotifPref(n.key)}
                      className="w-11 h-6 rounded-full relative transition-colors"
                      style={{ backgroundColor: notifPrefs[n.key] ? '#0038AF' : '#E2E8F0' }}>
                      <span className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-all ${notifPrefs[n.key] ? 'left-6' : 'left-1'}`} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeSection === 'sla' && (
            <>
              <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6">
                <h4 className="text-[#181c20] font-semibold text-base mb-2">{t('sla_config_title')}</h4>
                <p className="text-[#94A3B8] text-sm mb-5">{t('sla_config_desc')}</p>
                <div className="space-y-4">
                  {loadingCategories ? (
                    Array.from({ length: 5 }).map((_, i) => (
                      <div key={i} className="h-14 bg-[#f7f9fe] rounded-xl animate-pulse" />
                    ))
                  ) : categories.map(c => (
                    <div key={c.id} className="flex items-center gap-4 p-3 rounded-xl bg-[#f7f9fe] border border-[#E2E8F0]">
                      <span className="w-3 h-3 rounded-full flex-shrink-0 bg-[#0038AF]" />
                      <span className="text-sm font-medium text-[#181c20] flex-1">{categoryLabel(c)}</span>
                      <div className="flex items-center gap-2">
                        <input type="number" min={1} value={slaEdits[c.id] ?? ''}
                          onChange={e => setSlaEdits(prev => ({ ...prev, [c.id]: e.target.value }))}
                          className="w-20 bg-white border border-[#E2E8F0] rounded-lg px-3 py-1.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 text-center" />
                        <span className="text-xs text-[#64748B]">{t('sla_hours')}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="flex justify-end gap-3">
                <button onClick={() => {
                  const edits: Record<number, string> = {}
                  categories.forEach(c => { edits[c.id] = String(c.sla_hours ?? '') })
                  setSlaEdits(edits)
                }} className="px-6 py-2.5 border border-[#E2E8F0] text-[#64748B] rounded-xl text-sm font-medium hover:bg-[#f7f9fe]">
                  {t('btn_cancel_s')}
                </button>
                <button onClick={saveSla} disabled={savingSla || loadingCategories}
                  className="px-6 py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-medium shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                  {savingSla ? t('saving') : t('btn_save_s')}
                </button>
              </div>
            </>
          )}

          {activeSection === 'security' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6 max-w-md">
              <h4 className="text-[#181c20] font-semibold text-base mb-5">{t('btn_change_password')}</h4>
              {pwError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-100 rounded-xl px-4 py-3 mb-4">
                  <span className="material-symbols-outlined text-red-400" style={{ fontSize: 16 }}>error</span>
                  <span className="text-sm text-red-600">{pwError}</span>
                </div>
              )}
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_current_password')}</label>
                  <input type="password" value={pwForm.current} onChange={e => setPwForm(f => ({ ...f, current: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_new_password')}</label>
                  <input type="password" value={pwForm.next} onChange={e => setPwForm(f => ({ ...f, next: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#64748B] mb-1.5 uppercase tracking-wider">{t('lbl_confirm_password')}</label>
                  <input type="password" value={pwForm.confirm} onChange={e => setPwForm(f => ({ ...f, confirm: e.target.value }))}
                    className="w-full bg-[#f7f9fe] border border-[#E2E8F0] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[#0038AF]/20 focus:border-[#0038AF]" />
                </div>
                <button onClick={submitChangePassword} disabled={changingPw || !pwForm.current || !pwForm.next}
                  className="w-full py-2.5 bg-[#0038AF] text-white rounded-xl text-sm font-semibold shadow-md hover:opacity-90 transition-opacity disabled:opacity-50">
                  {changingPw ? t('saving') : t('btn_change_password')}
                </button>
              </div>
            </div>
          )}

          {activeSection === 'integrations' && (
            <div className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-8 text-center">
              <span className="material-symbols-outlined text-[#94A3B8] mb-3 block" style={{ fontSize: 40 }}>construction</span>
              <p className="text-[#64748B] text-sm">
                {sections.find(s => s.key === activeSection)?.label} — {t('under_dev')}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
