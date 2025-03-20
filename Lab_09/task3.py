import psycopg2
from geopy.geocoders import Nominatim

DB_CONFIG = {
    "dbname": "demo",
    "user": "postgres",
    "password": "password",
    "host": "localhost",
    "port": "5432"
}

def create_address_table():
    query = """
    CREATE TABLE IF NOT EXISTS Address (
        address_id SERIAL PRIMARY KEY,
        address_text TEXT,
        address_x NUMERIC,
        address_y NUMERIC
    );
    """
    with psycopg2.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            conn.commit()

def get_airport_coordinates():
    query = "SELECT airport_code, lat, lon FROM get_airport_addresses();"
    with psycopg2.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            return cur.fetchall()
        
def insert_address(address, lat, lon):
    query = "INSERT INTO Address (address_text, address_x, address_y) VALUES (%s, %s, %s);"
    with psycopg2.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            cur.execute(query, (address, lat, lon))
            conn.commit()

def get_real_addresses():
    geolocator = Nominatim(user_agent="geo_converter")
    coordinates = get_airport_coordinates()

    for airport_code, lat, lon in coordinates:
        try:
            location = geolocator.reverse((lat, lon), language="en")
            if location and location.address:
                insert_address(location.address, lat, lon)
                print(f"Saved: {airport_code} -> {location.address}")
            else:
                print(f"Could not find address for {airport_code} ({lat}, {lon})")
        except Exception as e:
            print(f"Error fetching address for {airport_code} ({lat}, {lon}): {e}")

if __name__ == "__main__":
    create_address_table()
    get_real_addresses()

"""
Program output:
Saved: MRV -> Alagirsky District, Republic of North Ossetia – Alania, North Caucasian Federal District, Russia
Saved: STW -> Chartala, Akhmeta Municipality, Kakheti, 0900, Georgia
Saved: ASF -> Chernoyarsky District, Astrakhan Oblast, Russia
Saved: MRV -> Alagirsky District, Republic of North Ossetia – Alania, North Caucasian Federal District, Russia
Saved: STW -> Chartala, Akhmeta Municipality, Kakheti, 0900, Georgia
Saved: ASF -> Chernoyarsky District, Astrakhan Oblast, Russia
Saved: STW -> Chartala, Akhmeta Municipality, Kakheti, 0900, Georgia
Saved: ASF -> Chernoyarsky District, Astrakhan Oblast, Russia
Saved: ASF -> Chernoyarsky District, Astrakhan Oblast, Russia
Saved: GRV -> Ipatovsky District, Stavropol Krai, North Caucasian Federal District, Russia
Saved: GRV -> Ipatovsky District, Stavropol Krai, North Caucasian Federal District, Russia
Saved: NAL -> Baksan Municipality, Kabardino-Balkaria, North Caucasian Federal District, Russia
Saved: OGZ -> Alexandrovsky District, Stavropol Krai, North Caucasian Federal District, Russia
Saved: ESL -> Ногайская степь, Nogaysky District, Dagestan, North Caucasian Federal District, Russia
Saved: GDZ -> Baharabad, دهستان چهریق, بخش کوهسار, Salmas County, West Azerbaijan Province, Iran
Saved: KRR -> Pileh Savar, دهستان زنگبار, بخش مرکزی, Poldasht County, West Azerbaijan Province, Iran
Saved: MCX -> Малолученское сельское поселение, Дубовский район, Rostov Oblast, 347425, Russia
Saved: ROV -> Khojavend District, Azerbaijan
Saved: AER -> Tuzluca, Iğdır, Eastern Anatolia Region, Turkey
Could not find address for VOG (44.3455009460449, 48.7825012207031)
Saved: AAQ -> دهستان باراندوزچای جنوبی, بخش مرکزی, Urumia County, West Azerbaijan Province, Iran
"""

"""
Table address: (address_id, address_text, address_x, address_y):
1	"Alagirsky District, Republic of North Ossetia – Alania, North Caucasian Federal District, Russia"	43.081901550293	44.2251014709473
2	"Chartala, Akhmeta Municipality, Kakheti, 0900, Georgia"	42.1128005981445	45.1091995239258
3	"Chernoyarsky District, Astrakhan Oblast, Russia"	48.0063018799	46.2832984924
4	"Ipatovsky District, Stavropol Krai, North Caucasian Federal District, Russia"	45.7840995788574	43.2980995178223
5	"Baksan Municipality, Kabardino-Balkaria, North Caucasian Federal District, Russia"	43.6366004943848	43.5129013061523
6	"Alexandrovsky District, Stavropol Krai, North Caucasian Federal District, Russia"	44.6066017151	43.2051010132
7	"Ногайская степь, Nogaysky District, Dagestan, North Caucasian Federal District, Russia"	44.3308982849121	46.3739013671875
8	"Baharabad, دهستان چهریق, بخش کوهسار, Salmas County, West Azerbaijan Province, Iran"	38.0124807358	44.5820926295
9	"Pileh Savar, دهستان زنگبار, بخش مرکزی, Poldasht County, West Azerbaijan Province, Iran"	39.170501708984	45.034698486328
10	"Малолученское сельское поселение, Дубовский район, Rostov Oblast, 347425, Russia"	47.6523017883301	42.8167991638184
11	"Khojavend District, Azerbaijan"	39.8180999756	47.2582015991
12	"Tuzluca, Iğdır, Eastern Anatolia Region, Turkey"	39.956600189209	43.449901580811
13	"دهستان باراندوزچای جنوبی, بخش مرکزی, Urumia County, West Azerbaijan Province, Iran"	37.347301483154	45.002101898193
"""