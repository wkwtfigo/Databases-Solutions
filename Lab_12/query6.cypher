match (a:Person)-[:ACTED_IN]->(m:Movie) with a, collect(DISTINCT toInteger(m.released / 10) * 10) as decades where size(decades) > 2 return a.name as actor_name

/*
actor_name
1
"Hugo Weaving"
2
"Tom Cruise"
3
"Jack Nicholson"
4
"Tom Hanks"
*/