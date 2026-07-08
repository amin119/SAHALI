"""Seed all Tunisia municipalities (by governorate)

Idempotent/additive only — safe to run against a database that already has
some municipalities (e.g. the demo "Tunis" row from 0002). Each insert is
guarded by a NOT EXISTS check on name, so re-running this migration or
running it against a partially-seeded DB never creates duplicates and never
touches/removes existing rows.

Revision ID: 0007
Revises: 0006
Create Date: 2026-07-08
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Source: Wikipedia "List of cities in Tunisia" (fetched 2026-07-08), grouped
# by governorate. This was extracted via automated summarization of the
# Wikipedia page rather than an official government gazette, so a handful of
# the smallest/newest communes from the 2016 reform (official total: 350)
# may be missing or have slightly different spellings — spot-check against
# an official INS/ministry source before treating this as authoritative for
# legal/administrative purposes.
MUNICIPALITIES_BY_GOVERNORATE: dict[str, list[str]] = {
    "Tunis": ["Tunis", "Le Bardo", "Le Kram", "La Goulette", "Carthage", "Sidi Bou Said", "La Marsa", "Sidi Hassine"],
    "Ariana": ["Ariana", "La Soukra", "Raoued", "Kalâat el-Andalous", "Sidi Thabet", "Ettadhamen", "Mnihla"],
    "Ben Arous": ["Ben Arous", "El Mourouj", "Hammam Lif", "Hammam Chott", "Bou Mhel el-Bassatine", "Ezzahra", "Radès", "Mégrine", "Mohamedia", "Mornag", "Khalidia", "Fouchana", "Naassen"],
    "Manouba": ["Manouba", "Den Den", "Douar Hicher", "Oued Ellil", "Mornaguia", "Borj El Amri", "Djedeida", "Tebourba", "El Battan"],
    "Nabeul": ["Nabeul", "Dar Châabane El Fehri", "Béni Khiar", "El Maâmoura", "Somâa", "Korba", "Tazarka", "Menzel Temime", "Menzel Horr", "El Mida", "Kelibia", "Azmour", "Hammam Ghezèze", "Dar Allouch", "El Haouaria", "Takelsa", "Soliman", "Korbous", "Menzel Bouzelfa", "Béni Khalled", "Zaouiet Djedidi", "Grombalia", "Bou Argoub", "Hammamet", "Fondouk Jedid", "Chrifet", "Sidi Djedidi", "Tazougrane"],
    "Zaghouan": ["Zaghouan", "Zriba", "Bir Mcherga", "Djebel Oust", "El Fahs", "Nadhour", "El Amaiem", "Saouaf"],
    "Bizerte": ["Bizerte", "Sejnane", "Mateur", "Menzel Bourguiba", "Tinja", "Ghar al Milh", "Aousja", "Menzel Jemil", "Menzel Abderrahmane", "El Alia", "Ras Jebel", "Metline", "Raf Raf", "El Hachachna", "Ghezala", "Joumine", "Utique"],
    "Béja": ["Béja", "El Maâgoula", "Zahret Medien", "Nefza", "Téboursouk", "Testour", "Goubellat", "Medjez El Bab", "Ouchtata", "Sidi Ismaïl", "Slouguia", "Thibar"],
    "Jendouba": ["Jendouba", "Bou Salem", "Tabarka", "Aïn Draham", "Fernana", "Beni M'Tir", "Ghardimaou", "Oued Melliz", "Jouaouda", "Souk Sebt", "Kalaa", "Khmairia", "Aïn Sobh", "Balta"],
    "Kef": ["El Kef", "Nebeur", "Touiref", "Sakiet Sidi Youssef", "Tajerouine", "Menzel Salem", "Kalaat Senan", "Kalâat Khasba", "Jérissa", "El Ksour", "Dahmani", "Sers", "Bahra", "El Marja", "Zaafrane"],
    "Siliana": ["Siliana", "Bou Arada", "Gaâfour", "El Krib", "Sidi Bou Rouis", "Maktar", "Rouhia", "Kesra", "Bargou", "El Aroussa", "El Hababsa", "Sidi Morched"],
    "Sousse": ["Sousse", "Ksibet Thrayet", "Ezzouhour", "Zaouiet Sousse", "Hammam Sousse", "Akouda", "Kalâa Kebira", "Sidi Bou Ali", "Hergla", "Enfidha", "Bouficha", "Sidi El Hani", "M'saken", "Kalâa Seghira", "Messaadine", "Kondar", "Chott Meriem", "Grimet"],
    "Monastir": ["Monastir", "Khniss", "Ouerdanine", "Sahline", "Sidi Ameur", "Zéramdine", "Beni Hassen", "Ghenada", "Jemmal", "Menzel Kamel", "Zaouiet Kontoch", "Bembla", "Menzel Ennour", "El Masdour", "Moknine", "Sidi Bennour", "Menzel Fersi", "Amiret El Fhoul", "Amiret Touazra", "Amiret Hajjaj", "Cherahil", "Bekalta", "Téboulba", "Ksar Hellal", "Ksibet El Mediouni", "Bennane Bodheur", "Touza", "Sayada", "Lemta", "Bouhjar", "Menzel Hayet"],
    "Mahdia": ["Mahdia", "Rejiche", "Bou Merdes", "Ouled Chamekh", "Chorbane", "Hebira", "Essouassi", "El Djem", "Kerker", "Chebba", "Melloulèche", "Sidi Alouane", "Ksour Essef", "El Bradâa", "El Hekaima", "Sidi Zid", "Tlelsa", "Zelba"],
    "Sfax": ["Sfax", "Sakiet Ezzit", "Chihia", "Sakiet Eddaïer", "Gremda", "El Aïn", "Thyna", "Agareb", "Jebiniana", "El Hencha", "Menzel Chaker", "Ghraïba", "Bir Ali Ben Khalifa", "Skhira", "Mahares", "Kerkennah", "El Achech", "El Amra", "El Nasr", "Hadjeb", "Hazeg", "Nadhour", "Ouabed"],
    "Kairouan": ["Kairouan", "Chebika", "Sbikha", "Oueslatia", "Aïn Djeloula", "Haffouz", "El Alâa", "Hajeb El Ayoun", "Nasrallah", "Menzel Mehiri", "Echrarda", "Bou Hajla", "Raqqada", "Chraitia", "Sisseb", "Jehina", "Aïn El Beïdha", "Chaouachi", "Abida"],
    "Kasserine": ["Kasserine", "Sbeitla", "Sbiba", "Jedelienne", "Thala", "Haïdra", "Foussana", "Fériana", "Thélepte", "Magel Bel Abbès"],
    "Sidi Bouzid": ["Sidi Bouzid", "Jilma", "Cebbala Ouled Asker", "Bir El Hafey", "Sidi Ali Ben Aoun", "Menzel Bouzaiane", "Meknassy", "Mezzouna", "Regueb", "Ouled Haffouz", "Souk Jedid", "Sidi Bouzid Ouest", "Sidi Bouzid Est", "El Hichria", "Baten Ghzal"],
    "Gabès": ["Gabès", "Chenini Nahal", "Ghannouch", "Métouia", "Oudhref", "El Hamma", "Matmata", "Nouvelle Matmata", "Mareth", "Zarat", "Teboulbou", "Habib Thameur Bouatouch", "Kettana", "Bouchemma", "Dkhilet Toujane", "Menzel El Habib"],
    "Médenine": ["Medenine", "Beni Khedache", "Ben Gardane", "Zarzis", "Houmt Souk", "Midoun", "Ajim", "Sidi Makhlouf"],
    "Tataouine": ["Tataouine", "Bir Lahmar", "Ghomrassen", "Dehiba", "Remada", "Smâr"],
    "Gafsa": ["Gafsa", "El Ksar", "Moularès", "Redeyef", "Métlaoui", "Mdhila", "El Guettar", "Sened", "Belkhir", "Lalla", "Sidi Aïch", "Sidi Boubaker", "Zannouch"],
    "Tozeur": ["Tozeur", "Degache", "El Hamma du Jérid", "Nafta", "Tamerza", "Hazoua"],
    "Kebili": ["Kebili", "Djemna", "Douz", "El Golâa", "Souk Lahad", "Bechli", "Bechri", "Faouar", "Rjim Maatoug"],
}


def upgrade() -> None:
    conn = op.get_bind()
    for names in MUNICIPALITIES_BY_GOVERNORATE.values():
        for name in names:
            conn.execute(
                sa.text(
                    """
                    INSERT INTO municipalities (name)
                    SELECT :name
                    WHERE NOT EXISTS (
                        SELECT 1 FROM municipalities WHERE name = :name
                    )
                    """
                ),
                {"name": name},
            )


def downgrade() -> None:
    # Intentionally a no-op: this migration is additive-only and shares rows
    # (e.g. "Tunis") with earlier demo seed data, so a blanket delete here
    # could remove municipalities that other rows (users, reports) depend
    # on. Remove specific rows manually if truly needed.
    pass
