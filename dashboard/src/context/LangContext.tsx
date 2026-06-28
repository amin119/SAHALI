import { createContext, useContext, useState, useEffect, type ReactNode } from 'react'

type Lang = 'fr' | 'ar'

const FR = {
  // Navigation
  nav_dashboard:     'Tableau de bord',
  nav_map:           'Carte en direct',
  nav_reports:       'Signalements',
  nav_interventions: 'Interventions',
  nav_calendar:      'Calendrier',
  nav_teams:         'Équipes & Agents',
  nav_municipalities:'Municipalités',
  nav_categories:    'Catégories',
  nav_statistics:    'Statistiques',
  nav_settings:      'Paramètres',
  // Status
  status_received:    'Reçu',
  status_under_review:'En examen',
  status_in_progress: 'En cours',
  status_resolved:    'Résolu',
  status_rejected:    'Rejeté',
  // Priority
  priority_low:      'Basse',
  priority_medium:   'Moyenne',
  priority_high:     'Haute',
  priority_critical: 'Critique',
  // Reports page
  reports_title:     'Signalements',
  reports_export:    'Exporter CSV',
  reports_search:    'Rechercher par code, titre, ville...',
  reports_all_statuses: 'Tous les statuts',
  col_code:   'Code',
  col_title:  'Titre',
  col_city:   'Ville',
  col_priority:'Priorité',
  col_status: 'Statut',
  col_date:   'Date',
  no_reports: 'Aucun signalement trouvé',
  prev:       '← Précédent',
  next:       'Suivant →',
  // Detail tabs
  tab_info:        'Détail',
  tab_history:     'Traçabilité',
  tab_assignment:  'Assignation',
  tab_report:      'Rapport',
  // Detail
  lbl_category:    'Catégorie',
  lbl_address:     'Adresse',
  lbl_description: 'Description',
  lbl_submitted:   'Soumis le',
  lbl_resolved_on: 'Résolu le',
  change_status:   'Changer le statut',
  move_to:         'Passer à',
  note_optional:   'Note (optionnel)',
  rejection_reason:'Motif de rejet *',
  rejection_placeholder: 'Expliquez la raison du rejet...',
  btn_confirm:     'Confirmer',
  btn_cancel:      'Annuler',
  // History
  status_history:  'Historique des statuts',
  by:              'par',
  no_history:      'Aucun historique',
  // Assignment
  assigned_agents: 'Agents assignés',
  reassign:        'Réassigner',
  assign_agents:   'Assigner des agents',
  assign_note_placeholder: "Note d'assignation (optionnel)",
  btn_assign:      'Assigner',
  assigning:       'Assignation...',
  no_agents:       'Aucun agent disponible',
  assign_history:  "Historique d'assignation",
  assigned_by:     'assigné par',
  // Resolution
  report_locked:   'Disponible une fois le signalement résolu',
  resolved_by:     'Résolu par',
  intervention_report: "Rapport d'intervention",
  materials_used:  'Matériaux utilisés',
  team:            'Équipe',
  create_report:   'Créer le rapport de résolution',
  report_comment_label: "Compte-rendu d'intervention *",
  report_comment_placeholder: 'Décrivez les actions réalisées...',
  materials_label: 'Matériaux utilisés',
  materials_placeholder: 'Ex: 2 m³ de béton, signalétique...',
  btn_create_report: 'Créer le rapport',
  saving:          'Enregistrement...',
  // Map
  map_title:       'Carte',
  map_subtitle:    'signalements géolocalisés',
  map_all_statuses:'Tous les statuts',
  map_summary:     'Résumé',
  map_total:       'Total',
  map_today:       "Aujourd'hui",
  map_displayed:   'Affichés',
  map_avg:         'Moy. résolution',
  map_by_status:   'Par statut',
  // Categories
  categories_title: 'Catégories',
  categories_configured: 'catégories configurées',
  root_categories: 'Catégories racines',
  sub_categories:  'Sous-catégorie',
  root_category:   'Catégorie racine',
  priority_label:  'Priorité',
  sla_target:      'SLA cible',
  // Common
  loading:         'Chargement...',
  refresh:         'Actualiser',
  error_retry:     'Réessayer',
}

const AR: typeof FR = {
  nav_dashboard:     'لوحة القيادة',
  nav_map:           'الخريطة المباشرة',
  nav_reports:       'التقارير',
  nav_interventions: 'التدخلات',
  nav_calendar:      'التقويم',
  nav_teams:         'الفرق والعملاء',
  nav_municipalities:'البلديات',
  nav_categories:    'الفئات',
  nav_statistics:    'الإحصائيات',
  nav_settings:      'الإعدادات',
  status_received:    'مستلم',
  status_under_review:'قيد الدراسة',
  status_in_progress: 'قيد التنفيذ',
  status_resolved:    'محلول',
  status_rejected:    'مرفوض',
  priority_low:      'منخفضة',
  priority_medium:   'متوسطة',
  priority_high:     'عالية',
  priority_critical: 'حرجة',
  reports_title:     'التقارير',
  reports_export:    'تصدير CSV',
  reports_search:    'بحث بالرمز، العنوان، المدينة...',
  reports_all_statuses: 'جميع الحالات',
  col_code:   'الرمز',
  col_title:  'العنوان',
  col_city:   'المدينة',
  col_priority:'الأولوية',
  col_status: 'الحالة',
  col_date:   'التاريخ',
  no_reports: 'لا توجد تقارير',
  prev:       '→ السابق',
  next:       'التالي ←',
  tab_info:        'التفاصيل',
  tab_history:     'السجل',
  tab_assignment:  'التكليف',
  tab_report:      'التقرير',
  lbl_category:    'الفئة',
  lbl_address:     'العنوان',
  lbl_description: 'الوصف',
  lbl_submitted:   'تاريخ الإرسال',
  lbl_resolved_on: 'تاريخ الحل',
  change_status:   'تغيير الحالة',
  move_to:         'الانتقال إلى',
  note_optional:   'ملاحظة (اختياري)',
  rejection_reason:'سبب الرفض *',
  rejection_placeholder: 'اشرح سبب رفض هذا البلاغ...',
  btn_confirm:     'تأكيد',
  btn_cancel:      'إلغاء',
  status_history:  'سجل الحالات',
  by:              'بواسطة',
  no_history:      'لا يوجد سجل',
  assigned_agents: 'العملاء المكلفون',
  reassign:        'إعادة التكليف',
  assign_agents:   'تكليف عملاء',
  assign_note_placeholder: 'ملاحظة التكليف (اختياري)',
  btn_assign:      'تكليف',
  assigning:       'جار التكليف...',
  no_agents:       'لا يوجد عملاء',
  assign_history:  'سجل التكليفات',
  assigned_by:     'كُلِّف بواسطة',
  report_locked:   'متاح بعد حل البلاغ',
  resolved_by:     'حُل بواسطة',
  intervention_report: 'تقرير التدخل',
  materials_used:  'المواد المستخدمة',
  team:            'الفريق',
  create_report:   'إنشاء تقرير الحل',
  report_comment_label: 'تقرير التدخل *',
  report_comment_placeholder: 'صف الإجراءات المنفذة...',
  materials_label: 'المواد المستخدمة',
  materials_placeholder: 'مثال: 2 م³ خرسانة، لافتات...',
  btn_create_report: 'إنشاء التقرير',
  saving:          'جار الحفظ...',
  map_title:       'الخريطة',
  map_subtitle:    'بلاغات على الخريطة',
  map_all_statuses:'جميع الحالات',
  map_summary:     'ملخص',
  map_total:       'الإجمالي',
  map_today:       'اليوم',
  map_displayed:   'المعروضة',
  map_avg:         'متوسط الحل',
  map_by_status:   'حسب الحالة',
  categories_title: 'الفئات',
  categories_configured: 'فئات مضبوطة',
  root_categories: 'الفئات الرئيسية',
  sub_categories:  'فئة فرعية',
  root_category:   'فئة رئيسية',
  priority_label:  'الأولوية',
  sla_target:      'هدف SLA',
  loading:         'جار التحميل...',
  refresh:         'تحديث',
  error_retry:     'إعادة المحاولة',
}

const DICT: Record<Lang, typeof FR> = { fr: FR, ar: AR }

export type TranslationKey = keyof typeof FR

interface LangCtx {
  lang: Lang
  setLang: (l: Lang) => void
  t: (key: TranslationKey) => string
  dir: 'ltr' | 'rtl'
}

const Ctx = createContext<LangCtx>({
  lang: 'fr', setLang: () => {}, t: k => FR[k], dir: 'ltr',
})

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(
    () => (localStorage.getItem('sahali_lang') as Lang) ?? 'fr'
  )

  const setLang = (l: Lang) => {
    setLangState(l)
    localStorage.setItem('sahali_lang', l)
  }

  useEffect(() => {
    document.documentElement.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr')
    document.documentElement.setAttribute('lang', lang)
  }, [lang])

  const t = (key: keyof typeof FR) => DICT[lang][key] ?? DICT.fr[key]
  const dir: 'ltr' | 'rtl' = lang === 'ar' ? 'rtl' : 'ltr'

  return <Ctx.Provider value={{ lang, setLang, t, dir }}>{children}</Ctx.Provider>
}

export function useLang() { return useContext(Ctx) }
