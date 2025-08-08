install httpfs;
load httpfs;

attach or replace 'cog@2025.duckdb' as sfaut;
create schema if not exists sfaut.cog;
use sfaut.cog;

-- -------------------------------------------------------------------------- --
-- Name types --------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --

create or replace table article (
  id utinyint primary key,
  article varchar not null,
  preposition varchar not null,
  comment varchar not null,
);

insert into article (id, article, preposition, comment)
values
  (0, '', 'de ', 'Pas d''article et le nom commence par une consonne sauf H muet'),
  (1, '', 'd''', 'Pas d''article et le nom commence par une voyelle ou un H muet'),
  (2, 'Le ', 'du ', ''),
  (3, 'La ', 'de La ', ''),
  (4, 'Les ', 'des ', ''),
  (5, 'L''', 'de L''', ''),
  (6, 'aux ', 'des ', ''),
  (7, 'Las ', 'de Las ', ''),
  (8, 'Los ', 'de Los ', ''),
;

-- ------------------------------------------------------------------------ --
-- Countries -------------------------------------------------------------- --
-- ------------------------------------------------------------------------ --

create or replace table country (
  code varchar primary key,
  iso2_code varchar not null,
  iso3_code varchar not null,
  num3_code varchar not null,
  name varchar not null,
  official_name varchar not null, -- Nom officiel du pays, ou composition détaillée du territoire
  actual_id utinyint not null,
  actual_name varchar not null,
  parent_code varchar not null,
  first_appearance_year usmallint not null, -- First appearance in COG
);

insert into country by name
from read_csv(
  'https://www.insee.fr/fr/statistiques/fichier/8377162/v_pays_territoire_2025.csv',
  types = { CRPAY: VARCHAR }
)
select all
  COG as code,
  coalesce(CODEISO2, '') as iso2_code,
  coalesce(CODEISO3, '') as iso3_code,
  coalesce(CODENUM3, '') as num3_code,
  LIBCOG as name,
  LIBENR as official_name,
  ACTUAL as actual_id,
  case ACTUAL
    when 1 then 'Actuel'
    when 4 then 'Territoire ayant son propre code officiel géographique'
  end as actual_name,
  coalesce(CRPAY, '') as parent_code,
  coalesce(ANI, 0) as first_appearance_year,
order by COG asc;

-- -------------------------------------------------------------------------- --
-- Regions ------------------------------------------------------------------ --
-- -------------------------------------------------------------------------- --

create or replace table region (
  code varchar primary key,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  identity varchar not null,
  group_name varchar not null,
  is_metropolitan boolean not null,
  article_id utinyint not null,
  article varchar not null,
  preposition varchar not null,
  capital_code varchar not null,
  capital_name varchar not null,
);

insert into region by name
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_region_2025.csv' as region
inner join article on region.TNCC = article.id
select all
  region.REG as code,
  region.LIBELLE as name,
  region.NCCENR as single_name,
  region.NCC as simple_name,
  region.REG || ' – ' || region.LIBELLE as identity,
  'Région ' || article.preposition || region.NCCENR as group_name,
  region.REG in ('11', '24', '27', '28', '32', '44', '52', '53', '75', '76', '84', '93', '94') as is_metropolitan,
  article.id as article_id,
  article.article,
  article.preposition,
  region.CHEFLIEU as capital_code,
  '' as capital_name,
order by region.REG asc;

-- -------------------------------------------------------------------------- --
-- Local authorities with departmental responsibilities --------------------- --
-- -------------------------------------------------------------------------- --

create or replace table collectivity (
  code varchar, -- primary key,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  identity varchar not null,
  is_metropolitan boolean not null,
  capital_code varchar not null,
  capital_name varchar not null,
  -- Region
  region_code varchar not null,
  region_name varchar not null,
  region_identity varchar not null,
);

insert into collectivity by name
with type (id, name) as (
  values
    (1, 'Collectivité'),
    (2, 'Collectivité européenne'),
    (3, 'Collectivité territoriale unique'),
    (4, 'Conseil départemental'),
    (5, 'Métropole'),
    (6, 'Ville'),
)
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_ctcd_2025.csv' as collectivity
inner join article on collectivity.TNCC = article.id
inner join region on collectivity.REG = region.code
select all
  collectivity.CTCD as code,
  collectivity.LIBELLE as name,
  collectivity.NCCENR as single_name,
  collectivity.NCC as simple_name,
  collectivity.CTCD || ' – ' || collectivity.LIBELLE as identity,
  region.is_metropolitan,
  collectivity.CHEFLIEU as capital_code,
  '' as capital_name,
  -- Region
  region.code as region_code,
  region.name as region_name,
  region.identity as region_identity,
order by collectivity.CTCD asc;

-- -------------------------------------------------------------------------- --
-- Departments -------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --

create or replace table department (
  code varchar primary key,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  identity varchar not null,
  group_name varchar not null,
  is_metropolitan boolean not null,
  article_id utinyint not null,
  article varchar not null,
  preposition varchar not null,
  capital_code varchar not null,
  capital_name varchar not null,
  -- Region
  region_code varchar not null,
  region_name varchar not null,
  region_identity varchar not null,
);

insert into department by name
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_departement_2025.csv' as department
inner join article on department.TNCC = article.id
inner join region on department.REG = region.code
select all
  department.DEP as code,
  department.LIBELLE as name,
  department.NCCENR as single_name,
  department.NCC as simple_name,
  department.DEP || ' – ' || department.LIBELLE as identity,
  'Département ' || article.preposition || department.NCCENR as group_name,
  region.is_metropolitan,
  article.id as article_id,
  article.article,
  article.preposition,
  department.CHEFLIEU as capital_code,
  '' as capital_name,
  region.code as region_code,
  region.name as region_name,
  region.identity as region_identity,
order by department.DEP asc;

-- -------------------------------------------------------------------------- --
-- Arrondissements ---------------------------------------------------------- --
-- -------------------------------------------------------------------------- --

create or replace table arrondissement (
  code varchar primary key,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  identity varchar not null,
  group_name varchar not null,
  is_metropolitan boolean not null,
  article_id utinyint not null,
  article varchar not null,
  preposition varchar not null,
  capital_code varchar not null,
  capital_name varchar not null,
  -- Region
  region_code varchar not null,
  region_name varchar not null,
  region_identity varchar not null,
  -- Department
  department_code varchar not null,
  department_name varchar not null,
  department_identity varchar not null,
);

insert into arrondissement by name
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_arrondissement_2025.csv' as arrondissement
inner join article on arrondissement.TNCC = article.id
inner join region on arrondissement.REG = region.code
inner join department on arrondissement.DEP = department.code
select all
  arrondissement.ARR as code,
  arrondissement.LIBELLE as name,
  arrondissement.NCCENR as single_name,
  arrondissement.NCC as simple_name,
  arrondissement.ARR || ' – ' || arrondissement.LIBELLE as identity,
  'Arrondissement ' || article.preposition || arrondissement.NCCENR as group_name,
  region.is_metropolitan,
  article.id as article_id,
  article.article,
  article.preposition,
  arrondissement.CHEFLIEU as capital_code,
  '' as capital_name,
  -- Region
  region.code as region_code,
  region.name as region_name,
  region.identity as region_identity,
  -- Department
  department.code as department_code,
  department.name as department_name,
  department.identity as department_identity,
order by arrondissement.ARR asc;

-- -------------------------------------------------------------------------- --
-- Cantons ------------------------------------------------------------------ --
-- -------------------------------------------------------------------------- --

create or replace table canton (
  code varchar primary key,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  identity varchar not null,
  group_name varchar not null,
  is_metropolitan boolean not null,
  type_code varchar not null,
  type_name varchar not null,
  composition_id utinyint not null,
  composition_name varchar not null,
  article_id utinyint not null,
  article varchar not null,
  preposition varchar not null,
  -- Capital
  capital_code varchar not null, -- Bureau Central
  capital_name varchar not null,
  -- Region
  region_code varchar not null,
  region_name varchar not null,
  region_identity varchar not null,
  -- Department
  department_code varchar not null,
  department_name varchar not null,
  department_identity varchar not null,
);

insert into canton by name
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_canton_2025.csv' as canton
inner join article on canton.TNCC = article.id
inner join region on canton.REG = region.code
inner join department on canton.DEP = department.code
select all
  canton.CAN as code,
  canton.LIBELLE as name,
  canton.NCCENR as single_name,
  canton.NCC as simple_name,
  canton.CAN || ' – ' || canton.LIBELLE as identity,
  'Canton ' || article.preposition || canton.NCCENR as group_name,
  region.is_metropolitan,
  canton.TYPECT as type_code,
  case canton.TYPECT
    when 'C' then 'Canton'
    when 'V' then 'Canton-Ville (ou pseudo-canton)'
    when 'N' then 'Canton « fictif » pour communes nouvelles'
  end as type_name,
  coalesce(canton.COMPCT, 0) as composition_id,
  case canton.COMPCT
    when 1 then 'Canton composé de commune(s) entière(s)'
    when 2 then 'Canton composé d''une fraction d''une commune et de commune(s) entière(s)'
    when 3 then 'Canton composé de fractions de plusieurs communes et de commune(s) entière(s)'
    when 4 then 'Canton composé d''une fraction de commune'
    when 5 then 'Canton composé de fractions de plusieurs communes'
    else '' -- Only for type code "N" and "V"
  end as composition_name,
  article.id as article_id,
  article.article,
  article.preposition,
  -- Capital
  BURCENTRAL as capital_code, -- Bureau Central
  '' as capital_name,
  -- Region
  region.code as region_code,
  region.name as region_name,
  region.identity as region_identity,
  -- Department
  department.code as department_code,
  department.name as department_name,
  department.identity as department_identity,
order by canton.CAN asc
;

-- -------------------------------------------------------------------------- --
-- Communes ----------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --

create or replace table commune (
  key varchar primary key,
  code varchar not null,
  type_code varchar not null,
  type_name varchar not null,
  parent_code varchar not null,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  group_name varchar not null,
  is_metropolitan boolean not null,
  article_id utinyint not null,
  article varchar not null,
  preposition varchar not null,
  -- Region
  region_code varchar not null,
  region_name varchar not null,
  region_identity varchar not null,
  -- Collectivity
  collectivity_code varchar not null,
  collectivity_name varchar not null,
  collectivity_identity varchar not null,
  -- Department
  department_code varchar not null,
  department_name varchar not null,
  department_identity varchar not null,
  -- Arrondissement
  -- No arrondissement for Mayotte region/department
  arrondissement_code varchar not null,
  arrondissement_name varchar not null,
  arrondissement_identity varchar not null,
  -- Canton
  -- No canton form Martinique and Guyane regions/departments
  canton_code varchar not null,
  canton_name varchar not null,
  canton_identity varchar not null,
  -- Contrainte
  unique (code, type_code),
);

insert into commune by name
with commune as (
  from read_csv(
    'https://www.insee.fr/fr/statistiques/fichier/8377162/v_commune_2025.csv',
    types = { REG: 'VARCHAR' }
  )
)
from commune
inner join article on commune.TNCC = article.id
left outer join commune as commune_parent on commune.COMPARENT = commune_parent.COM and commune_parent.TYPECOM = 'COM'
inner join region on coalesce(commune.REG, commune_parent.REG) = region.code
inner join collectivity on coalesce(commune.CTCD, commune_parent.CTCD) = collectivity.code
inner join department on coalesce(commune.DEP, commune_parent.DEP) = department.code
left outer join arrondissement on coalesce(commune.ARR, commune_parent.ARR) = arrondissement.code -- No arrondissement for Mayotte
left outer join canton on coalesce(commune.CAN, commune_parent.CAN) = canton.code -- No canton for Martinique and Guyane
select all
  commune.COM || '/' || commune.TYPECOM as key,
  commune.COM as code,
  commune.TYPECOM as type_code,
  case commune.TYPECOM
    when 'COM' then 'Commune'
    when 'COMA'	then 'Commune associée'
    when 'COMD'	then 'Commune déléguée'
    when 'ARM' then 'Arrondissement municipal'
  end as type_name,
  coalesce(commune.COMPARENT, '') as parent_code,
  commune.LIBELLE as name,
  commune.NCCENR as single_name,
  commune.NCC as simple_name,
  'Commune ' || article.preposition || commune.NCCENR as group_name,
  region.is_metropolitan,
  article.id as article_id,
  article.article,
  article.preposition,
  -- Region
  region.code as region_code,
  region.name as region_name,
  region.identity as region_identity,
  -- Collectivity
  collectivity.code as collectivity_code,
  collectivity.name as collectivity_name,
  collectivity.identity as collectivity_identity,
  -- Department
  department.code as department_code,
  department.name as department_name,
  department.identity as department_identity,
  -- Arrondissement
  -- No arrondissement for Mayotte region/department
  coalesce(arrondissement.code, '') as arrondissement_code,
  coalesce(arrondissement.name, '') as arrondissement_name,
  coalesce(arrondissement.identity, '') as arrondissement_identity,
  -- Canton
  -- No canton form Martinique and Guyane regions/departments
  coalesce(canton.code, '') as canton_code,
  coalesce(canton.name, '') as canton_name,
  coalesce(canton.identity, '') as canton_identity,
order by commune.COM || '/' || commune.TYPECOM asc;

create or replace table commune_unique (
  code varchar primary key,
  type_code varchar not null,
  type_name varchar not null,
  parent_code varchar not null,
  name varchar not null,
  single_name varchar not null,
  simple_name varchar not null,
  group_name varchar not null,
  is_metropolitan boolean not null,
  article_id utinyint not null,
  article varchar not null,
  preposition varchar not null,
  -- Region
  region_code varchar not null,
  region_name varchar not null,
  region_identity varchar not null,
  -- Collectivity
  collectivity_code varchar not null,
  collectivity_name varchar not null,
  collectivity_identity varchar not null,
  -- Department
  department_code varchar not null,
  department_name varchar not null,
  department_identity varchar not null,
  -- Arrondissement
  -- No arrondissement for Mayotte region/department
  arrondissement_code varchar not null,
  arrondissement_name varchar not null,
  arrondissement_identity varchar not null,
  -- Canton
  -- No canton form Martinique and Guyane regions/departments
  canton_code varchar not null,
  canton_name varchar not null,
  canton_identity varchar not null,
);

insert into commune_unique by name
from commune
select all * exclude (key)
where type_code in ('COM', 'COMA', 'ARM')
order by commune.code asc;

-- -------------------------------------------------------------------------- --
-- Capital names hydration -------------------------------------------------- --
-- -------------------------------------------------------------------------- --

update region
set capital_name = commune_unique.name
from commune_unique
where commune_unique.code = region.capital_code;

update collectivity
set capital_name = commune_unique.name
from commune_unique
where commune_unique.code = collectivity.capital_code;

update department
set capital_name = commune_unique.name
from commune_unique
where commune_unique.code = department.capital_code;

update arrondissement
set capital_name = commune_unique.name
from commune_unique
where commune_unique.code = arrondissement.capital_code;

update canton
set capital_name = commune_unique.name
from commune_unique
where commune_unique.code = canton.capital_code;

-- -------------------------------------------------------------------------- --
-- Files generation --------------------------------------------------------- --
-- -------------------------------------------------------------------------- --

copy article to 'cog-articles@2025.parquet';
copy article to 'cog-articles@2025.csv';
copy article to 'cog-articles@2025.json' with (array true);
copy article to 'cog-articles@2025.ndjson';

copy country to 'cog-countries@2025.parquet';
copy country to 'cog-countries@2025.csv';
copy country to 'cog-countries@2025.json' with (array true);
copy country to 'cog-countries@2025.ndjson';

copy region to 'cog-regions@2025.parquet';
copy region to 'cog-regions@2025.csv';
copy region to 'cog-regions@2025.json' with (array true);
copy region to 'cog-regions@2025.ndjson';

copy collectivity to 'cog-collectivities@2025.parquet';
copy collectivity to 'cog-collectivities@2025.csv';
copy collectivity to 'cog-collectivities@2025.json' with (array true);
copy collectivity to 'cog-collectivities@2025.ndjson';

copy department to 'cog-departments@2025.parquet';
copy department to 'cog-departments@2025.csv';
copy department to 'cog-departments@2025.json' with (array true);
copy department to 'cog-departments@2025.ndjson';

copy arrondissement to 'cog-arrondissements@2025.parquet';
copy arrondissement to 'cog-arrondissements@2025.csv';
copy arrondissement to 'cog-arrondissements@2025.json' with (array true);
copy arrondissement to 'cog-arrondissements@2025.ndjson';

copy canton to 'cog-cantons@2025.parquet';
copy canton to 'cog-cantons@2025.csv';
copy canton to 'cog-cantons@2025.json' with (array true);
copy canton to 'cog-cantons@2025.ndjson';

copy commune to 'cog-communes@2025.parquet';
copy commune to 'cog-communes@2025.csv';
copy commune to 'cog-communes@2025.json' with (array true);
copy commune to 'cog-communes@2025.ndjson';

copy commune_unique to 'cog-communes-unique@2025.parquet';
copy commune_unique to 'cog-communes-unique@2025.csv';
copy commune_unique to 'cog-communes-unique@2025.json' with (array true);
copy commune_unique to 'cog-communes-unique@2025.ndjson';
