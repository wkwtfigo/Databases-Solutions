import psycopg2
from sentence_transformers import SentenceTransformer
import random

DB_NAME = "writersdb"
DB_USER = "postgres"
DB_PASSWORD = "rootroot"
DB_HOST = "localhost"
DB_PORT = 5433

model = SentenceTransformer('all-MiniLM-L6-v2')

def get_random_writer():
    conn = psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
    )
    cur = conn.cursor()

    cur.execute("SELECT writer_name, text, text_vector FROM writers ORDER BY random() LIMIT 1;")
    
    writer = cur.fetchone()
    conn.close()

    return {
        'name': writer[0],
        'text': writer[1],
        'vector': writer[2]
    }

def find_similar_writers(reference_vector, threshold=0.3):
    conn = psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
    )
    cur = conn.cursor()

    cur.execute("""
            SELECT writer_name, text, 
                   1 - (text_vector <=> %s::vector) as similarity
            FROM writers
            WHERE 1 - (text_vector <=> %s::vector) > %s
            ORDER BY similarity DESC;
        """, (reference_vector, reference_vector, threshold))

    results = cur.fetchall()
    conn.close()

    return results

def main():
    random_writer = get_random_writer()
    print(f"\nRandomly selected writer: {random_writer['name']}")
    print(f"\nOriginal text:\n{random_writer['text']}...\n")

    similar_writers = find_similar_writers(random_writer['vector'])
    print(f"\nFound {len(similar_writers)} similar writers (threshold=0.3):")
    print("="*80)

    for idx, (name, text, similarity) in enumerate(similar_writers, 1):
        print(f"\n{idx}. {name} (similarity: {similarity:.2f})")
        print(f"\nText:\n{text}...")
        print("-"*80)

if __name__ == "__main__":
    main()

"""
Randomly selected writer: Taylor Parker

Original text:
Head alone board hold.
For reflect from base go....


Found 4 similar writers (threshold=0.6):
================================================================================

1. Taylor Parker (similarity: 1.00)

Text:
Head alone board hold.
For reflect from base go....
--------------------------------------------------------------------------------

2. Tyler Hansen (similarity: 0.39)

Text:
Against rise stand mother ready focus inside finish. Arrive night during they sure sometimes. Reflect drive provide ok series away moment recent.
Too example analysis physical staff. Perhaps allow city you gas reflect. Involve sell over magazine energy point least....
--------------------------------------------------------------------------------

3. Christian Phillips (similarity: 0.33)

Text:
Chair notice enough section. Along last system meeting several.
Stock would very their ground bit. Why yet field son question stock garden per.
Least nice cut surface today small personal. Green involve note gas....
--------------------------------------------------------------------------------

4. Mr. Robert Stevens (similarity: 0.32)

Text:
Light accept group what sense. Structure call oil and model. Purpose successful former reflect give.        
Manager research say third. Discussion production month next. Experience their talk their agreement easy program....
--------------------------------------------------------------------------------
"""