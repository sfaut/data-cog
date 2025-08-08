# COG -- Code Officiel Géographique de France

- [README](https://github.com/sfaut/data-cog/tree/master/README.md)
- [ETL SQL et données 2025](https://github.com/sfaut/data-cog/tree/master/v2025/)

- [Présentation](#présentation)
- [Dessins](#dessins)
- [Exemples d'utilisation](#exemples)
  - [DuckDB](#duckdb)
  - [PHP](#php)
  - [Python](#python)

## Présentation

L'<abbr title="Institut National de la Statistique et des Études Économiques">INSEE</abbr>
fournit, via le Code Officiel Géographique (<abbr title="Code Officiel Géographique">COG</abbr>),
des fichiers annuels relatifs aux communes, cantons, arrondissements,
collectivités territoriales exerçant des compétences départementales,
départements et régions de France, ainsi qu'aux pays et territoires étrangers.

Ce dépôt propose ces données dans différents formats plats (CSV, JSON, ND-JSON, Parquet)
et au format DuckDB.

Le schéma de base de données n'a pas vocation à être 3NF,
ni même l'ambition d'être optimisé pour des traitements lourds.
Par exemple, les identifiants naturels texte ont été conservés tels quels et promus clef primaire.

## Dessins

### Général

| Colonne COG | Description COG                               | Colonne sfaut\data-cog |
|------------:|----------------------------------------------:|-----------------------:|
| `LIBELLE`   | Nom en clair (typographie riche) avec article | `name`                 |
| `NCCENR`    | Nom en clair (typographie riche)              | `single_name`          |
| `NCC`       | Nom en clair (majuscules)                     | `simple_name`          |

### `article`

| Colonne     | Type       | Description                                                  |
|------------:|-----------:|--------------------------------------------------------------|
| id 🔑      | `UTINYINT` | Identifiant numérique COG                                    |
| article     | `VARCHAR`  | Article, ex. *Les* pour *Les Hauts-de-Seine*                 |
| preposition | `VARCHAR`  | Préposition, ex. *des* pour *Département des Hauts-de-Seine* |
| comment     | `VARCHAR`  | --                                                           |

### `country`

| Colonne               | Type        | Description                                                      |
|----------------------:|------------:|------------------------------------------------------------------|
| code 🔑              | `VARCHAR`   | Code identifiant COG sur 5 caractères, ex. *99100*               |
| iso2_code             | `VARCHAR`   | Code alphabétique ISO sur 2 caractères, ex. *FR*                 |
| iso3_code             | `VARCHAR`   | Code alphabétique ISO sur 3 caractères, ex. *FRA*                |
| num3_code             | `VARCHAR`   | Code numérique ISO sur 3 caractères, ex. *250*                   |
| name                  | `VARCHAR`   | Nom court, ex. *France*                                          |
| official_name         | `VARCHAR`   | Nom officiel, ex. *République française*                         |
| actual_id 🔗         | `UTINYINT`  | Code actualité                                                   |
| actual_name           | `VARCHAR`   | Décodage du code actualité                                       |
| parent_code 🔗       | `VARCHAR`   | Code du pays de rattachement, ex. pour Hong Kong *99216* (Chine) |
| first_appearance_year | `USMALLINT` | Année de 1re apparition dans le COG                              |

### `region`

| Colonne          | Type       | Description                                                                                        |
|-----------------:|-----------:|----------------------------------------------------------------------------------------------------|
| code 🔑         | `VARCHAR`  | Code sur 2 caractères                                                                              |
| name             | `VARCHAR`  | Nom, ex. *Provence-Alpes-Côte d'Azur*                                                              |
| single_name      | `VARCHAR`  | Nom sans article                                                                                   |
| simple_name      | `VARCHAR`  | Nom en lettres capitales, sans article et sans caractère spécial, ex. *PROVENCE ALPES COTE D AZUR* |
| identity         | `VARCHAR`  | Code suivi du nom, ex. *53 – Bretagne*                                                             |
| group_name       | `VARCHAR`  | Groupe nominale, ex. *Région de Bretagne*                                                          |
| is_metropolitan  | `BOOLEAN`  | Indique si la région est métropolitaine                                                            |
| article_id 🔗   | `UTINYINT` | Identifiant du type de nom                                                                         |
| article          | `VARCHAR`  | Article                                                                                            |
| preposition      | `VARCHAR`  | Préposition                                                                                        |
| capital_code 🔗 | `VARCHAR`  | Code commune du chef-lieu, ex. *35238*                                                             |
| capital_name     | `VARCHAR`  | Nom du chef-lieu, ex. *Rennes*                                                                     |

### `collectivity`

| Colonne          | Type      | Description                                                                                                |
|-----------------:|----------:|------------------------------------------------------------------------------------------------------------|
| code 🔑         | `VARCHAR` | Code sur 3 caractères, ex. *73D*                                                                           |
| name             | `VARCHAR` | Nom, ex. *Conseil départemental de La Savoie*                                                              |
| single_name      | `VARCHAR` | Nom sans article, ex. *Conseil départemental de La Savoie*                                                 |
| simple_name      | `VARCHAR` | Nom en lettres capitales, sans article et sans caractère spécial, ex. *CONSEIL DEPARTEMENTAL DE LA SAVOIE* |
| identity         | `VARCHAR` | Code suivi du nom, ex. *73D – Conseil départemental de La Savoie*                                          |
| is_metropolitan  | `BOOLEAN` | Indique si la collectivité est métropolitaine                                                              |
| capital_code 🔗 | `VARCHAR` | Code commune du chef-lieu, ex. *73065*                                                                     |
| capital_name     | `VARCHAR` | Nom du chef-lieu, ex. *Annecy*                                                                             |
| region_code 🔗  | `VARCHAR` | Code de la région sur 2 caractères                                                                         |
| region_name      | `VARCHAR` | Nom de la région                                                                                           |
| region_identity  | `VARCHAR` | Code et nom de la région                                                                                   |

### `department`

| Colonne         | Type       | Description                                                                    |
|----------------:|-----------:|--------------------------------------------------------------------------------|
| code 🔑        | `VARCHAR`  | Code sur 2 caractères (3 pour l'outre-mer), ex. *85*                           |
| name            | `VARCHAR`  | Nom, ex. *Vendée*                                                              |
| single_name     | `VARCHAR`  | Nom sans article, ex. *Vendée*                                                 |
| simple_name     | `VARCHAR`  | Nom en lettres capitales, sans article et sans caractère spécial, ex. *VENDEE* |
| identity        | `VARCHAR`  | Code suivi du nom, ex. *85 – Vendée*                                           |
| group_name      | `VARCHAR`  | Groupe nominale, ex. *Département de Vendée*                                   |
| is_metropolitan | `BOOLEAN`  | Indique si le département est métropolitain                                    |
| article_id 🔗  | `UTINYINT` | Identifiant du type de nom                                                     |
| article         | `VARCHAR`  | Article, ex. *La* pour *La Vendée*                                             |
| preposition     | `VARCHAR`  | Préposition, ex. *de La* pour *Département de La Vendée*                       |
| capital_code 🔗| `VARCHAR`  | Code commune du chef-lieu, ex. *85191*                                         |
| capital_name    | `VARCHAR`  | Nom du chef-lieu, ex. *La Roche-sur-Yon*                                       |
| region_code 🔗 | `VARCHAR`  | Code de la région sur 2 caractères                                             |
| region_name     | `VARCHAR`  | Nom de la région                                                               |
| region_identity | `VARCHAR`  | Code et nom de la région                                                       |

### `arrondissement`

| Colonne             | Type       | Description                                                                   |
|--------------------:|-----------:|-------------------------------------------------------------------------------|
| code 🔑            | `VARCHAR`  | Code sur 3 caractères (4 pour l'outre-mer), ex. *513*                         |
| name                | `VARCHAR`  | Nom, ex. *Reims*                                                              |
| single_name         | `VARCHAR`  | Nom sans article, ex. *Reims*                                                 |
| simple_name         | `VARCHAR`  | Nom en lettres capitales, sans article et sans caractère spécial, ex. *REIMS* |
| identity            | `VARCHAR`  | Code suivi du nom, ex. *513 – Reims*                                          |
| group_name          | `VARCHAR`  | Groupe nominal, ex. *Arrondissement de Reims*                                 |
| is_metropolitan     | `BOOLEAN`  | Indique si l'arrondissement est métropolitain                                 |
| article_id 🔗      | `UTINYINT` | Identifiant du type de nom                                                    |
| article             | `VARCHAR`  | Article                                                                       |
| preposition         | `VARCHAR`  | Préposition                                                                   |
| capital_code 🔗    | `VARCHAR`  | Code commune du chef-lieu, ex. *51454*                                        |
| capital_name        | `VARCHAR`  | Nom du chef-lieu, ex. *Reims*                                                 |
| region_code 🔗     | `VARCHAR`  | Code de la région                                                             |
| region_name         | `VARCHAR`  | Nom de la région                                                              |
| region_identity     | `VARCHAR`  | Code et nom de la région                                                      |
| department_code 🔗 | `VARCHAR`  | Code du département                                                           |
| department_name     | `VARCHAR`  | Nom du département                                                            |
| department_identity | `VARCHAR`  | Code et nom du département                                                    |

### `canton`

| Colonne             | Type       | Description                                                                             |
|--------------------:|-----------:|-----------------------------------------------------------------------------------------|
| code 🔑            | `VARCHAR`  | Code sur 4 caractères, ex. *8512*                                                       |
| name                | `VARCHAR`  | Nom, ex. *La Roche-sur-Yon-1*                                                           |
| single_name         | `VARCHAR`  | Nom sans article, ex. *Roche-sur-Yon-1*                                                 |
| simple_name         | `VARCHAR`  | Nom en lettres capitales, sans article et sans caractère spécial, ex. *ROCHE SUR YON 1* |
| identity            | `VARCHAR`  | Code suivi du nom, ex. *8512 – La Roche-sur-Yon-1*                                      |
| group_name          | `VARCHAR`  | Groupe nominal, ex. *Canton de La Roche-sur-Yon-1*                                      |
| type_code 🔗       | `VARCHAR`  | Parmi *C*, *N* et *V*                                                                   |
| type_name           | `VARCHAR`  | Type décodé :<br>*C* = Canton<br>*N* = Canton « fictif » pour communes nouvelles<br>*V* = Canton-Ville (ou pseudo-canton) |
| composition_id 🔗  | `UTINYINT` | Parmi *0..5*                                                                            |
| composition_name    | `VARCHAR`  | Composition décodée :<br>*0* = Non applicable<br>*1* = Canton composé de commune(s) entière(s)<br>*2* = Canton composé d'une fraction d'une commune et de commune(s) entière(s)<br>*3* = Canton composé de fractions de plusieurs communes et de commune(s) entière(s)<br>*4* = Canton composé d'une fraction de commune<br>*5* = Canton composé de fractions de plusieurs communes |
| is_metropolitan     | `BOOLEAN`  | Indique si le canton est métropolitain                                                  |
| article_id 🔗      | `UTINYINT` | Identifiant du type de nom                                                              |
| article             | `VARCHAR`  | Article                                                                                 |
| preposition         | `VARCHAR`  | Préposition                                                                             |
| capital_code 🔗    | `VARCHAR`  | Code commune du bureau central                                                          |
| capital_name        | `VARCHAR`  | Nom de la commune du bureau central                                                     |
| region_code 🔗     | `VARCHAR`  | Code de la région                                                                       |
| region_name         | `VARCHAR`  | Nom de la région                                                                        |
| region_identity     | `VARCHAR`  | Code et nom de la région                                                                |
| department_code 🔗 | `VARCHAR`  | Code du département                                                                     |
| department_name     | `VARCHAR`  | Nom du département                                                                      |
| department_identity | `VARCHAR`  | Code et nom du département                                                              |

### `commune`

| Colonne                 | Type       | Description                                                                                                                    |
|------------------------:|-----------:|--------------------------------------------------------------------------------------------------------------------------------|
| key 🔑                 | `VARCHAR`  | Clef primaire composée du code commune et du type commune                                                                      |
| code                    | `VARCHAR`  | Code sur 5 caractères                                                                                                          |
| type_code               | `VARCHAR`  | Parmi *COM*, *COMA*, *COMD* et *ARM*                                                                                           |
| type_name               | `VARCHAR`  | Type décodé :<br>*COM* = Commune<br>*COMA* = Commune associée<br>*COMD* = Commune déléguée<br>*ARM* = Arrondissement municipal |
| parent_code 🔗         | `VARCHAR`  | Code de la commune parent, pour les commune *COMA*, *COMD* et *ARM*                                                            |
| name                    | `VARCHAR`  | Nom, ex. *L'Île-d'Yeu*                                                                                                         |
| single_name             | `VARCHAR`  | Nom sans article, ex. *Île-d'Yeu*                                                                                              |
| simple_name             | `VARCHAR`  | Nom en lettres capitales, sans article et sans caractère spécial, ex. *ILE D YEU*                                              |
| identity                | `VARCHAR`  | Code suivi du nom, ex. *85113 – L'Île-d'Yeu*                                                                                   |
| group_name              | `VARCHAR`  | Groupe nominal, ex. *Commune de L'Île-d'Yeu*                                                                                   |
| is_metropolitan         | `BOOLEAN`  | Indique si la commune est métropolitaine                                                                                       |
| article_id 🔗          | `UTINYINT` | Identifiant du type de nom                                                                                                     |
| article                 | `VARCHAR`  | Article                                                                                                                        |
| preposition             | `VARCHAR`  | Préposition                                                                                                                    |
| region_code 🔗         | `VARCHAR`  | Code de la région                                                                                                              |
| region_name             | `VARCHAR`  | Nom de la région                                                                                                               |
| region_identity         | `VARCHAR`  | Code et nom de la région                                                                                                       |
| collectivity_code 🔗   | `VARCHAR`  | Code de la région                                                                                                              |
| collectivity_name       | `VARCHAR`  | Nom de la région                                                                                                               |
| collectivity_identity   | `VARCHAR`  | Code et nom de la région                                                                                                       |
| department_code 🔗     | `VARCHAR`  | Code du département                                                                                                            |
| department_name         | `VARCHAR`  | Nom du département                                                                                                             |
| department_identity     | `VARCHAR`  | Code et nom du département                                                                                                     |
| arrondissement_code 🔗 | `VARCHAR`  | Code de l'arrondissement                                                                                                       |
| arrondissement_name     | `VARCHAR`  | Nom de l'arrondissement                                                                                                        |
| arrondissement_identity | `VARCHAR`  | Code et nom de l'arrondissement                                                                                                |
| canton_code 🔗         | `VARCHAR`  | Code du canton                                                                                                                 |
| canton_name             | `VARCHAR`  | Nom du canton                                                                                                                  |
| canton_identity         | `VARCHAR`  | Code et nom du canton                                                                                                          |

### `commune_unique`

La table `commune_unique` reprend les lignes de la table `commune` de type `COM`, `COMA` et `ARM`.

Cela permet d'avoir une unicité sur la colonne `commune_unique.code` et de promouvoir cette dernière clef primaire.

À l'exception de la colonne `key` désormais inutile et absente,
la table `communue_unique` a la même structure que la table `commune`.

## Exemples

### DuckDB

La base de données contient un schéma unique nommé `cog`.

Avec le terminal DuckDB :

```sql
install httpfs;
load httpfs;

attach or replace 'https://github.com/sfaut/data-cog/raw/refs/heads/master/v2025/cog@2025.duckdb' as my_db;

from my_db.cog.department
select all
    region_identity as Région, is_metropolitan as "Est métropolitaine ?",
    identity as Départment, group_name as "Libellé département"
order by all asc;
```

| Région             | Est métropolitaine ? | Départment          | Libellé département            |
|-------------------:|---------------------:|--------------------:|-------------------------------:|
| 01 – Guadeloupe    | false                | 971 – Guadeloupe    | Département de La Guadeloupe   |
| 02 – Martinique    | false                | 972 – Martinique    | Département de La Martinique   |
| 03 – Guyane        | false                | 973 – Guyane        | Département de La Guyane       |
| 04 – La Réunion    | false                | 974 – La Réunion    | Département de La Réunion      |
| 06 – Mayotte       | false                | 976 – Mayotte       | Département de Mayotte         |
| 11 – Île-de-France | true                 | 75 – Paris          | Département de Paris           |
| 11 – Île-de-France | true                 | 77 – Seine-et-Marne | Département de Seine-et-Marne  |
| 11 – Île-de-France | true                 | 78 – Yvelines       | Département des Yvelines       |
| 11 – Île-de-France | true                 | 91 – Essonne        | Département de L'Essonne       |
| 11 – Île-de-France | true                 | 92 – Hauts-de-Seine | Département des Hauts-de-Seine |
| ...

### PHP

```php
<?php

$url = 'https://github.com/sfaut/data-cog/raw/refs/heads/master/v2025/cog-departments@2025.csv';

$stream = fopen($url, mode: 'r');

$csv_options = ['separator' => ',', 'enclosure' => '"', 'escape' => '"'];

$header = fgetcsv($stream, ...$csv_options);

$data = [];
while ($record = fgetcsv($stream, ...$csv_options)) {
    $record = array_combine($header, $record);
    $data[] = $record;
}

print_r($data);
```

### Python

```python
import csv
import io
import urllib.request

url = "https://github.com/sfaut/data-cog/raw/refs/heads/master/v2025/cog-departments@2025.csv"

with urllib.request.urlopen(url) as response:
    io_wrapper = io.TextIOWrapper(response, encoding="utf-8")
    csv_reader = csv.DictReader(io_wrapper)
    data = list(csv_reader)

print(data)
```
