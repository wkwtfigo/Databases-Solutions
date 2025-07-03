MATCH (p:Person)-[r:ACTED_IN]->(m:Movie) with p, m order by p.name, m.released asc with p, head(collect(m)) as oldest_movie where oldest_movie.released < 1990 return p.name as actor_name, oldest_movie.title as movie_title, oldest_movie.released as year

/*
actor_name | movie_title | year
1
"Anthony Edwards"
"Top Gun"
1986
2
"Corey Feldman"
"Stand By Me"
1986
3
"Danny DeVito"
"One Flew Over the Cuckoo's Nest"
1975
4
"Jack Nicholson"
"One Flew Over the Cuckoo's Nest"
1975
5
"Jerry O'Connell"
"Stand By Me"
1986
6
"John Cusack"
"Stand By Me"
1986
7
"Kelly McGillis"
"Top Gun"
1986
8
"Kiefer Sutherland"
"Stand By Me"
1986
9
"Marshall Bell"
"Stand By Me"
1986
10
"Meg Ryan"
"Top Gun"
1986
11
"River Phoenix"
"Stand By Me"
1986
12
"Tom Cruise"
"Top Gun"
1986
13
"Tom Skerritt"
"Top Gun"
1986
14
"Val Kilmer"
"Top Gun"
1986
15
"Wil Wheaton"
"Stand By Me"
1986
*/