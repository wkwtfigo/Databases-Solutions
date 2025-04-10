match (p:Person)-[r:REVIEWED]->(m:Movie) where r.rating > 90 return p.name as reviewer_name, m.title as movie_title, r.rating as rating

/*
reviewer_name | movie_title | rating
1
"Jessica Thompson" "Jerry Maguire" 92
2
"Jessica Thompson" "Cloud Atlas" 95
3
"James Thompson" "The Replacements" 100
*/