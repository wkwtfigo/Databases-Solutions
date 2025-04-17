import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from sentence_transformers import SentenceTransformer

DB_NAME = "writersdb"
DB_USER = "postgres"
DB_PASSWORD = "rootroot"
DB_HOST = "localhost"
DB_PORT = 5433

conn = psycopg2.connect(
    dbname="postgres", user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
)
conn.autocommit = True
cur = conn.cursor()
cur.execute(f"SELECT 1 FROM pg_database WHERE datname = '{DB_NAME}'")
exists = cur.fetchone()
if not exists:
    cur.execute(f"CREATE DATABASE {DB_NAME};")
cur.close()
conn.close()

conn = psycopg2.connect(
    dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
)
cur = conn.cursor()
cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")

cur.execute("""
CREATE TABLE IF NOT EXISTS writers (
    id SERIAL PRIMARY KEY,
    writer_name TEXT,
    writer_name_vector VECTOR(384),
    text TEXT,
    text_vector VECTOR(384)
);
""")
conn.commit()

model = SentenceTransformer('all-MiniLM-L6-v2') 

with open("Lab_13/writers_biographies.txt", "r", encoding="utf-8") as f:
    data = f.read()

biographies = data.split("---")

for bio in biographies:
    bio = bio.strip()
    if not bio:
        continue

    lines = bio.split("\n")
    header = lines[0].strip()

    if not header.startswith("#"):
        continue

    name_part = header[1:].split(":")[0].strip()
    bio_text = "\n".join(lines[1:]).strip()

    name_vec = model.encode(name_part).tolist()
    text_vec = model.encode(bio_text).tolist()

    cur.execute("""
        INSERT INTO writers (writer_name, writer_name_vector, text, text_vector)
        VALUES (%s, %s, %s, %s)
    """, (name_part, name_vec, bio_text, text_vec))

conn.commit()
cur.close()
conn.close()

print("Done")