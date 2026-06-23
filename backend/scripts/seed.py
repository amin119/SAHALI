"""
Demo seed — 8 municipalities, 20 staff, 80 citizens, 650 reports.
Run AFTER migrations:
    alembic downgrade base && alembic upgrade head
    uv run python scripts/seed.py
"""
import sys, uuid, random
from pathlib import Path
from datetime import datetime, timedelta, timezone

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.models.report import Report, ReportStatus, ReportPriority, ReportStatusHistory
from app.models.notification import Notification
from app.utils.security import hash_password
import sqlalchemy as sa

random.seed(42)

# ── helpers ──────────────────────────────────────────────────────────────────

def days_ago(n: float) -> datetime:
    return datetime.now(timezone.utc) - timedelta(days=n)

def rand_dt(min_days: float, max_days: float) -> datetime:
    return days_ago(random.uniform(min_days, max_days))

CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789"
_used: set[str] = set()

def tracking_code() -> str:
    while True:
        c = "CA" + "".join(random.choices(CHARS, k=6))
        if c not in _used:
            _used.add(c)
            return c

# ── geography ────────────────────────────────────────────────────────────────

CITIES = [
    ("Tunis",          36.8190, 10.1658, "pro"),
    ("La Marsa",       36.8780, 10.3240, "pro"),
    ("Ariana",         36.8625, 10.1956, "standard"),
    ("Carthage",       36.8528, 10.3233, "standard"),
    ("Sidi Bou Saïd",  36.8700, 10.3413, "standard"),
    ("La Goulette",    36.8180, 10.3050, "basic"),
    ("Le Bardo",       36.8096, 10.1345, "basic"),
    ("Sfax",           34.7400, 10.7600, "pro"),
    ("Sousse",         35.8254, 10.6360, "standard"),
    ("Bizerte",        37.2746,  9.8739, "basic"),
]

STREETS = [
    "Avenue Habib Bourguiba", "Rue de la République", "Avenue de la Liberté",
    "Rue de Carthage", "Avenue Mohamed V", "Rue de Marseille",
    "Avenue de Paris", "Rue Ibn Khaldoun", "Avenue Farhat Hached",
    "Boulevard du 7 Novembre", "Rue de Tunis", "Avenue de la Médina",
    "Rue Mongi Slim", "Avenue Hédi Nouira", "Boulevard de la Terre",
    "Rue Sidi Ben Arous", "Avenue du Président Bourguiba", "Rue des Orangers",
    "Avenue de l'Indépendance", "Rue Taïeb Mhiri", "Impasse du Jasmin",
    "Rue des Fleurs", "Avenue de la Mer", "Rue du Stade",
    "Boulevard Taieb Mhiri", "Rue Bab El Khadra", "Avenue Kheireddine",
    "Rue du 18 Janvier", "Avenue Ali Belhouane", "Rue Mustapha Khaznadar",
]

# ── people ────────────────────────────────────────────────────────────────────

STAFF_DATA = [
    # (name, email, role, password)
    ("Amin Ben Ali",       "amin@sahali.tn",        UserRole.admin,       "Admin1234!"),
    ("Sara Belhadj",       "sara@sahali.tn",         UserRole.supervisor,  "Staff1234!"),
    ("Omar Hammami",       "omar@sahali.tn",         UserRole.supervisor,  "Staff1234!"),
    ("Nour Khemiri",       "nour@sahali.tn",         UserRole.supervisor,  "Staff1234!"),
    ("Meriem Gara",        "meriem@sahali.tn",       UserRole.analyst,     "Staff1234!"),
    ("Bilel Chaabane",     "bilel@sahali.tn",        UserRole.analyst,     "Staff1234!"),
    ("Sami Mejri",         "sami@sahali.tn",         UserRole.field_agent, "Staff1234!"),
    ("Hana Trabelsi",      "hana@sahali.tn",         UserRole.field_agent, "Staff1234!"),
    ("Kais Dhouib",        "kais@sahali.tn",         UserRole.field_agent, "Staff1234!"),
    ("Youssef Ben Salem",  "youssef@sahali.tn",      UserRole.field_agent, "Staff1234!"),
    ("Fatma Karoui",       "fatma@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Ramzi Mansouri",     "ramzi@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Sonia Dahmani",      "sonia@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Tarek Ferchichi",    "tarek@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Ines Boughzala",     "ines@sahali.tn",         UserRole.field_agent, "Staff1234!"),
    ("Khalil Alouini",     "khalil@sahali.tn",       UserRole.field_agent, "Staff1234!"),
    ("Amira Jeridi",       "amira@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Riadh Zouari",       "riadh@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Dorra Baccouche",    "dorra@sahali.tn",        UserRole.field_agent, "Staff1234!"),
    ("Firas Oueslati",     "firas@sahali.tn",        UserRole.field_agent, "Staff1234!"),
]

CITIZEN_NAMES = [
    "Ahmed Ben Ali", "Fatma Trabelsi", "Mohamed Karoui", "Leila Mansouri",
    "Sami Dridi", "Hana Chabbi", "Youssef Jebali", "Mariem Belhaj",
    "Karim Ouali", "Nadia Sfar", "Taoufik Hamdi", "Amira Gharbi",
    "Bilel Rekik", "Sonia Ben Salah", "Riadh Ayari", "Ines Zouari",
    "Chokri Mbarki", "Dorra Abidi", "Nabil Hammami", "Wafa Souissi",
    "Lotfi Ben Fredj", "Sihem Cherif", "Hatem Turki", "Asma Jaziri",
    "Tarek Khlifi", "Olfa Hmida", "Slim Hidouri", "Raja Baccouche",
    "Fathi Nasri", "Chiraz Louati", "Nizar Belhassen", "Saoussen Dridi",
    "Mounir Elloumi", "Jihene Ben Khalifa", "Fethi Riahi", "Houda Mokni",
    "Walid Hamdi", "Dorsaf Ghariani", "Mondher Saidi", "Faiza Ferchichi",
    "Anouar Ben Moussa", "Najet Oueslati", "Habib Masri", "Hela Boukraa",
    "Zied Ghrairi", "Samira Khedher", "Lassaad Brahem", "Besma Labidi",
    "Ridha Mejri", "Nadia Ben Amor", "Salem Boughanmi", "Myriam Sassi",
    "Khaled Ben Romdhane", "Aida Maaloul", "Samir Abidi", "Radhia Hamza",
    "Naoufel Benyounes", "Hanen Chaieb", "Adel Trabelsi", "Emna Fakhfakh",
    "Kamel Ayadi", "Zaineb Riahi", "Othman Ben Yahia", "Mabrouka Chekir",
    "Foued Chouari", "Khadija Arfaoui", "Habib Ben Dhia", "Lobna Farhat",
    "Yacine Nefzaoui", "Raouia Sellami", "Hichem Gaied", "Fatou Diallo",
    "Khaoula Berrich", "Imed Jaziri", "Souad Boujemaa", "Bechir Gharbi",
    "Manel Saad", "Wissem Zghal", "Hela Dridi", "Jalel Ben Abdallah",
]

# ── report content ─────────────────────────────────────────────────────────

REPORT_TEMPLATES = [
    # (title, category_slug, priority, description)
    ("Nid-de-poule dangereux sur {street}", "infrastructure.pothole", "high",
     "Un nid-de-poule profond d'environ 30 cm de diamètre obstrue partiellement la voie. Plusieurs automobilistes ont déjà endommagé leurs véhicules. Une intervention urgente est nécessaire avant qu'un accident grave ne survienne."),
    ("Trottoir effondré au {n} {street}", "infrastructure.sidewalk", "medium",
     "Le trottoir s'est affaissé sur une longueur d'environ 2 mètres. Les personnes âgées et les personnes à mobilité réduite ne peuvent plus passer sans danger. Des travaux de réfection sont nécessaires."),
    ("Panneau de signalisation manquant {street}", "infrastructure.sign_missing", "medium",
     "Le panneau stop à l'intersection a disparu, probablement suite à un accident. La situation est dangereuse pour les usagers de la route qui ne savent plus qui a la priorité."),
    ("Panneau endommagé et illisible {street}", "infrastructure.sign_damaged", "low",
     "Le panneau de signalisation est tordu et son texte est devenu illisible suite à un choc. Il doit être remplacé pour assurer la sécurité des conducteurs."),
    ("Lampadaire en panne depuis {n} jours", "lighting.streetlight", "high",
     "Le lampadaire situé devant le numéro {n} {street} est en panne depuis plusieurs jours. La zone est plongée dans l'obscurité la nuit, créant un risque d'accident et d'insécurité pour les riverains."),
    ("Câble électrique pendant dangereusement", "lighting.exposed_wire", "critical",
     "Un câble électrique a été arraché et pend à hauteur d'homme au-dessus du trottoir. Il y a un risque d'électrocution immédiat. Une intervention d'urgence est requise sans délai."),
    ("Lampadaire allumé en permanence de jour", "lighting.streetlight", "low",
     "Le lampadaire de la rue reste allumé toute la journée, probablement à cause d'un dysfonctionnement du détecteur de lumière. Cela représente un gaspillage d'énergie notable."),
    ("Dépôt sauvage de déchets {street}", "waste.illegal_dump", "high",
     "Des déchets ont été déposés illégalement en dehors des conteneurs officiels. Le tas de déchets attire des nuisibles et dégage de mauvaises odeurs, nuisant à la qualité de vie des riverains."),
    ("Collecte des ordures non effectuée depuis {n} jours", "waste.garbage", "medium",
     "La collecte des ordures n'a pas été effectuée dans ce quartier depuis {n} jours. Les conteneurs débordent et les ordures se répandent sur le trottoir, créant des problèmes d'hygiène."),
    ("Conteneurs de tri débordants quartier {n}", "waste.overflow", "medium",
     "Les conteneurs de collecte sélective sont pleins à ras bord depuis plusieurs jours. Des sacs poubelles sont posés au sol à côté des bacs, attirant les nuisibles."),
    ("Fuite d'eau importante {street}", "water_sanitation.leak", "critical",
     "Une fuite d'eau sous pression jaillit du sol et inonde la chaussée. Le volume d'eau perdu est important et la chaussée commence à se creuser. Une coupure d'eau et une réparation d'urgence sont nécessaires."),
    ("Égout bouché causant inondations locales", "water_sanitation.sewage", "high",
     "L'égout de la rue est complètement bouché. Lors des dernières pluies, toute la rue a été inondée et les caves de plusieurs immeubles ont été envahies par les eaux usées. Le problème persiste."),
    ("Fuite eau sous-terrain visible en surface", "water_sanitation.leak", "high",
     "Une humidité suspecte est visible sur la chaussée et une légère odeur de chlore indique une fuite du réseau d'eau potable en sous-sol. Le sol commence à se ramollir."),
    ("Arbre mort menaçant de tomber", "environment.tree_cutting", "high",
     "Un grand arbre dont le tronc est visiblement mort et creusé menace de tomber sur la rue passante. En cas de vent fort, il pourrait causer de graves dégâts matériels ou blesser des passants."),
    ("Brûlage de déchets sauvage polluant l'air", "environment.air_pollution", "medium",
     "Des déchets sont régulièrement brûlés à ciel ouvert dans ce terrain vague. La fumée toxique se répand dans le quartier, causant des problèmes respiratoires chez les habitants, notamment les enfants."),
    ("Pollution visible dans le canal d'irrigation", "environment.water_pollution", "high",
     "Une substance huileuse et de couleur anormale flotte à la surface du canal. Des poissons morts ont été observés. La source de pollution semble être une entreprise proche. Intervention urgente requise."),
    ("Arrêt de bus vandalisé {street}", "transport.bus_stop", "low",
     "L'abri de l'arrêt de bus a été vandalisé : vitres brisées et banc arraché. Les usagers des transports en commun sont exposés aux intempéries. Un remplacement ou une réparation s'impose."),
    ("Feu de signalisation en panne intersection {n}", "transport.traffic_signal", "high",
     "Le feu de circulation à cette intersection importante est en panne depuis le matin. La circulation est chaotique et plusieurs quasi-accidents ont été observés. Un agent de circulation ou une réparation urgente est nécessaire."),
    ("Façade d'immeuble menaçant de s'effondrer", "safety.building", "critical",
     "Des morceaux de façade se détachent régulièrement d'un immeuble abandonné et tombent sur le trottoir. Un périmètre de sécurité doit être installé immédiatement avant qu'un passant ne soit blessé."),
    ("Zone dangereuse sans signalisation de sécurité", "safety.hazard", "high",
     "Des travaux ont été abandonnés laissant un grand trou ouvert sur le trottoir sans aucune signalisation ni protection. Plusieurs personnes ont failli tomber, notamment de nuit. Une intervention immédiate est requise."),
    ("Route dégradée après fortes pluies {street}", "infrastructure.pothole", "high",
     "Les dernières pluies ont considérablement dégradé la chaussée. De nombreux nids-de-poule sont apparus et la route est devenue dangereuse pour les deux-roues. Un rabotage et un reprofilage sont nécessaires."),
    ("Éclairage absent dans le passage piéton {n}", "lighting.streetlight", "medium",
     "Le passage piéton proche de l'école est plongé dans le noir après 18h car les lampadaires sont hors service. La sécurité des enfants qui rentrent le soir est sérieusement compromise."),
    ("Décharge sauvage près de l'école primaire", "waste.illegal_dump", "high",
     "Une décharge sauvage s'est constituée juste en face de l'école primaire. Les enfants sont exposés aux odeurs et aux risques sanitaires. Des mesures urgentes de nettoyage et de prévention sont nécessaires."),
    ("Canalisation cassée inondant la chaussée", "water_sanitation.leak", "critical",
     "Une conduite d'eau principale s'est rompue, créant une rivière sur la chaussée qui perturbe gravement la circulation et risque d'affaiblir les fondations des bâtiments environnants."),
    ("Trottoir effondré près du marché", "infrastructure.sidewalk", "high",
     "Le trottoir longeant le marché hebdomadaire s'est effondré sur une vingtaine de mètres, exposant des câbles et des conduites. Les piétons sont obligés de marcher sur la chaussée."),
    ("Arbre déraciné bloquant partiellement la voie", "environment.tree_cutting", "high",
     "Un grand arbre a été partiellement déraciné par la tempête et penche dangereusement au-dessus de la rue. La circulation est réduite à une voie. Une intervention rapide d'élagage ou d'abattage est nécessaire."),
    ("Pollution atmosphérique usine voisine", "environment.air_pollution", "medium",
     "Des émanations nauséabondes provenant d'une usine voisine empestent régulièrement le quartier en soirée. Les résidents souffrent de maux de tête et d'irritations des voies respiratoires. Une plainte a été déposée."),
    ("Arrêt de bus sans abri ni banc {n}", "transport.bus_stop", "low",
     "L'arrêt de bus le plus fréquenté de ce quartier ne dispose d'aucun abri ni banc. Les usagers, notamment les personnes âgées, sont exposés aux intempéries et ne peuvent pas s'asseoir pour attendre."),
    ("Intersection sans signalisation priorité", "infrastructure.sign_missing", "high",
     "Cette intersection à forte circulation est totalement dépourvue de signalisation. Les conducteurs ignorent les règles de priorité, ce qui engendre des conflits et des risques d'accidents quotidiens."),
    ("Bâtiment avec façade qui s'effrite", "safety.building", "medium",
     "La façade d'un immeuble des années 60 commence à montrer des signes de délabrement avancé : fissures profondes, morceaux de béton qui tombent. Un diagnostic structurel urgent est nécessaire."),
    ("Robinet de la fontaine publique cassé", "water_sanitation.leak", "medium",
     "La fontaine publique de la place coule en permanence car son robinet est cassé. Des litres d'eau potable sont gaspillés chaque jour. Une réparation simple suffirait à régler le problème."),
    ("Nid-de-poule en expansion rapide", "infrastructure.pothole", "critical",
     "Un nid-de-poule qui avait été signalé il y a deux mois s'est considérablement agrandi. Il mesure maintenant plus d'un mètre de diamètre et une voiture y a perdu une roue hier matin."),
    ("Trottoir obstrué par végétation non taillée", "environment.tree_cutting", "low",
     "Les branches des arbres plantés sur le trottoir ont poussé au point de bloquer complètement le passage des piétons. Les personnes avec poussettes ou fauteuils roulants ne peuvent plus passer."),
    ("Déversement suspects dans le wadi", "environment.water_pollution", "high",
     "Des camions-citernes déversent régulièrement leurs cuves dans le cours d'eau proche, de nuit. Les eaux ont pris une couleur anormale et une forte odeur se dégage. Une enquête est urgente."),
]

DESCRIPTIONS_SHORT = [
    "Signalé pour la deuxième fois ce mois-ci sans intervention.",
    "Problème visible depuis la voie publique, plusieurs voisins concernés.",
    "Des photos ont été jointes au signalement pour illustrer la situation.",
    "Des appels téléphoniques précédents n'ont pas abouti à une intervention.",
    "La situation s'aggrave de jour en jour, une action rapide est essentielle.",
    "Des résidents âgés du quartier sont particulièrement affectés.",
    "Le problème impacte la circulation quotidienne dans ce secteur.",
    "Plusieurs commerçants locaux ont signalé le même problème.",
]

# ── status flows ──────────────────────────────────────────────────────────────

STATUS_FLOWS = {
    "new":        (["submitted"],                                                              40),
    "received":   (["submitted", "received"],                                                  45),
    "review":     (["submitted", "received", "under_review"],                                  55),
    "scheduled":  (["submitted", "received", "under_review", "scheduled"],                     45),
    "inprogress": (["submitted", "received", "under_review", "scheduled", "in_progress"],      70),
    "resolved":   (["submitted", "received", "under_review", "scheduled", "in_progress", "resolved"], 220),
    "closed":     (["submitted", "received", "under_review", "scheduled", "in_progress", "resolved", "closed"], 80),
    "rejected":   (["submitted", "rejected"],                                                  45),
    "rejected2":  (["submitted", "received", "under_review", "rejected"],                      25),
    "stalled":    (["submitted", "received", "under_review", "scheduled"],                     25),
}
# Total: 40+45+55+45+70+220+80+45+25+25 = 650

# ── main ─────────────────────────────────────────────────────────────────────

def main():
    db = SessionLocal()
    try:
        print("🗑  Clearing existing data...")
        db.execute(sa.text(
            "TRUNCATE notifications, report_status_history, reports, users, "
            "categories, departments, municipalities RESTART IDENTITY CASCADE"
        ))
        db.commit()

        # ── municipalities ──────────────────────────────────────────────────
        print("🏙  Creating municipalities...")
        city_to_muni_id: dict[str, int] = {}
        for name, _lat, _lng, tier in CITIES:
            db.execute(sa.text(
                "INSERT INTO municipalities (name, subscription_tier) VALUES (:n, :t)"
            ), {"n": name, "t": tier})
        db.commit()
        for name, *_ in CITIES:
            row = db.execute(sa.text("SELECT id FROM municipalities WHERE name=:n"), {"n": name}).fetchone()
            city_to_muni_id[name] = row[0]

        # ── departments ──────────────────────────────────────────────────────
        print("🏢  Creating departments...")
        dept_map: dict[int, int] = {}
        for name, mid in city_to_muni_id.items():
            db.execute(sa.text(
                "INSERT INTO departments (municipality_id, name) VALUES (:m, 'Services Techniques')"
            ), {"m": mid})
            db.commit()
            row = db.execute(sa.text("SELECT id FROM departments WHERE municipality_id=:m"), {"m": mid}).fetchone()
            dept_map[mid] = row[0]

        # ── categories ───────────────────────────────────────────────────────
        print("🏷  Creating categories...")
        CAT_ROWS = [
            ("infrastructure",              "البنية التحتية",                "Infrastructure",                    "Infrastructure",              None,                168, "road"),
            ("infrastructure.pothole",      "حفرة في الطريق",               "Nid-de-poule",                      "Road pothole",                "infrastructure",   168, "construction"),
            ("infrastructure.sidewalk",     "رصيف تالف",                    "Trottoir endommagé",                "Damaged sidewalk",            "infrastructure",   168, "directions_walk"),
            ("infrastructure.sign_missing", "لافتة مفقودة",                  "Panneau manquant",                  "Missing road sign",           "infrastructure",   168, "signpost"),
            ("infrastructure.sign_damaged", "لافتة تالفة",                   "Panneau endommagé",                 "Damaged road sign",           "infrastructure",   168, "signpost"),
            ("lighting",                    "الإنارة العامة",                "Éclairage public",                  "Public Lighting",             None,                72, "lightbulb"),
            ("lighting.streetlight",        "عطل مصباح الشارع",             "Lampadaire défectueux",             "Faulty streetlight",          "lighting",          72, "light"),
            ("lighting.exposed_wire",       "أسلاك كهربائية مكشوفة",        "Fils électriques exposés",          "Exposed wires",               "lighting",          24, "bolt"),
            ("waste",                       "النظافة والنفايات",            "Propreté et déchets",               "Cleanliness & Waste",         None,               168, "delete"),
            ("waste.illegal_dump",          "إلقاء غير قانوني",             "Dépôt sauvage",                     "Illegal dumping",             "waste",            168, "delete_forever"),
            ("waste.garbage",               "تراكم القمامة",                 "Déchets accumulés",                 "Accumulated garbage",         "waste",            168, "recycling"),
            ("waste.overflow",              "حاويات ممتلئة",                 "Conteneurs débordants",             "Overflowing containers",      "waste",            168, "inventory_2"),
            ("environment",                 "البيئة",                        "Environnement",                     "Environment",                 None,               336, "park"),
            ("environment.water_pollution", "تلوث المياه",                   "Pollution de l'eau",                "Water pollution",             "environment",      336, "water"),
            ("environment.air_pollution",   "تلوث الهواء",                   "Pollution atmosphérique",           "Air pollution",               "environment",      336, "air"),
            ("environment.tree_cutting",    "قطع أشجار",                     "Arbre dangereux/abattage",          "Dangerous tree",              "environment",      336, "nature"),
            ("water_sanitation",            "المياه والصرف الصحي",          "Eau et assainissement",             "Water & Sanitation",          None,                48, "water_drop"),
            ("water_sanitation.leak",       "تسرب المياه",                   "Fuite d'eau",                       "Water leak",                  "water_sanitation",  48, "plumbing"),
            ("water_sanitation.sewage",     "انسداد الصرف الصحي",           "Égout bouché",                      "Blocked sewage",              "water_sanitation",  48, "drain"),
            ("transport",                   "النقل",                         "Transport",                         "Transportation",              None,               168, "directions_bus"),
            ("transport.bus_stop",          "محطة حافلات",                   "Arrêt de bus endommagé",            "Damaged bus stop",            "transport",        168, "bus_alert"),
            ("transport.traffic_signal",    "إشارة مرور",                    "Feu de circulation en panne",       "Traffic signal fault",        "transport",         24, "traffic"),
            ("safety",                      "السلامة والأمن",                "Sécurité",                          "Safety & Security",           None,                24, "shield"),
            ("safety.building",             "مبنى غير آمن",                 "Bâtiment dangereux",                "Unsafe building",             "safety",            24, "apartment"),
            ("safety.hazard",               "خطر عام",                       "Danger public",                     "Public hazard",               "safety",            24, "warning"),
        ]
        slug_to_id: dict[str, int] = {}
        tunis_dept = dept_map[city_to_muni_id["Tunis"]]
        for slug, ar, fr, en, parent_slug, sla, icon in CAT_ROWS:
            parent_id = slug_to_id.get(parent_slug) if parent_slug else None
            row = db.execute(sa.text("""
                INSERT INTO categories (slug, label_ar, label_fr, label_en, parent_id, sla_hours, icon, default_department_id)
                VALUES (:slug, :ar, :fr, :en, :par, :sla, :icon, :dept) RETURNING id
            """), dict(slug=slug, ar=ar, fr=fr, en=en, par=parent_id, sla=sla, icon=icon, dept=tunis_dept))
            slug_to_id[slug] = row.scalar()
        db.commit()

        # ── staff ────────────────────────────────────────────────────────────
        print("👷  Creating staff...")
        staff_ids: list[uuid.UUID] = []
        agent_ids: list[uuid.UUID] = []
        supervisor_ids: list[uuid.UUID] = []
        tunis_mid = city_to_muni_id["Tunis"]
        marsa_mid = city_to_muni_id["La Marsa"]

        city_names = list(city_to_muni_id.keys())
        for i, (name, email, role, pwd) in enumerate(STAFF_DATA):
            uid = uuid.uuid4()
            # distribute agents across municipalities
            muni = tunis_mid if role in (UserRole.admin, UserRole.supervisor, UserRole.analyst) else city_to_muni_id[city_names[i % len(city_names)]]
            db.add(User(
                id=uid, full_name=name, email=email,
                password_hash=hash_password(pwd),
                role=role, municipality_id=muni,
                preferred_language="fr", is_active=True,
            ))
            staff_ids.append(uid)
            if role == UserRole.field_agent:
                agent_ids.append(uid)
            if role == UserRole.supervisor:
                supervisor_ids.append(uid)
        db.commit()
        print(f"   {len(staff_ids)} staff, {len(agent_ids)} field agents")

        # ── citizens ─────────────────────────────────────────────────────────
        print("👥  Creating citizens...")
        citizen_ids: list[uuid.UUID] = []
        for i, name in enumerate(CITIZEN_NAMES):
            uid = uuid.uuid4()
            slug = name.lower().replace(" ", ".").replace("'", "").replace("é", "e").replace("ï", "i")
            muni = city_to_muni_id[city_names[i % len(city_names)]]
            db.add(User(
                id=uid, full_name=name,
                email=f"{slug}@citoyens.tn",
                phone=f"+21{random.randint(620000000, 699999999)}",
                password_hash=hash_password("Citoyen1234!"),
                role=UserRole.citizen, municipality_id=muni,
                preferred_language=random.choice(["fr", "ar"]),
                is_active=True,
            ))
            citizen_ids.append(uid)
        db.commit()
        print(f"   {len(citizen_ids)} citizens")

        # ── leaf categories ───────────────────────────────────────────────────
        leaf_slugs = [s for s in slug_to_id if "." in s]
        template_by_slug = {t[1]: t for t in REPORT_TEMPLATES}

        # ── reports ──────────────────────────────────────────────────────────
        print("📋  Creating reports...")
        total_created = 0
        changer_pool = staff_ids[:6]  # admin + supervisors + analysts change statuses

        for flow_key, (flow_steps, count) in STATUS_FLOWS.items():
            final_status = flow_steps[-1]

            # age range per flow: newer = earlier statuses
            age_ranges = {
                "new": (0, 3), "received": (1, 7), "review": (3, 14),
                "scheduled": (5, 20), "inprogress": (7, 30),
                "resolved": (14, 75), "closed": (30, 90),
                "rejected": (1, 30), "rejected2": (5, 30), "stalled": (10, 40),
            }
            min_age, max_age = age_ranges.get(flow_key, (1, 60))

            for _ in range(count):
                city_name, base_lat, base_lng, _ = random.choice(CITIES)
                street = random.choice(STREETS)
                n = random.randint(1, 120)

                tpl = random.choice(REPORT_TEMPLATES)
                title = tpl[0].format(street=street, n=n)
                cat_slug = tpl[1]
                priority = tpl[2]
                base_desc = tpl[3].format(street=street, n=n) if "{" in tpl[3] else tpl[3]
                extra = random.choice(DESCRIPTIONS_SHORT)
                desc = f"{base_desc} {extra}"

                jlat = base_lat + random.uniform(-0.035, 0.035)
                jlng = base_lng + random.uniform(-0.035, 0.035)

                # clamp to Tunisia bounding box
                jlat = max(34.5, min(37.5, jlat))
                jlng = max(9.0, min(11.5, jlng))

                created = rand_dt(min_age, max_age)
                resolved_at = None
                if final_status in ("resolved", "closed"):
                    resolved_at = created + timedelta(hours=random.randint(8, 96))

                # agents get assigned at scheduled/in_progress stages
                assigned_agent = None
                if final_status not in ("submitted", "received", "rejected"):
                    assigned_agent = random.choice(agent_ids)

                rid = uuid.uuid4()
                citizen_id = random.choice(citizen_ids)
                cat_id = slug_to_id[cat_slug]

                db.execute(sa.text("""
                    INSERT INTO reports (
                        id, tracking_code, citizen_id, category_id, status,
                        title, description, address, city,
                        location, priority, assigned_to, is_duplicate,
                        resolved_at, created_at, updated_at
                    ) VALUES (
                        :id, :code, :citizen, :cat, :status,
                        :title, :desc, :addr, :city,
                        ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
                        :priority, :agent, false,
                        :resolved_at, :created_at, :created_at
                    )
                """), {
                    "id": rid, "code": tracking_code(),
                    "citizen": citizen_id, "cat": cat_id, "status": final_status,
                    "title": title, "desc": desc,
                    "addr": f"{n} {street}", "city": city_name,
                    "lat": jlat, "lng": jlng,
                    "priority": priority, "agent": assigned_agent,
                    "resolved_at": resolved_at, "created_at": created,
                })

                # status history
                prev = None
                for step_i, step_status in enumerate(flow_steps):
                    step_ts = created + timedelta(hours=step_i * random.randint(3, 36))
                    changed_by = random.choice(changer_pool)
                    db.execute(sa.text("""
                        INSERT INTO report_status_history
                            (id, report_id, from_status, to_status, changed_by, note, created_at)
                        VALUES (:id, :rid, :from_s, :to_s, :by, :note, :ts)
                    """), {
                        "id": uuid.uuid4(), "rid": rid,
                        "from_s": prev, "to_s": step_status,
                        "by": changed_by,
                        "note": random.choice([None, None, None, "Vérifié sur place.", "Transmis au service compétent.", "Intervention planifiée."]),
                        "ts": step_ts,
                    })
                    prev = step_status

                # citizen notification for resolved reports
                if final_status in ("resolved", "closed"):
                    db.execute(sa.text("""
                        INSERT INTO notifications (id, user_id, report_id, title, body, is_read, created_at)
                        VALUES (:id, :uid, :rid, :title, :body, :read, :ts)
                    """), {
                        "id": uuid.uuid4(), "uid": citizen_id, "rid": rid,
                        "title": "Votre signalement a été résolu ✓",
                        "body": f"Le problème «{title[:70]}» a été pris en charge et résolu par nos équipes. Merci pour votre signalement.",
                        "read": random.random() > 0.35,
                        "ts": resolved_at or created + timedelta(hours=48),
                    })

                total_created += 1

        db.commit()
        print(f"   {total_created} reports created")

        # ── staff notifications ───────────────────────────────────────────────
        print("🔔  Creating staff notifications...")
        STAFF_NOTIFS = [
            ("Rapport hebdomadaire disponible",       "Le rapport de performance de cette semaine est prêt. Taux de résolution global: 84%. 3 signalements critiques en attente."),
            ("⚠️ 8 signalements critiques non traités","Des signalements de priorité critique attendent une intervention depuis plus de 24h. Merci de vérifier la liste des urgences."),
            ("Maintenance système — ce soir 23h-1h",  "Une mise à jour système est planifiée ce soir entre 23h et 1h du matin. L'accès sera temporairement interrompu."),
            ("Objectif SLA dépassé ce mois 🎉",        "Félicitations à l'équipe ! Nous avons atteint 91% de résolution dans les délais SLA ce mois-ci, dépassant notre objectif de 85%."),
            ("Nouvelle zone prioritaire : Bab El Khadra", "Suite aux remontées citoyennes, le secteur Bab El Khadra a été désigné zone prioritaire pour ce trimestre."),
            ("Réunion d'équipe — demain 9h",           "Rappel : réunion d'équipe mensuelle demain matin à 9h en salle de réunion principale. Ordre du jour envoyé par email."),
            ("Formation sécurité routière — inscription", "Une formation sur les normes de sécurité routière est organisée le mois prochain. Les inscriptions sont ouvertes jusqu'au 30 du mois."),
            ("3 nouveaux agents affectés à Sfax",      "3 agents terrain supplémentaires ont rejoint l'équipe de Sfax pour renforcer la couverture de cette zone à forte densité."),
            ("Rapport mensuel — chiffres clés",        "Résumé du mois : 650 signalements reçus, 84% traités dans les délais, 12h de délai moyen de résolution. Détails disponibles dans le tableau de bord."),
            ("Alerte météo — préparer les équipes",    "Des pluies importantes sont annoncées pour la semaine prochaine. Anticipez une hausse des signalements liés aux inondations et à la voirie."),
        ]
        for staff_uid in staff_ids:
            k = random.randint(3, 6)
            for title, body in random.sample(STAFF_NOTIFS, k=min(k, len(STAFF_NOTIFS))):
                db.execute(sa.text("""
                    INSERT INTO notifications (id, user_id, title, body, is_read, created_at)
                    VALUES (:id, :uid, :title, :body, :read, :ts)
                """), {
                    "id": uuid.uuid4(), "uid": staff_uid,
                    "title": title, "body": body,
                    "read": random.random() > 0.45,
                    "ts": rand_dt(0, 21),
                })
        db.commit()

        # ── summary ──────────────────────────────────────────────────────────
        totals = db.execute(sa.text(
            "SELECT status, COUNT(*) FROM reports GROUP BY status ORDER BY COUNT(*) DESC"
        )).fetchall()

        print("\n" + "="*50)
        print("  ✅  SEED COMPLETE")
        print("="*50)
        print(f"  Municipalités : {len(CITIES)}")
        print(f"  Staff         : {len(STAFF_DATA)}  ({len(agent_ids)} agents terrain)")
        print(f"  Citoyens      : {len(CITIZEN_NAMES)}")
        print(f"  Signalements  : {total_created}")
        print("\n  Répartition par statut:")
        for row in totals:
            bar = "█" * (row[1] // 10)
            print(f"    {row[0]:<18} {row[1]:>4}  {bar}")
        print("\n  Identifiants de connexion:")
        print("    Admin      : amin@sahali.tn      / Admin1234!")
        print("    Superviseur: sara@sahali.tn      / Staff1234!")
        print("    Analyste   : meriem@sahali.tn    / Staff1234!")
        print("    Agent      : sami@sahali.tn      / Staff1234!")
        print("="*50)

    finally:
        db.close()


if __name__ == "__main__":
    main()
