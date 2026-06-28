"""Demo seed — staff users, citizens, reports across all statuses

Revision ID: 0004
Revises: 0003
Create Date: 2026-06-28
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# All demo users share this password
DEMO_PASSWORD = "Demo1234!"


def _hash(password: str) -> str:
    from passlib.context import CryptContext
    return CryptContext(schemes=["bcrypt"], deprecated="auto").hash(password)


def upgrade() -> None:
    import uuid as _uuid

    conn = op.get_bind()
    pw = _hash(DEMO_PASSWORD)

    # ── Resolve seed data from 0002 ──────────────────────────────────────────
    muni_id = conn.execute(sa.text(
        "SELECT id FROM municipalities WHERE name='Tunis'"
    )).scalar()
    dept_id = conn.execute(sa.text(
        "SELECT id FROM departments WHERE municipality_id=:m"
    ), {"m": muni_id}).scalar()

    def cat(slug: str) -> int:
        return conn.execute(
            sa.text("SELECT id FROM categories WHERE slug=:s"), {"s": slug}
        ).scalar()

    cat_pothole   = cat("infrastructure.pothole")
    cat_sidewalk  = cat("infrastructure.sidewalk")
    cat_light     = cat("lighting.streetlight")
    cat_wire      = cat("lighting.exposed_wire")
    cat_dump      = cat("waste.illegal_dump")
    cat_garbage   = cat("waste.garbage")
    cat_leak      = cat("water_sanitation.leak")
    cat_sewage    = cat("water_sanitation.sewage")
    cat_bus       = cat("transport.bus_stop")
    cat_traffic   = cat("transport.traffic_signal")
    cat_hazard    = cat("safety.hazard")
    cat_sign      = cat("infrastructure.sign_missing")

    # ── Staff users ──────────────────────────────────────────────────────────
    def staff(role: str, full_name: str, email: str) -> str:
        uid = str(_uuid.uuid4())
        conn.execute(sa.text("""
            INSERT INTO users (id, role, full_name, email, password_hash,
                               municipality_id, preferred_language, is_active)
            VALUES (:id, :role, :name, :email, :pw, :muni, 'fr', true)
        """), {"id": uid, "role": role, "name": full_name,
               "email": email, "pw": pw, "muni": muni_id})
        return uid

    admin_id    = staff("admin",       "Khalil Bensaid",    "admin@sahali.tn")
    sup_id      = staff("supervisor",  "Fatma Mansouri",    "fatma@sahali.tn")
    analyst1_id = staff("analyst",     "Sami Mejri",        "sami@sahali.tn")
    analyst2_id = staff("analyst",     "Mohamed Ghazouani", "ghazouani@sahali.tn")
    agent1_id   = staff("field_agent", "Hana Trabelsi",     "hana@sahali.tn")
    agent2_id   = staff("field_agent", "Kais Dhouib",       "kais@sahali.tn")
    agent3_id   = staff("field_agent", "Meriem Gara",       "meriem@sahali.tn")
    agent4_id   = staff("field_agent", "Youssef Ben Salem", "youssef@sahali.tn")

    # ── Citizens ─────────────────────────────────────────────────────────────
    def citizen(full_name: str, phone: str) -> str:
        uid = str(_uuid.uuid4())
        conn.execute(sa.text("""
            INSERT INTO users (id, role, full_name, phone, municipality_id,
                               preferred_language, is_active)
            VALUES (:id, 'citizen', :name, :phone, :muni, 'fr', true)
        """), {"id": uid, "name": full_name, "phone": phone, "muni": muni_id})
        return uid

    cit1 = citizen("Rania Hammami",    "+21620111001")
    cit2 = citizen("Tarek Maaloul",    "+21620111002")
    cit3 = citizen("Ines Jelassi",     "+21620111003")
    cit4 = citizen("Hatem Zouari",     "+21620111004")
    cit5 = citizen("Sabrina Baccar",   "+21620111005")

    # ── Report helper ────────────────────────────────────────────────────────
    # points: (lng, lat) for PostGIS POINT(lng lat)
    LOCATIONS = {
        "la_marsa":    (10.3239,  36.8792),
        "ariana":      (10.1956,  36.8625),
        "carthage":    (10.3277,  36.8523),
        "la_goulette": (10.3054,  36.8186),
        "tunis":       (10.1815,  36.8065),
        "el_manar":    (10.2100,  36.8340),
        "sidi_bou":    (10.3481,  36.8688),
    }

    def report(code: str, title: str, citizen_id: str, cat_id: int,
               status: str, loc: str, city: str, address: str,
               description: str, priority: str,
               analyzed_by: str | None = None,
               assigned_to: str | None = None,
               days_ago_created: int = 7) -> str:
        rid = str(_uuid.uuid4())
        lng, lat = LOCATIONS[loc]
        conn.execute(sa.text("""
            INSERT INTO reports (id, tracking_code, citizen_id, category_id, status,
                title, description, location, address, city, priority,
                analyzed_by, assigned_to, department_id,
                created_at, updated_at)
            VALUES (
                :id, :code, :cit, :cat, CAST(:status AS reportstatus),
                :title, :desc,
                ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
                :address, :city, CAST(:priority AS reportpriority),
                :analyzed_by, :assigned_to, :dept,
                now() - (:days || ' days')::interval,
                now() - (:days || ' days')::interval
            )
        """), {
            "id": rid, "code": code, "cit": citizen_id, "cat": cat_id,
            "status": status, "title": title, "desc": description,
            "lng": lng, "lat": lat, "address": address, "city": city,
            "priority": priority, "analyzed_by": analyzed_by,
            "assigned_to": assigned_to, "dept": dept_id,
            "days": days_ago_created,
        })
        return rid

    def history(report_id: str, from_status: str | None, to_status: str,
                changed_by: str, note: str | None, days_ago: float) -> None:
        conn.execute(sa.text("""
            INSERT INTO report_status_history
                (id, report_id, from_status, to_status, changed_by, note, created_at)
            VALUES (
                gen_random_uuid(), :rid,
                CAST(:from_s AS reportstatus),
                CAST(:to_s AS reportstatus),
                :changed_by, :note,
                now() - (:days || ' days')::interval
            )
        """), {
            "rid": report_id,
            "from_s": from_status,
            "to_s": to_status,
            "changed_by": changed_by,
            "note": note,
            "days": days_ago,
        })

    def assign(report_id: str, agent_id: str, assigned_by: str,
               note: str | None, days_ago: float, is_active: bool = True) -> str:
        aid = str(_uuid.uuid4())
        conn.execute(sa.text("""
            INSERT INTO assignments (id, report_id, agent_id, assigned_by,
                note, is_active, created_at)
            VALUES (:id, :rid, :agent, :by, :note, :active,
                    now() - (:days || ' days')::interval)
        """), {
            "id": aid, "rid": report_id, "agent": agent_id,
            "by": assigned_by, "note": note, "active": is_active, "days": days_ago,
        })
        return aid

    def resolve(report_id: str, resolved_by: str, comment: str,
                materials: str | None, days_ago: float) -> None:
        conn.execute(sa.text("""
            INSERT INTO resolution_reports (id, report_id, resolved_by,
                comment, materials, created_at)
            VALUES (gen_random_uuid(), :rid, :by, :comment, :materials,
                    now() - (:days || ' days')::interval)
        """), {
            "rid": report_id, "by": resolved_by,
            "comment": comment, "materials": materials, "days": days_ago,
        })
        conn.execute(sa.text("""
            UPDATE reports SET resolved_at = now() - (:days || ' days')::interval
            WHERE id = :rid
        """), {"rid": report_id, "days": days_ago})

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # RESOLVED reports
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    r1 = report("SA-00001", "Nid-de-poule dangereux avenue Taïeb Mhiri",
                cit1, cat_pothole, "resolved", "la_marsa", "La Marsa",
                "Av. Taïeb Mhiri, La Marsa",
                "Nid-de-poule de 40 cm de diamètre et 10 cm de profondeur, très dangereux pour les deux-roues.",
                "high", analyzed_by=analyst1_id, assigned_to=agent1_id, days_ago_created=14)
    history(r1, None,          "submitted",   cit1,      None, 14)
    history(r1, "submitted",   "received",    sup_id,    None, 13)
    history(r1, "received",    "under_review",analyst1_id, None, 12)
    history(r1, "under_review","in_progress", sup_id,    "Assigné à Hana Trabelsi", 10)
    history(r1, "in_progress", "resolved",    agent1_id, "Travaux terminés", 5)
    assign(r1, agent1_id, sup_id, "Intervention urgente", 10)
    assign(r1, agent2_id, sup_id, "Support pour coulage béton", 10)
    resolve(r1, agent1_id,
            "Comblage du nid-de-poule avec béton bitumineux chaud. Surface reprofilée et compactée. Zone sécurisée pendant 24h.",
            "2 m³ béton bitumineux, 1 rouleau compacteur, 6 cônes de signalisation", 5)

    r2 = report("SA-00002", "Lampadaire défectueux rue Ibn Khaldoun",
                cit2, cat_light, "resolved", "ariana", "Ariana",
                "Rue Ibn Khaldoun, Ariana",
                "Lampadaire éteint depuis 5 jours, zone très sombre la nuit, risque pour les piétons.",
                "medium", analyzed_by=analyst2_id, assigned_to=agent3_id, days_ago_created=12)
    history(r2, None,          "submitted",   cit2,      None, 12)
    history(r2, "submitted",   "received",    sup_id,    None, 11)
    history(r2, "received",    "under_review",analyst2_id, None, 10)
    history(r2, "under_review","in_progress", sup_id,    "Assigné pour remplacement ampoule", 8)
    history(r2, "in_progress", "resolved",    agent3_id, "Remplacement effectué", 3)
    assign(r2, agent3_id, sup_id, None, 8)
    resolve(r2, agent3_id,
            "Remplacement de la lampe sodium haute pression (150W). Armoire électrique vérifiée. Fonctionnement normal rétabli.",
            "1 lampe HPS 150W, 1 starter, outillage électrique", 3)

    r3 = report("SA-00003", "Fuite d'eau importante carrefour Salammbô",
                cit3, cat_leak, "resolved", "carthage", "Carthage",
                "Carrefour Salammbô / Rue de Carthage",
                "Fuite importante sur conduite principale, eau qui jaillit et inonde la chaussée.",
                "critical", analyzed_by=analyst1_id, assigned_to=agent2_id, days_ago_created=11)
    history(r3, None,          "submitted",   cit3,      None, 11)
    history(r3, "submitted",   "received",    sup_id,    None, 10)
    history(r3, "received",    "under_review",analyst1_id, None, 9)
    history(r3, "under_review","in_progress", sup_id,    "Urgence — équipe dépêchée", 7)
    history(r3, "in_progress", "resolved",    agent2_id, "Réparation terminée", 2)
    assign(r3, agent2_id, sup_id, "Priorité maximale", 7)
    assign(r3, agent4_id, sup_id, "Renfort manœuvre", 7)
    resolve(r3, agent2_id,
            "Isolation de la conduite principale, remplacement du joint défectueux DN150. Remblaiement et réfection de la chaussée sur 2m².",
            "1 joint EPDM DN150, béton de ciment 0.5m³, plaques de blindage", 2)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # IN_PROGRESS reports
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    r4 = report("SA-00004", "Dépôt sauvage derrière le marché municipal",
                cit4, cat_dump, "in_progress", "la_marsa", "La Marsa",
                "Derrière marché municipal La Marsa",
                "Accumulation importante de déchets ménagers et encombrants derrière le marché. Risque sanitaire.",
                "high", analyzed_by=analyst2_id, assigned_to=agent1_id, days_ago_created=8)
    history(r4, None,          "submitted",   cit4,      None, 8)
    history(r4, "submitted",   "received",    sup_id,    None, 7)
    history(r4, "received",    "under_review",analyst2_id, None, 5)
    history(r4, "under_review","in_progress", sup_id,    "Équipe propreté mobilisée", 3)
    assign(r4, agent1_id, sup_id, "Responsable équipe nettoyage", 3)
    assign(r4, agent3_id, sup_id, "Support logistique", 3)

    r5 = report("SA-00005", "Trottoir effondré rue de Sidi Bou Saïd",
                cit5, cat_sidewalk, "in_progress", "sidi_bou", "Sidi Bou Saïd",
                "Rue Habib Thameur, Sidi Bou Saïd",
                "Section de trottoir effondrée sur 3m, dalle cassée, risque de chute notamment pour personnes âgées.",
                "high", analyzed_by=analyst1_id, assigned_to=agent2_id, days_ago_created=7)
    history(r5, None,          "submitted",   cit5,      None, 7)
    history(r5, "submitted",   "received",    sup_id,    None, 6)
    history(r5, "received",    "under_review",analyst1_id, None, 4)
    history(r5, "under_review","in_progress", sup_id,    "Assigné équipe voirie", 2)
    assign(r5, agent2_id, sup_id, None, 2)

    r6 = report("SA-00006", "Panneau de signalisation manquant carrefour El Manar",
                cit1, cat_sign, "in_progress", "el_manar", "El Manar",
                "Carrefour bd El Manar / rue 8010",
                "Panneau STOP manquant à un carrefour sans visibilité. Plusieurs accidents failli se produire.",
                "critical", analyzed_by=analyst2_id, assigned_to=agent4_id, days_ago_created=6)
    history(r6, None,          "submitted",   cit1,      None, 6)
    history(r6, "submitted",   "received",    sup_id,    None, 5)
    history(r6, "received",    "under_review",analyst2_id, "Urgence sécurité routière", 3)
    history(r6, "under_review","in_progress", sup_id,    None, 1)
    assign(r6, agent4_id, sup_id, "Pose panneau STOP urgente", 1)

    r7 = report("SA-00007", "Feux tricolores hors service avenue Bourguiba",
                cit2, cat_traffic, "in_progress", "tunis", "Tunis",
                "Av. Habib Bourguiba, Tunis",
                "Feux tricolores en panne depuis ce matin, circulation chaotique, risque d'accidents.",
                "critical", analyzed_by=analyst1_id, assigned_to=agent1_id, days_ago_created=5)
    history(r7, None,          "submitted",   cit2,      None, 5)
    history(r7, "submitted",   "received",    sup_id,    None, 4)
    history(r7, "received",    "under_review",analyst1_id, None, 3)
    history(r7, "under_review","in_progress", sup_id,    "Technicien signalisation mobilisé", 1)
    assign(r7, agent1_id, sup_id, "Intervention prioritaire", 1)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # UNDER_REVIEW reports
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    r8 = report("SA-00008", "Câbles électriques dénudés au sol rue Pasteur",
                cit3, cat_wire, "under_review", "ariana", "Ariana",
                "Rue Pasteur, Ariana",
                "Câbles électriques tombés au sol suite à une tempête de vent, très dangereux.",
                "critical", analyzed_by=analyst2_id, days_ago_created=5)
    history(r8, None,        "submitted",   cit3, None, 5)
    history(r8, "submitted", "received",    sup_id, None, 4)
    history(r8, "received",  "under_review",analyst2_id, "Signalement urgent — sécurité électrique", 2)

    r9 = report("SA-00009", "Arbre menaçant de tomber avenue de la Liberté",
                cit4, cat_hazard, "under_review", "tunis", "Tunis",
                "Av. de la Liberté, Tunis",
                "Grand arbre penché dangereusement au-dessus de la voie publique après les dernières pluies.",
                "high", analyzed_by=analyst1_id, days_ago_created=4)
    history(r9, None,        "submitted",   cit4, None, 4)
    history(r9, "submitted", "received",    sup_id, None, 3)
    history(r9, "received",  "under_review",analyst1_id, None, 1)

    r10 = report("SA-00010", "Égout bouché rue de la Médina",
                 cit5, cat_sewage, "under_review", "la_goulette", "La Goulette",
                 "Rue de la Médina, La Goulette",
                 "Égout bouché, eaux usées qui débordent sur le trottoir, odeurs nauséabondes.",
                 "high", analyzed_by=analyst2_id, days_ago_created=3)
    history(r10, None,       "submitted",   cit5, None, 3)
    history(r10, "submitted","received",    sup_id, None, 2)
    history(r10, "received", "under_review",analyst2_id, None, 0.5)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # RECEIVED reports
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    r11 = report("SA-00011", "Accumulation de déchets non collectés résidence Ennasr",
                 cit1, cat_garbage, "received", "ariana", "Ariana",
                 "Résidence Ennasr II, Ariana",
                 "Les bacs à ordures n'ont pas été vidés depuis 4 jours, débordement sur la voie publique.",
                 "medium", days_ago_created=3)
    history(r11, None,       "submitted", cit1, None, 3)
    history(r11, "submitted","received",  sup_id, None, 2)

    r12 = report("SA-00012", "Éclairage public éteint dans le parc de La Marsa",
                 cit2, cat_light, "received", "la_marsa", "La Marsa",
                 "Parc municipal de La Marsa",
                 "Plusieurs lampadaires du parc sont hors service, le parc est complètement sombre la nuit.",
                 "medium", days_ago_created=2)
    history(r12, None,       "submitted", cit2, None, 2)
    history(r12, "submitted","received",  sup_id, None, 1)

    r13 = report("SA-00013", "Nid-de-poule chaussée boulevard El Manar",
                 cit3, cat_pothole, "received", "el_manar", "El Manar",
                 "Bd El Manar II, El Manar",
                 "Plusieurs nids-de-poule sur 20m de chaussée, endommagent les véhicules.",
                 "medium", days_ago_created=2)
    history(r13, None,       "submitted", cit3, None, 2)
    history(r13, "submitted","received",  sup_id, None, 0.5)

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # REJECTED reports
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    r14 = report("SA-00014", "Litige avec propriétaire pour clôture abîmée",
                 cit4, cat_hazard, "rejected", "la_marsa", "La Marsa",
                 "Rue des Orangers, La Marsa",
                 "La clôture de mon voisin est tombée sur mon terrain. Je voudrais que la mairie intervienne.",
                 "low", days_ago_created=7)
    history(r14, None,        "submitted", cit4, None, 7)
    history(r14, "submitted", "received",  sup_id, None, 6)
    history(r14, "received",  "rejected",  analyst1_id,
            "Ce litige relève du droit privé et non de la compétence de la municipalité. Veuillez vous adresser au tribunal.", 5)

    r15 = report("SA-00015", "Demande d'éclairage supplémentaire parking privé",
                 cit5, cat_light, "rejected", "ariana", "Ariana",
                 "Parking résidence Les Pins, Ariana",
                 "Le parking de notre résidence privée est insuffisamment éclairé la nuit.",
                 "low", analyzed_by=analyst2_id, days_ago_created=5)
    history(r15, None,          "submitted",   cit5, None, 5)
    history(r15, "submitted",   "received",    sup_id, None, 4)
    history(r15, "received",    "under_review",analyst2_id, None, 3)
    history(r15, "under_review","rejected",    analyst2_id,
            "Cette propriété est privée. L'éclairage interne d'un parking privé ne relève pas du domaine public municipal.", 2)


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text("DELETE FROM resolution_reports"))
    conn.execute(sa.text("DELETE FROM assignments"))
    conn.execute(sa.text("DELETE FROM report_status_history"))
    conn.execute(sa.text("DELETE FROM reports"))
    conn.execute(sa.text(
        "DELETE FROM users WHERE role IN ('admin','supervisor','analyst','field_agent') "
        "AND email LIKE '%@sahali.tn'"
    ))
    conn.execute(sa.text(
        "DELETE FROM users WHERE role='citizen' AND phone LIKE '+21620111%'"
    ))
