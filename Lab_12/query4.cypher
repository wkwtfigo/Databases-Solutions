MATCH (d:Person)-[:DIRECTED]->(m:Movie)<-[:ACTED_IN]-(a:Person) with d, a, count(m) as movies_together where movies_together > 2 return d.name as director_name, a.name as actor_name, movies_together

/*
director_name | actor_name | movies_together
1
"Lilly Wachowski" "Carrie-Anne Moss" 3
2
"Lilly Wachowski" "Laurence Fishburne" 3
3
"Lilly Wachowski" "Hugo Weaving" 4
4
"Lilly Wachowski" "Keanu Reeves" 3
5
"Lana Wachowski" "Carrie-Anne Moss" 3
6
"Lana Wachowski" "Laurence Fishburne" 3
7
"Lana Wachowski" "Hugo Weaving" 4
8
"Lana Wachowski" "Keanu Reeves" 3
*/