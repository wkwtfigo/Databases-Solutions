match (p:Person)-[r:ACTED_IN]-(m:Movie) where (p:Person)-[:DIRECTED]-() return DISTINCT p.name as actor_name

/*
actor_name
1
"James Marshall"
2
"Werner Herzog"
3
"Tom Hanks"
4
"Clint Eastwood"
5
"Danny DeVito"
*/