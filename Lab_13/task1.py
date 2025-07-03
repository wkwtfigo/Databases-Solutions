import psycopg2
from sentence_transformers import SentenceTransformer

DB_NAME = "writersdb"
DB_USER = "postgres"
DB_PASSWORD = "rootroot"
DB_HOST = "localhost"
DB_PORT = 5433

model = SentenceTransformer('all-MiniLM-L6-v2')

def find_similar_writers(name_query):
    name_vec = model.encode(name_query).tolist()

    conn = psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
    )
    cur = conn.cursor()

    cur.execute("""
        SELECT writer_name, text
        FROM writers
        ORDER BY writer_name_vector <-> %s::vector
        LIMIT 5
    """, (name_vec,))

    results = cur.fetchall()
    conn.close()

    print(f"\nTop 5 similar to '{name_query}' writers:")
    for name, text in results:
        print(f"\n{name}\n{text[:200]}...")

find_similar_writers("Alex")
find_similar_writers("Laura")
