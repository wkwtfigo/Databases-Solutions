import psycopg2
from collections import Counter
import re
from sentence_transformers import SentenceTransformer
import nltk
from nltk.corpus import stopwords

nltk.download('stopwords')
stop_words = set(stopwords.words("english"))

DB_NAME = "writersdb"
DB_USER = "postgres"
DB_PASSWORD = "rootroot"
DB_HOST = "localhost"
DB_PORT = 5433

model = SentenceTransformer('all-MiniLM-L6-v2')

def get_all_texts():
    conn = psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
    )
    cur = conn.cursor()
    cur.execute("SELECT id, writer_name, text FROM writers;")
    results = cur.fetchall()
    conn.close()
    return results

def extract_keywords(texts, top_k=10):
    all_words = []
    for _, _, text in texts:
        words = re.findall(r'\b\w+\b', text.lower())
        first_15 = words[:15]
        filtered = [w for w in first_15 if w not in stop_words]
        all_words.extend(filtered)
    return [word for word, _ in Counter(all_words).most_common(top_k)]

def find_similar_by_keywords(keywords, threshold=0.4):
    keyword_string = " ".join(keywords)
    keyword_vec = model.encode(keyword_string).tolist()
    max_distance = 1 - threshold

    conn = psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT
    )
    cur = conn.cursor()

    cur.execute("""
        SELECT writer_name, text, 1 - (text_vector <=> %s::vector) AS similarity
        FROM writers
        WHERE (text_vector <=> %s::vector) <= %s
        ORDER BY similarity DESC;
    """, (keyword_vec, keyword_vec, max_distance))

    results = cur.fetchall()
    conn.close()
    return keyword_string, results

def main():
    texts = get_all_texts()
    top_keywords = extract_keywords(texts)
    print("Top 10 keywords from first 15 words of each text:")
    print(top_keywords)
    print("=" * 80)

    keyword_text, similar = find_similar_by_keywords(top_keywords, threshold=0.4)
    print(f"\nSearching for texts similar to combined keywords:\n\"{keyword_text}\"\n")

    for name, text, sim in similar:
        print(f"{name} | Similarity: {sim:.2f}")
        print(f"{text[:200]}...\n{'-'*60}")

if __name__ == "__main__":
    main()


"""
Top 10 keywords from first 15 words of each text:
['item', 'fire', 'prove', 'join', 'summer', 'contain', 'fast', 'senior', 'tree', 'life']
================================================================================

Searching for texts similar to combined keywords:
"item fire prove join summer contain fast senior tree life"

James Klein | Similarity: 0.51
Many owner prove my little catch tree. Summer information per kitchen question fast property....
------------------------------------------------------------
Pamela Brown | Similarity: 0.42
Senior ground cold those wife. Visit behavior reason trade himself claim modern summer.
Drop compare spring oil. Decide protect include light sometimes section time. Early pressure someone....
------------------------------------------------------------
"""