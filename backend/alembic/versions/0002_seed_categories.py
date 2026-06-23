"""Seed categories and demo municipality

Revision ID: 0002
Revises: 0001
Create Date: 2026-06-19
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

CATEGORIES = [
    # (slug, label_ar, label_fr, label_en, parent_slug, sla_hours, icon)
    ("infrastructure", "البنية التحتية", "Infrastructure", "Infrastructure", None, 168, "road"),
    ("infrastructure.pothole", "حفرة في الطريق", "Nid-de-poule", "Road pothole", "infrastructure", 168, "pothole"),
    ("infrastructure.sidewalk", "رصيف تالف", "Trottoir endommagé", "Damaged sidewalk", "infrastructure", 168, "sidewalk"),
    ("infrastructure.sign_missing", "لافتة مفقودة", "Panneau manquant", "Missing road sign", "infrastructure", 168, "sign"),
    ("infrastructure.sign_damaged", "لافتة تالفة", "Panneau endommagé", "Damaged road sign", "infrastructure", 168, "sign"),

    ("lighting", "الإنارة العامة", "Éclairage public", "Public Lighting", None, 72, "lightbulb"),
    ("lighting.streetlight", "عطل مصباح الشارع", "Lampadaire défectueux", "Faulty streetlight", "lighting", 72, "streetlight"),
    ("lighting.exposed_wire", "أسلاك كهربائية مكشوفة", "Fils électriques exposés", "Exposed electrical wires", "lighting", 24, "wire"),

    ("waste", "النظافة والنفايات", "Propreté et déchets", "Cleanliness and Waste", None, 168, "trash"),
    ("waste.illegal_dump", "إلقاء غير قانوني للنفايات", "Dépôt sauvage", "Illegal dumping", "waste", 168, "dump"),
    ("waste.garbage", "تراكم القمامة", "Déchets accumulés", "Accumulated garbage", "waste", 168, "garbage"),
    ("waste.overflow", "حاويات ممتلئة", "Conteneurs débordants", "Overflowing containers", "waste", 168, "overflow"),

    ("environment", "البيئة", "Environnement", "Environment", None, 336, "tree"),
    ("environment.water_pollution", "تلوث المياه", "Pollution de l'eau", "Water pollution", "environment", 336, "water"),
    ("environment.air_pollution", "تلوث الهواء", "Pollution de l'air", "Air pollution", "environment", 336, "air"),
    ("environment.tree_cutting", "قطع الأشجار بشكل غير قانوني", "Abattage illégal d'arbres", "Illegal tree cutting", "environment", 336, "tree"),

    ("water_sanitation", "المياه والصرف الصحي", "Eau et assainissement", "Water and Sanitation", None, 48, "water"),
    ("water_sanitation.leak", "تسرب المياه", "Fuite d'eau", "Water leak", "water_sanitation", 48, "leak"),
    ("water_sanitation.sewage", "انسداد الصرف الصحي", "Égout bouché", "Blocked sewage", "water_sanitation", 48, "sewage"),

    ("transport", "النقل", "Transport", "Transportation", None, 168, "bus"),
    ("transport.bus_stop", "محطة حافلات تالفة", "Arrêt de bus endommagé", "Damaged bus stop", "transport", 168, "bus"),
    ("transport.traffic_signal", "عطل إشارة المرور", "Dysfonctionnement feu de circulation", "Traffic signal malfunction", "transport", 168, "traffic"),

    ("safety", "السلامة والأمن", "Sécurité", "Safety and Security", None, 24, "shield"),
    ("safety.building", "مبنى غير آمن", "Bâtiment dangereux", "Unsafe building", "safety", 24, "building"),
    ("safety.hazard", "خطر عام", "Danger public", "Public safety hazard", "safety", 24, "hazard"),
]


def upgrade() -> None:
    conn = op.get_bind()

    # Demo municipality
    conn.execute(sa.text(
        "INSERT INTO municipalities (name, subscription_tier) VALUES ('Tunis', 'pro')"
    ))
    muni_id = conn.execute(sa.text("SELECT id FROM municipalities WHERE name='Tunis'")).scalar()

    # Demo department
    conn.execute(sa.text(
        "INSERT INTO departments (municipality_id, name) VALUES (:m, 'Services Techniques')"
    ), {"m": muni_id})
    dept_id = conn.execute(sa.text("SELECT id FROM departments WHERE municipality_id=:m"), {"m": muni_id}).scalar()

    slug_to_id: dict[str, int] = {}
    for cat in CATEGORIES:
        slug, label_ar, label_fr, label_en, parent_slug, sla_hours, icon = cat
        parent_id = slug_to_id.get(parent_slug) if parent_slug else None
        result = conn.execute(
            sa.text("""
                INSERT INTO categories (slug, label_ar, label_fr, label_en, parent_id, sla_hours, icon, default_department_id)
                VALUES (:slug, :ar, :fr, :en, :parent, :sla, :icon, :dept)
                RETURNING id
            """),
            {"slug": slug, "ar": label_ar, "fr": label_fr, "en": label_en,
             "parent": parent_id, "sla": sla_hours, "icon": icon, "dept": dept_id}
        )
        slug_to_id[slug] = result.scalar()


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text("DELETE FROM categories"))
    conn.execute(sa.text("DELETE FROM departments"))
    conn.execute(sa.text("DELETE FROM municipalities"))
