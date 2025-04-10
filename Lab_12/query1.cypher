match (p:Person)-[r:ACTED_IN]->(m:Movie) where size(r.roles) > 1 RETURN p.name as actor_name, r.roles as roles

/*
actor_name | roles
1
"Meg Ryan"
["DeDe", "Angelica Graynamore", "Patricia Graynamore"]
2
"Hugo Weaving"
["Bill Smoke", "Haskell Moore", "Tadeusz Kesselring", "Nurse Noakes", "Boardman Mephi", "Old Georgie"]
3
"Tom Hanks"
["Zachry", "Dr. Henry Goose", "Isaac Sachs", "Dermot Hoggins"]
4
"Halle Berry"
["Luisa Rey", "Jocasta Ayrs", "Ovid", "Meronym"]
5
"Jim Broadbent"
["Vyvyan Ayrs", "Captain Molyneux", "Timothy Cavendish"]
6
"Tom Hanks"
["Hero Boy", "Father", "Conductor", "Hobo", "Scrooge", "Santa Claus"]
*/