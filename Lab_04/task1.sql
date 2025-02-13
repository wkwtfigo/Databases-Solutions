CREATE TABLE artist (
    name CHAR(50) NOT NULL PRIMARY KEY
);

CREATE TABLE album (
    name CHAR(50) NOT NULL PRIMARY KEY
);

CREATE TABLE track (
    name CHAR(50) NOT NULL PRIMARY KEY,
    length INT,
    album_name CHAR(50) NOT NULL,
    FOREIGN KEY (album_name) REFERENCES album(name)
);

CREATE TABLE makes (
    artist_name CHAR(50) NOT NULL PRIMARY KEY,
    album_name CHAR(50) NOT NULL PRIMARY KEY,
    FOREIGN KEY (artist_name) REFERENCES artist(name),
    FOREIGN KEY (album_name) REFERENCES album(name)
);
