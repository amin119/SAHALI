import { useAuth } from '../context/AuthContext'
import { useLang } from '../context/LangContext'
import type { UserRole } from '../types/api'

interface HelpSection {
  id: string
  icon: string
  color: string
  roles?: UserRole[]
  title: { fr: string; ar: string }
  summary: { fr: string; ar: string }
  points: { fr: string[]; ar: string[] }
}

const SECTIONS: HelpSection[] = [
  {
    id: 'dashboard',
    icon: 'dashboard',
    color: '#0038AF',
    title: { fr: 'Tableau de bord', ar: 'لوحة القيادة' },
    summary: {
      fr: 'La page d\'accueil — ce qui a besoin de votre attention en premier, les statistiques détaillées en dessous.',
      ar: 'الصفحة الرئيسية — ما يتطلب اهتمامك أولاً، والإحصائيات المفصلة أسفلها.',
    },
    points: {
      fr: [
        'En haut : les signalements nouveaux, en examen et en cours — cliquez sur une carte pour ouvrir la liste déjà filtrée.',
        'Si tout est traité, un message vous le confirme au lieu d\'afficher des cartes vides.',
        'En dessous : indicateurs clés (total, taux de résolution), répartition par statut, et les signalements les plus récents.',
        'Bouton "Exporter" pour télécharger la liste complète en CSV.',
      ],
      ar: [
        'في الأعلى: البلاغات الجديدة، قيد المراجعة، وقيد التنفيذ — انقر على بطاقة لفتح القائمة المصفّاة مباشرة.',
        'إذا كان كل شيء قد عولج، تظهر رسالة تؤكد ذلك بدل بطاقات فارغة.',
        'أسفلها: المؤشرات الرئيسية (الإجمالي، معدل الحل)، التوزيع حسب الحالة، وآخر البلاغات.',
        'زر "تصدير" لتحميل القائمة الكاملة بصيغة CSV.',
      ],
    },
  },
  {
    id: 'map',
    icon: 'map',
    color: '#0EA5E9',
    roles: ['admin'],
    title: { fr: 'Carte en direct', ar: 'الخريطة المباشرة' },
    summary: {
      fr: 'Localise tous les signalements actifs sur une carte — les signalements résolus ou rejetés n\'y apparaissent pas.',
      ar: 'تحدد مواقع جميع البلاغات النشطة على خريطة — البلاغات المحلولة أو المرفوضة لا تظهر فيها.',
    },
    points: {
      fr: [
        'Chaque repère est coloré selon le statut du signalement.',
        'Filtrez via la légende sous la carte ou le menu déroulant en haut.',
        'Cliquez sur un repère pour voir un résumé dans le panneau latéral.',
      ],
      ar: [
        'كل علامة مرمّزة بلون يعكس حالة البلاغ.',
        'صفِّ عبر المفتاح تحت الخريطة أو القائمة المنسدلة في الأعلى.',
        'انقر على علامة لعرض ملخص في اللوحة الجانبية.',
      ],
    },
  },
  {
    id: 'statistics',
    icon: 'insert_chart',
    color: '#8B5CF6',
    roles: ['admin', 'analyst'],
    title: { fr: 'Statistiques', ar: 'الإحصائيات' },
    summary: {
      fr: 'Une analyse plus poussée que le tableau de bord : répartition par statut, vue d\'ensemble, et détail chiffré.',
      ar: 'تحليل أعمق من لوحة القيادة: توزيع حسب الحالة، نظرة عامة، وتفاصيل رقمية.',
    },
    points: {
      fr: [
        'Graphique de répartition des signalements par statut.',
        'Vue d\'ensemble des indicateurs de performance.',
        'Tableau détaillé pour aller plus loin que les chiffres globaux.',
      ],
      ar: [
        'رسم بياني لتوزيع البلاغات حسب الحالة.',
        'نظرة عامة على مؤشرات الأداء.',
        'جدول مفصل لتجاوز الأرقام العامة.',
      ],
    },
  },
  {
    id: 'reports',
    icon: 'report_problem',
    color: '#F97316',
    title: { fr: 'Signalements', ar: 'التقارير' },
    summary: {
      fr: 'La liste complète des signalements, et la page dédiée à chacun d\'eux.',
      ar: 'القائمة الكاملة للبلاغات، وصفحة خاصة بكل واحد منها.',
    },
    points: {
      fr: [
        'Recherchez par code, titre ou ville ; filtrez par statut.',
        'Cliquez sur une ligne pour ouvrir la page complète du signalement — pas une simple fenêtre, une vraie page avec son propre lien.',
        'Sur cette page : le parcours visuel du signalement (soumis → reçu → en examen → en cours → résolu), les détails, l\'équipe assignée, le rapport de résolution une fois terminé, et l\'historique complet.',
        'Faites avancer un signalement à l\'étape suivante directement depuis sa page, avec une note optionnelle.',
        'Pour assigner un agent : seuls les agents actuellement en service apparaissent par défaut ; cochez "Tous les agents" ou utilisez la recherche pour voir les autres.',
      ],
      ar: [
        'البحث بالرمز أو العنوان أو المدينة؛ التصفية حسب الحالة.',
        'انقر على سطر لفتح صفحة البلاغ الكاملة — ليست نافذة منبثقة، بل صفحة حقيقية برابط خاص بها.',
        'في هذه الصفحة: مسار البلاغ المرئي (مُقدَّم ← مستلَم ← قيد المراجعة ← قيد التنفيذ ← محلول)، التفاصيل، الفريق المكلَّف، تقرير الحل بعد الإنجاز، والسجل الكامل.',
        'انقل البلاغ إلى المرحلة التالية مباشرة من صفحته، مع ملاحظة اختيارية.',
        'لتكليف عون: يظهر الأعوان المتاحون حالياً فقط بشكل تلقائي؛ فعّل "كل الأعوان" أو استخدم البحث لرؤية الباقي.',
      ],
    },
  },
  {
    id: 'interventions',
    icon: 'engineering',
    color: '#0038AF',
    roles: ['admin'],
    title: { fr: 'Interventions', ar: 'التدخلات' },
    summary: {
      fr: 'Une vue Kanban des signalements en cours de traitement, organisée par étape.',
      ar: 'عرض Kanban للبلاغات قيد المعالجة، منظّم حسب المرحلة.',
    },
    points: {
      fr: [
        'Quatre colonnes : réception, examen, en cours, terminés.',
        'Glissez-déposez une carte vers la colonne suivante pour faire avancer le signalement — un déplacement illégal (qui saute une étape) est refusé.',
        'Une courte note optionnelle peut être ajoutée à chaque déplacement.',
        'Cliquer sur une carte ouvre aussi un panneau classique, pour ceux qui préfèrent choisir le prochain statut dans une liste.',
      ],
      ar: [
        'أربعة أعمدة: الاستقبال، المراجعة، قيد التنفيذ، المنتهية.',
        'اسحب بطاقة إلى العمود التالي لنقل البلاغ إلى المرحلة التالية — أي نقل غير قانوني (يتخطى مرحلة) يُرفض.',
        'يمكن إضافة ملاحظة قصيرة اختيارية مع كل نقل.',
        'النقر على بطاقة يفتح أيضاً لوحة كلاسيكية، لمن يفضّل اختيار الحالة التالية من قائمة.',
      ],
    },
  },
  {
    id: 'calendar',
    icon: 'calendar_today',
    color: '#22C55E',
    roles: ['admin'],
    title: { fr: 'Calendrier', ar: 'التقويم' },
    summary: {
      fr: 'Une vue semaine par semaine de l\'activité des signalements, un jour par colonne.',
      ar: 'عرض أسبوعي لنشاط البلاغات، بعمود ليوم واحد.',
    },
    points: {
      fr: [
        'Chaque carte représente un signalement, classée dans la journée où il a été mis à jour.',
        'Naviguez avec les flèches, ou revenez à "Aujourd\'hui".',
        'Cliquez sur une carte pour voir ses détails.',
      ],
      ar: [
        'كل بطاقة تمثل بلاغاً، مصنّفة في اليوم الذي تم تحديثه فيه.',
        'تنقّل بالأسهم، أو عد إلى "اليوم".',
        'انقر على بطاقة لعرض تفاصيلها.',
      ],
    },
  },
  {
    id: 'teams',
    icon: 'groups',
    color: '#8B5CF6',
    roles: ['admin'],
    title: { fr: 'Équipes & Agents', ar: 'الفرق والأعوان' },
    summary: {
      fr: 'La gestion de vos agents et analystes, leurs horaires, et leurs statistiques individuelles.',
      ar: 'إدارة الأعوان والمحللين، جداولهم، وإحصائياتهم الفردية.',
    },
    points: {
      fr: [
        'Ajoutez, modifiez, activez ou désactivez un compte agent/analyste.',
        'Ouvrez un agent pour voir ses signalements assignés, résolus, en cours, et sa performance.',
        'Définissez ses horaires de travail hebdomadaires — c\'est ce qui détermine s\'il apparaît comme "disponible" lors d\'une assignation de signalement.',
      ],
      ar: [
        'أضف، عدّل، فعّل أو عطّل حساب عون/محلل.',
        'افتح ملف عون لعرض بلاغاته المكلَّف بها، المحلولة، قيد التنفيذ، وأدائه.',
        'حدّد ساعات عمله الأسبوعية — هذا ما يحدد ظهوره كـ"متاح" عند تكليفه ببلاغ.',
      ],
    },
  },
  {
    id: 'municipalities',
    icon: 'location_city',
    color: '#0038AF',
    roles: ['admin'],
    title: { fr: 'Municipalités', ar: 'البلديات' },
    summary: {
      fr: 'Réservée au super-admin — la gestion de toutes les municipalités de la plateforme.',
      ar: 'مخصصة للمدير العام — إدارة جميع بلديات المنصة.',
    },
    points: {
      fr: [
        'Ajoutez ou modifiez une municipalité, avec sa localisation sur une carte.',
        'Cette localisation sert à orienter automatiquement chaque nouveau signalement vers la municipalité la plus proche.',
        'Ouvrez une municipalité pour voir la liste réelle des agents qui y travaillent.',
      ],
      ar: [
        'أضف أو عدّل بلدية، مع تحديد موقعها على خريطة.',
        'يُستخدم هذا الموقع لتوجيه كل بلاغ جديد تلقائياً إلى أقرب بلدية.',
        'افتح بلدية لعرض القائمة الفعلية للأعوان العاملين فيها.',
      ],
    },
  },
  {
    id: 'categories',
    icon: 'category',
    color: '#F59E0B',
    roles: ['admin'],
    title: { fr: 'Catégories', ar: 'الفئات' },
    summary: {
      fr: 'Les types de signalement que les citoyens peuvent soumettre depuis l\'application mobile.',
      ar: 'أنواع البلاغات التي يمكن للمواطنين تقديمها من التطبيق المحمول.',
    },
    points: {
      fr: [
        'Super-admin : active ou désactive une catégorie pour l\'ensemble de la plateforme.',
        'Admin municipal : active ou désactive une catégorie uniquement pour sa propre municipalité — les citoyens de cette municipalité ne la verront plus dans l\'application, les autres municipalités ne sont pas affectées.',
        'Une catégorie désactivée par le super-admin reste indisponible partout, quoi que fasse un admin municipal.',
      ],
      ar: [
        'المدير العام: يفعّل أو يعطّل فئة على مستوى المنصة كاملة.',
        'المدير البلدي: يفعّل أو يعطّل فئة لبلديته فقط — لن يراها مواطنو هذه البلدية في التطبيق، ولا تتأثر البلديات الأخرى.',
        'الفئة المعطّلة من المدير العام تبقى غير متاحة في كل مكان، بغض النظر عن إجراء المدير البلدي.',
      ],
    },
  },
  {
    id: 'settings',
    icon: 'settings',
    color: '#64748B',
    title: { fr: 'Paramètres', ar: 'الإعدادات' },
    summary: {
      fr: 'Votre profil, vos notifications, et — pour les admins — la configuration de la plateforme.',
      ar: 'ملفك الشخصي، إشعاراتك، و — للمدراء — إعدادات المنصة.',
    },
    points: {
      fr: [
        'Profil : nom, mot de passe, langue préférée.',
        'Notifications, seuils SLA, sécurité et intégrations.',
      ],
      ar: [
        'الملف الشخصي: الاسم، كلمة المرور، اللغة المفضلة.',
        'الإشعارات، حدود SLA، الأمان والتكاملات.',
      ],
    },
  },
]

export default function Help() {
  const { user } = useAuth()
  const { lang } = useLang()

  const visible = SECTIONS.filter(s => !s.roles || (user && s.roles.includes(user.role)))

  const isSuperAdmin = user?.role === 'admin' && user?.municipality_id == null
  const isMunicipalAdmin = user?.role === 'admin' && user?.municipality_id != null
  const roleIntro = lang === 'ar'
    ? isSuperAdmin
      ? 'بصفتك مديراً عاماً، لديك صلاحية الوصول إلى كل ما يلي — بما في ذلك إدارة البلديات على مستوى المنصة كاملة.'
      : isMunicipalAdmin
        ? 'بصفتك مديراً بلدياً، ما يلي مخصص ببلديتك — الفرق، البلاغات، والفئات التي تراها تخصك فقط.'
        : 'فيما يلي الصفحات المتاحة لحسابك.'
    : isSuperAdmin
      ? 'En tant que super-admin, vous avez accès à tout ce qui suit — y compris la gestion des municipalités à l\'échelle de toute la plateforme.'
      : isMunicipalAdmin
        ? 'En tant qu\'admin municipal, tout ce qui suit est scopé à votre municipalité — les équipes, signalements et catégories que vous voyez ne concernent qu\'elle.'
        : 'Voici les pages disponibles pour votre compte.'

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <h2 className="text-[#0F172A] text-2xl font-bold">
          {lang === 'ar' ? 'كيفية استخدام سهلي' : 'Comment utiliser Sahali'}
        </h2>
        <p className="text-[#64748B] text-sm mt-2 max-w-2xl">{roleIntro}</p>
      </div>

      <div className="flex gap-8">
        {/* Table of contents — desktop only */}
        <div className="hidden lg:block w-48 flex-shrink-0">
          <div className="sticky top-24 space-y-1">
            {visible.map(s => (
              <a
                key={s.id}
                href={`#${s.id}`}
                className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-[#64748B] hover:bg-white hover:text-[#181c20] transition-colors"
              >
                <span className="material-symbols-outlined" style={{ fontSize: 16, color: s.color }}>{s.icon}</span>
                {s.title[lang === 'ar' ? 'ar' : 'fr']}
              </a>
            ))}
          </div>
        </div>

        {/* Sections */}
        <div className="flex-1 min-w-0 space-y-5">
          {visible.map(s => (
            <div key={s.id} id={s.id} className="bg-white rounded-xl border border-[#E2E8F0] shadow-sm p-6 scroll-mt-24">
              <div className="flex items-start gap-4 mb-4">
                <div className="w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${s.color}18` }}>
                  <span className="material-symbols-outlined" style={{ fontSize: 22, color: s.color }}>{s.icon}</span>
                </div>
                <div>
                  <h3 className="text-[#181c20] font-bold text-base">{s.title[lang === 'ar' ? 'ar' : 'fr']}</h3>
                  <p className="text-sm text-[#64748B] mt-0.5">{s.summary[lang === 'ar' ? 'ar' : 'fr']}</p>
                </div>
              </div>
              <ul className="space-y-2 pl-1">
                {s.points[lang === 'ar' ? 'ar' : 'fr'].map((point, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm text-[#181c20] leading-relaxed">
                    <span className="material-symbols-outlined text-[#94A3B8] flex-shrink-0 mt-0.5" style={{ fontSize: 14 }}>arrow_right</span>
                    {point}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
