import type { Side } from 'driver.js'

type Lang = 'fr' | 'ar'

interface TourStepDef {
  element: string
  side?: Side
  title: { fr: string; ar: string }
  description: { fr: string; ar: string }
}

// Keyed by route path — ':id' segments are matched generically so
// /reports/abc-123 resolves to the '/reports/:id' entry below.
const TOURS: Record<string, TourStepDef[]> = {
  '/dashboard': [
    {
      element: '[data-tour="attention"]',
      title: { fr: 'Ce qui a besoin de vous', ar: 'ما يحتاج إلى اهتمامك' },
      description: {
        fr: 'Ces cartes montrent les signalements nouveaux, en examen et en cours. Cliquez sur une carte pour ouvrir la liste déjà filtrée — c\'est le premier endroit à regarder chaque jour.',
        ar: 'تُظهر هذه البطاقات البلاغات الجديدة، قيد المراجعة، وقيد التنفيذ. انقر على بطاقة لفتح القائمة المصفّاة مباشرة — هذا أول مكان تنظر إليه كل يوم.',
      },
    },
    {
      element: '[data-tour="kpi-cards"]',
      side: 'bottom',
      title: { fr: 'Indicateurs clés', ar: 'المؤشرات الرئيسية' },
      description: {
        fr: 'Total, en attente, résolus, rejetés — la photo d\'ensemble de l\'activité.',
        ar: 'الإجمالي، قيد الانتظار، المحلولة، المرفوضة — الصورة الشاملة للنشاط.',
      },
    },
    {
      element: '[data-tour="recent-reports"]',
      side: 'top',
      title: { fr: 'Signalements récents', ar: 'البلاغات الأخيرة' },
      description: {
        fr: 'Les derniers signalements soumis, avec un bouton pour exporter toute la liste en CSV.',
        ar: 'آخر البلاغات المقدَّمة، مع زر لتصدير القائمة كاملة بصيغة CSV.',
      },
    },
  ],

  '/reports': [
    {
      element: '[data-tour="reports-filters"]',
      title: { fr: 'Rechercher et filtrer', ar: 'البحث والتصفية' },
      description: {
        fr: 'Cherchez par code, titre ou ville, et filtrez par statut pour ne voir que ce qui vous intéresse.',
        ar: 'ابحث بالرمز أو العنوان أو المدينة، وصفِّ حسب الحالة لرؤية ما يهمك فقط.',
      },
    },
    {
      element: '[data-tour="reports-table"]',
      title: { fr: 'La liste des signalements', ar: 'قائمة البلاغات' },
      description: {
        fr: 'Cliquez n\'importe où sur une ligne pour ouvrir la page complète de ce signalement — c\'est là que se passe tout : assignation, avancement, résolution.',
        ar: 'انقر في أي مكان على سطر لفتح الصفحة الكاملة لهذا البلاغ — هناك يحدث كل شيء: التكليف، التقدّم، الحل.',
      },
    },
    {
      element: '[data-tour="reports-export"]',
      side: 'bottom',
      title: { fr: 'Exporter', ar: 'تصدير' },
      description: {
        fr: 'Téléchargez la liste complète (avec les filtres actuels) au format CSV.',
        ar: 'نزّل القائمة الكاملة (مع الفلاتر الحالية) بصيغة CSV.',
      },
    },
  ],

  // The flagship example — assigning an agent and advancing a report through
  // its phases, step by step, pointing at the real controls.
  '/reports/:id': [
    {
      element: '[data-tour="journey"]',
      title: { fr: 'Le parcours du signalement', ar: 'مسار البلاغ' },
      description: {
        fr: 'Cette barre montre où en est le signalement : soumis → reçu → en examen → en cours → résolu. L\'étape actuelle est en bleu.',
        ar: 'يُظهر هذا الشريط أين وصل البلاغ: مُقدَّم ← مستلَم ← قيد المراجعة ← قيد التنفيذ ← محلول. المرحلة الحالية بالأزرق.',
      },
    },
    {
      element: '[data-tour="status-action"]',
      title: { fr: 'Faire avancer le signalement', ar: 'تقديم البلاغ إلى المرحلة التالية' },
      description: {
        fr: 'Voici comment avancer d\'une phase : cliquez sur la prochaine étape proposée (par exemple "En cours"), ajoutez une note si besoin, puis confirmez. Vous ne pouvez pas sauter une étape — c\'est volontaire, pour garder un historique fiable.',
        ar: 'هكذا تنتقل إلى المرحلة التالية: انقر على الخيار المقترح (مثلاً "قيد التنفيذ")، أضف ملاحظة إذا لزم الأمر، ثم أكّد. لا يمكنك تخطي مرحلة — هذا مقصود للحفاظ على سجل موثوق.',
      },
    },
    {
      element: '[data-tour="assign-search"]',
      title: { fr: 'Trouver un agent disponible', ar: 'إيجاد عون متاح' },
      description: {
        fr: 'Par défaut, seuls les agents actuellement en service apparaissent dans la liste ci-dessous — ceux dont l\'horaire de travail couvre l\'heure actuelle. Tapez un nom pour chercher un agent précis, ou cochez "Tous les agents" pour voir tout le monde, y compris hors service.',
        ar: 'بشكل تلقائي، يظهر في القائمة أدناه فقط الأعوان العاملون حالياً — الذين تشمل ساعات عملهم الوقت الحالي. اكتب اسماً للبحث عن عون معيّن، أو فعّل "كل الأعوان" لرؤية جميع الأعوان بما فيهم غير المتاحين.',
      },
    },
    {
      element: '[data-tour="assign-list"]',
      title: { fr: 'Choisir un ou plusieurs agents', ar: 'اختيار عون واحد أو أكثر' },
      description: {
        fr: 'Cochez un ou plusieurs agents dans la liste. Vous pouvez en assigner plusieurs au même signalement si besoin.',
        ar: 'حدّد عوناً واحداً أو أكثر من القائمة. يمكنك تكليف عدة أعوان بنفس البلاغ عند الحاجة.',
      },
    },
    {
      element: '[data-tour="assign-btn"]',
      side: 'top',
      title: { fr: 'Confirmer l\'assignation', ar: 'تأكيد التكليف' },
      description: {
        fr: 'Ajoutez une note pour l\'agent si vous voulez, puis cliquez ici pour valider — l\'agent recevra une notification.',
        ar: 'أضف ملاحظة للعون إذا رغبت، ثم انقر هنا للتأكيد — سيصل إشعار إلى العون.',
      },
    },
    {
      element: '[data-tour="resolution"]',
      title: { fr: 'Le rapport de résolution', ar: 'تقرير الحل' },
      description: {
        fr: 'Une fois le signalement résolu, le compte-rendu de l\'agent apparaît ici : ce qu\'il a fait, les matériaux utilisés, et ses photos ou vidéos. Si le rapport n\'existe pas encore, vous pouvez le créer vous-même depuis cette section.',
        ar: 'بعد حل البلاغ، يظهر هنا تقرير العون: ما قام به، المواد المستخدمة، وصوره أو مقاطع الفيديو. إذا لم يُنشأ التقرير بعد، يمكنك إنشاؤه بنفسك من هنا.',
      },
    },
    {
      element: '[data-tour="history"]',
      side: 'top',
      title: { fr: 'Historique détaillé', ar: 'السجل التفصيلي' },
      description: {
        fr: 'Le journal complet de chaque changement de statut, avec qui l\'a fait, quand, et la note laissée à ce moment-là.',
        ar: 'السجل الكامل لكل تغيير في الحالة، مع مَن قام به، ومتى، والملاحظة المتروكة في تلك اللحظة.',
      },
    },
  ],

  '/interventions': [
    {
      element: '[data-tour="kanban-board"]',
      title: { fr: 'Le tableau Kanban', ar: 'لوحة Kanban' },
      description: {
        fr: 'Quatre colonnes, une par étape : Réception, Examen, En cours, Terminés. Chaque carte est un signalement.',
        ar: 'أربعة أعمدة، واحد لكل مرحلة: الاستقبال، المراجعة، قيد التنفيذ، المنتهية. كل بطاقة تمثل بلاغاً.',
      },
    },
    {
      element: '[data-tour="kanban-card"]',
      title: { fr: 'Glissez pour faire avancer', ar: 'اسحب للتقدّم' },
      description: {
        fr: 'Saisissez une carte et déposez-la dans la colonne suivante pour changer son statut — une note optionnelle vous sera proposée avant de confirmer. Un déplacement qui saute une étape est refusé automatiquement.',
        ar: 'أمسك بطاقة وأسقطها في العمود التالي لتغيير حالتها — ستُعرض عليك ملاحظة اختيارية قبل التأكيد. أي نقل يتخطى مرحلة يُرفض تلقائياً.',
      },
    },
  ],

  '/calendar': [
    {
      element: '[data-tour="calendar-grid"]',
      title: { fr: 'Vue semaine', ar: 'عرض أسبوعي' },
      description: {
        fr: 'Chaque colonne est un jour, chaque carte un signalement actif ce jour-là. Utilisez les flèches pour changer de semaine.',
        ar: 'كل عمود يمثل يوماً، وكل بطاقة بلاغاً نشطاً في ذلك اليوم. استخدم الأسهم للتنقل بين الأسابيع.',
      },
    },
  ],

  '/teams': [
    {
      element: '[data-tour="teams-list"]',
      title: { fr: 'Vos agents et analystes', ar: 'أعوانك ومحلّلوك' },
      description: {
        fr: 'Cliquez sur un agent pour ouvrir son profil : ses statistiques, ses missions actives, et ses horaires.',
        ar: 'انقر على عون لفتح ملفه: إحصائياته، مهامه النشطة، وساعات عمله.',
      },
    },
    {
      element: '[data-tour="add-agent"]',
      side: 'bottom',
      title: { fr: 'Ajouter un agent', ar: 'إضافة عون' },
      description: {
        fr: 'Créez un nouveau compte agent ou analyste ici.',
        ar: 'أنشئ حساب عون أو محلل جديد من هنا.',
      },
    },
    {
      element: '[data-tour="schedule-editor"]',
      side: 'left',
      title: { fr: 'Définir les horaires de travail', ar: 'تحديد ساعات العمل' },
      description: {
        fr: 'Cochez les jours travaillés et réglez les heures de début et de fin. C\'est ce qui détermine si cet agent apparaît comme "disponible" quand on assigne un signalement.',
        ar: 'فعّل أيام العمل وحدّد ساعات البداية والنهاية. هذا ما يحدد ظهور هذا العون كـ"متاح" عند تكليف بلاغ.',
      },
    },
  ],

  '/municipalities': [
    {
      element: '[data-tour="muni-add"]',
      title: { fr: 'Ajouter une municipalité', ar: 'إضافة بلدية' },
      description: {
        fr: 'Créez une municipalité et placez son centre sur la carte en cliquant dessus — cette position sert à orienter automatiquement chaque nouveau signalement vers la municipalité la plus proche.',
        ar: 'أنشئ بلدية وحدّد مركزها على الخريطة بالنقر عليها — يُستخدم هذا الموقع لتوجيه كل بلاغ جديد تلقائياً إلى أقرب بلدية.',
      },
    },
    {
      element: '[data-tour="muni-table"]',
      title: { fr: 'Cliquer pour voir le détail', ar: 'انقر لعرض التفاصيل' },
      description: {
        fr: 'Cliquez sur une municipalité pour voir ses agents réels, sa localisation, et son taux de résolution.',
        ar: 'انقر على بلدية لعرض أعوانها الفعليين، موقعها، ومعدل حلها.',
      },
    },
  ],

  '/categories': [
    {
      element: '[data-tour="category-toggle"]',
      title: { fr: 'Activer ou désactiver une catégorie', ar: 'تفعيل أو تعطيل فئة' },
      description: {
        fr: 'En tant que super-admin, ce bouton active/désactive une catégorie pour toute la plateforme. En tant qu\'admin municipal, il ne l\'active/désactive que pour votre propre municipalité — les citoyens de chez vous ne la verront plus dans l\'application mobile, les autres municipalités ne sont pas affectées.',
        ar: 'كمدير عام، هذا الزر يفعّل/يعطّل فئة على مستوى المنصة كاملة. كمدير بلدي، يفعّلها/يعطّلها فقط لبلديتك — لن يراها مواطنوك في التطبيق، ولا تتأثر البلديات الأخرى.',
      },
    },
  ],

  '/map': [
    {
      element: '[data-tour="map-canvas"]',
      title: { fr: 'La carte', ar: 'الخريطة' },
      description: {
        fr: 'Chaque repère est un signalement actif, coloré selon son statut. Cliquez sur un repère pour un résumé.',
        ar: 'كل علامة تمثل بلاغاً نشطاً، ملوّنة حسب حالته. انقر على علامة لعرض ملخص.',
      },
    },
    {
      element: '[data-tour="map-legend"]',
      side: 'top',
      title: { fr: 'Filtrer par statut', ar: 'التصفية حسب الحالة' },
      description: {
        fr: 'Cliquez sur un statut de la légende pour n\'afficher que ces signalements-là.',
        ar: 'انقر على حالة في المفتاح لعرض هذه البلاغات فقط.',
      },
    },
  ],

  '/statistics': [
    {
      element: '[data-tour="stats-chart"]',
      title: { fr: 'Répartition par statut', ar: 'التوزيع حسب الحالة' },
      description: {
        fr: 'Une vue visuelle de la proportion de signalements dans chaque statut.',
        ar: 'عرض بصري لنسبة البلاغات في كل حالة.',
      },
    },
  ],

  '/settings': [
    {
      element: '[data-tour="settings-tabs"]',
      title: { fr: 'Sections des paramètres', ar: 'أقسام الإعدادات' },
      description: {
        fr: 'Profil, notifications, seuils SLA, sécurité et intégrations — chaque onglet regroupe un type de réglage.',
        ar: 'الملف الشخصي، الإشعارات، حدود SLA، الأمان والتكاملات — كل تبويب يجمع نوعاً من الإعدادات.',
      },
    },
  ],
}

function resolveKey(pathname: string): string {
  if (/^\/reports\/[^/]+$/.test(pathname)) return '/reports/:id'
  return pathname
}

export function hasTour(pathname: string): boolean {
  return (TOURS[resolveKey(pathname)]?.length ?? 0) > 0
}

export function getTourSteps(pathname: string, lang: Lang) {
  const defs = TOURS[resolveKey(pathname)] ?? []
  return defs.map(d => ({
    element: d.element,
    popover: {
      title: d.title[lang],
      description: d.description[lang],
      side: d.side,
    },
  }))
}
