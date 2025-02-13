CREATE TABLE Artists (
  id INT PRIMARY KEY,
  Name VARCHAR(40),
  country VARCHAR(100)
);

CREATE TABLE Albums (
  id INTEGER PRIMARY KEY,
  artist_id INTEGER,
  name VARCHAR(40),
  year_of_publication INTEGER,
  FOREIGN KEY (artist_id) REFERENCES Artists(id)
);

INSERT INTO Artists (id, name, country) VALUES
(1, 'Pink Floyd', 'UK'),
(2, 'Radiohead', 'UK'),
(3, 'The Beatles', 'UK'),
(4, 'Kendrick Lamar', 'USA'),
(5, 'Pixies', 'USA');

INSERT INTO Albums (id, artist_id, name, year_of_publication) VALUES
(1, 1, 'The Dark Side Of The Moon', 1973),
(2, 2, 'OK Computer', 1997),
(3, 3, 'Abbey Road', 1969),
(4, 3, 'Revolver', 1966),
(5, 2, 'In Rainbows', 2007),
(6, 4, 'Good Kid, M.A.A.D City', 2012),
(7, 5, 'Doolittle', 1989),
(8, 3, 'Rubber Soul', 1965);

SELECT id, name, country
FROM Artists
WHERE country = 'USA';

SELECT artist_id, name
FROM Albums
WHERE artist_id = 3;

SELECT artist_id, name
FROM Albums
WHERE year_of_publication >= 2000;

SELECT Albums.name AS album_name, Artists.name AS artist_name
FROM Albums
JOIN Artists ON Albums.artist_id = Artists.id;