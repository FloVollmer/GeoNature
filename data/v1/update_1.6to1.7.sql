﻿-- IMPORTANT ! LIRE AVANT D'EXECUTER CE CODE --
--Modification des identifiants des listes pour compatibilité avec les applications GeoNature Mobile
--Dans GeoNature Mobile, les taxons sont filtrables par classe sur la base d'un id_classe. Ces id sont inscrits en dur dans le code des applications mobiles. 
--Dans la base GeoNature les classes taxonomiques sont configurables grace au vues v_nomade_classes qui utilisent les listes (taxonomie.bib_listes)
--Les id_liste ont donc été mis à jour pour être compatibles avec les id_classe des applications mobiles
--ATTENTION, le script ci-dessous permet de rentre compatible votre base avec geonature mobile sur la base des id_liste livrées avec la base.
--Si vous avez modifié les id_liste dans votre base GeoNature après son installation, vous ne devez pas exécuter ce script. 
--Vous pouvez vous en inspirer mais soyez vigilant.
--Si vous n'utilisez pas les applications GeoNature Mobile, vous pouvez laisser id_liste d'origine.
--ATENTION à ne lancer ce script d'update qu'une seule fois.
--Il est conseillé de lancer les instructions sql d'update ligne par ligne et de vérifier que les id_liste à mettre à jour correspondent bien à ceux de votre base.
--Les liens d'intégrité doivent mettre à jour les tables contactfaune.cor_critere_liste, taxonomie.cor_taxon_liste

UPDATE taxonomie.bib_listes set id_liste = id_liste + 10000; --gestion des conflits sur la clé primaire
DELETE FROM taxonomie.bib_listes WHERE id_liste = 11000; --Plantes vasculaires
DELETE FROM taxonomie.bib_listes WHERE id_liste = 10400; --Champignons
UPDATE taxonomie.bib_listes set id_liste = 1001 WHERE id_liste = 10001; --faune vertébré
UPDATE taxonomie.bib_listes set id_liste = 1002 WHERE id_liste = 10002; --faune invertébré
UPDATE taxonomie.bib_listes set id_liste = 1003 WHERE id_liste = 10003; --flore
UPDATE taxonomie.bib_listes set id_liste = 1004 WHERE id_liste = 11004; --fonge
UPDATE taxonomie.bib_listes set id_liste = 301 WHERE id_liste = 11001; --Bryophytes
UPDATE taxonomie.bib_listes set id_liste = 302 WHERE id_liste = 11002; --Lichens
UPDATE taxonomie.bib_listes set id_liste = 303 WHERE id_liste = 11003; --Algues
UPDATE taxonomie.bib_listes set id_liste = 1 WHERE id_liste = 10101; --Amphibiens
UPDATE taxonomie.bib_listes set id_liste = 7 WHERE id_liste = 10102; --Pycnogonides
UPDATE taxonomie.bib_listes set id_liste = 3 WHERE id_liste = 10103; --Entognathes
UPDATE taxonomie.bib_listes set id_liste = 4 WHERE id_liste = 10104; --Echinodermes
UPDATE taxonomie.bib_listes set id_liste = 5 WHERE id_liste = 10105; --Ecrevisses
UPDATE taxonomie.bib_listes set id_liste = 9 WHERE id_liste = 10106; --Insectes
UPDATE taxonomie.bib_listes set id_liste = 11 WHERE id_liste = 10107; --Mammifères
UPDATE taxonomie.bib_listes set id_liste = 12 WHERE id_liste = 10108; --Oiseaux
UPDATE taxonomie.bib_listes set id_liste = 13 WHERE id_liste = 10109; --Poissons
UPDATE taxonomie.bib_listes set id_liste = 14 WHERE id_liste = 10110; --Reptiles
UPDATE taxonomie.bib_listes set id_liste = 15 WHERE id_liste = 10111; --Myriapodes
UPDATE taxonomie.bib_listes set id_liste = 16 WHERE id_liste = 10112; --Arachnides
UPDATE taxonomie.bib_listes set id_liste = 101 WHERE id_liste = 10113; --Mollusques
UPDATE taxonomie.bib_listes set id_liste = 2 WHERE id_liste = 10114; --Vers
UPDATE taxonomie.bib_listes set id_liste = 20 WHERE id_liste = 10115; --Rotifères
UPDATE taxonomie.bib_listes set id_liste = 21 WHERE id_liste = 10116; --Tardigrades
UPDATE taxonomie.bib_listes set id_liste = 10 WHERE id_liste = 10201; --Bivalves
UPDATE taxonomie.bib_listes set id_liste = 8 WHERE id_liste = 10202; --Gastéropodes
UPDATE taxonomie.bib_listes set nom_liste = 'Crustacés' WHERE id_liste = 5; --Ecrevisses

UPDATE taxonomie.bib_listes set nom_liste = 'Faune vertébrée' WHERE id_liste = 1001; --faune vertébré
UPDATE taxonomie.bib_listes set nom_liste = 'Faune invertébrée' WHERE id_liste = 1002; --faune invertébré
UPDATE taxonomie.bib_listes set nom_liste = 'Flore' WHERE id_liste = 1003; --flore
UPDATE taxonomie.bib_listes set nom_liste = 'Fonge' WHERE id_liste = 1004; --fonge

INSERT INTO taxonomie.bib_listes (id_liste,nom_liste,desc_liste,picto) VALUES (305, 'Ptéridophytes',null, 'images/pictos/nopicto.gif'); --Ptéridophytes
INSERT INTO taxonomie.bib_listes (id_liste,nom_liste,desc_liste,picto) VALUES (306, 'Monocotylédones',null, 'images/pictos/nopicto.gif'); --Monocotylédones
INSERT INTO taxonomie.bib_listes (id_liste,nom_liste,desc_liste,picto) VALUES (307, 'Dycotylédones',null, 'images/pictos/nopicto.gif'); --Dycotylédones

CREATE OR REPLACE VIEW contactfaune.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste = ANY (ARRAY[1, 11, 12, 13, 14])
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text = 'Chordata'::text;

CREATE OR REPLACE VIEW contactinv.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste = ANY (ARRAY[2, 5, 8, 9, 10, 15, 16])
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text <> 'Chordata'::text AND t.regne::text = 'Animalia'::text;
  
CREATE OR REPLACE VIEW florepatri.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste > 300 AND l.id_liste < 400
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.regne::text = 'Plantae'::text;

CREATE OR REPLACE VIEW taxonomie.v_nomade_classes AS 
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM contactfaune.v_nomade_classes
UNION
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM contactinv.v_nomade_classes
UNION
 SELECT v_nomade_classes.id_classe,
    v_nomade_classes.nom_classe_fr,
    v_nomade_classes.desc_classe
   FROM florepatri.v_nomade_classes;
   
CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
 SELECT DISTINCT t.nom_francais,
    txr.lb_nom AS nom_latin,
    f2.bool AS patrimonial,
    f3.bool AS protection_stricte,
    txr.cd_ref,
    txr.cd_nom,
    txr.nom_valide,
    txr.famille,
    txr.ordre,
    txr.classe,
    txr.regne,
    prot.protections,
    l.id_liste,
    l.picto
   FROM taxonomie.taxref txr
     JOIN taxonomie.bib_taxons t ON txr.cd_nom = t.cd_nom
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN taxonomie.bib_listes l ON l.id_liste = ctl.id_liste AND (l.id_liste = ANY (ARRAY[1001, 1002, 1003, 1004]))
     LEFT JOIN ( SELECT tpe.cd_nom,
            string_agg((((tpa.arrete || ' '::text) || tpa.article::text) || '__'::text) || tpa.url::text, '#'::text) AS protections
           FROM taxonomie.taxref_protection_especes tpe
             JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true
          GROUP BY tpe.cd_nom) prot ON prot.cd_nom = t.cd_nom
     JOIN cor_boolean f2 ON f2.expression::text = t.filtre2::text
     JOIN cor_boolean f3 ON f3.expression::text = t.filtre3::text
     JOIN ( SELECT DISTINCT syntheseff.cd_nom
           FROM synthese.syntheseff
          WHERE syntheseff.supprime = false) s ON s.cd_nom = t.cd_nom
  ORDER BY t.nom_francais;
  
  -- Correction/fusion des menus faune et invertébrés. Seul le menu 9 (faune) existe à la livraison de GeoNature.
  -- Si vous souhaitez distinguer les observateurs "faune" des observateurs "invertébrés", il faut créer un menu dans utilisateurs.t_menus,
  -- mettre les observateurs ou les groupes d'observateurs en lien avec ce nouveau menu dans utilisateurs.cor_role_menu 
  -- puis modifier cette vue en conséquence
 CREATE OR REPLACE VIEW utilisateurs.v_nomade_observateurs_all AS 
( SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role,
    'fauna'::text AS mode
   FROM utilisateurs.t_roles r
  WHERE (r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE crm.id_menu = 9))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON r_1.id_role = crm.id_role AND crm.id_menu = 9 AND r_1.groupe = false))
  ORDER BY r.nom_role, r.prenom_role, r.id_role)
UNION
( SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role,
    'flora'::text AS mode
   FROM utilisateurs.t_roles r
  WHERE (r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE crm.id_menu = 10))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON r_1.id_role = crm.id_role AND crm.id_menu = 10 AND r_1.groupe = false))
  ORDER BY r.nom_role, r.prenom_role, r.id_role)
UNION
( SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role,
    'inv'::text AS mode
   FROM utilisateurs.t_roles r
  WHERE (r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE crm.id_menu = 9))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON r_1.id_role = crm.id_role AND crm.id_menu = 9 AND r_1.groupe = false))
  ORDER BY r.nom_role, r.prenom_role, r.id_role);
 
 --Création de 2 vues manquantes pour le fonctionnement des applications mobiles
 CREATE OR REPLACE VIEW florepatri.v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_liste = l.id_liste
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctl.id_taxon
          WHERE l.id_liste >= 300 AND l.id_liste < 400
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.regne::text = 'Plantae'::text;

ALTER TABLE florepatri.v_nomade_classes
  OWNER TO geonatuser;
GRANT ALL ON TABLE florepatri.v_nomade_classes TO geonatuser;


CREATE OR REPLACE VIEW public.v_mobile_recherche AS 
( SELECT ap.indexap AS gid,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    st_asgeojson(st_transform(ap.the_geom_2154, 4326)) AS geom_4326,
    st_x(st_transform(st_centroid(ap.the_geom_2154), 4326)) AS centroid_x,
    st_y(st_transform(st_centroid(ap.the_geom_2154), 4326)) AS centroid_y
   FROM florepatri.t_apresence ap
     JOIN florepatri.t_zprospection zp ON ap.indexzp = zp.indexzp
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = ap.indexzp
  WHERE ap.supprime = false AND st_isvalid(ap.the_geom_2154) AND ap.topo_valid = true
  ORDER BY zp.dateobs DESC)
UNION
( SELECT cft.id_station AS gid,
    s.dateobs,
    t.latin AS taxon,
    o.observateurs,
    st_asgeojson(st_transform(s.the_geom_3857, 4326)) AS geom_4326,
    st_x(st_transform(st_centroid(s.the_geom_3857), 4326)) AS centroid_x,
    st_y(st_transform(st_centroid(s.the_geom_3857), 4326)) AS centroid_y
   FROM florestation.cor_fs_taxon cft
     JOIN florestation.t_stations_fs s ON s.id_station = cft.id_station
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = cft.cd_nom
     JOIN ( SELECT c.id_station,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florestation.cor_fs_observateur c
             JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
          GROUP BY c.id_station) o ON o.id_station = cft.id_station
  WHERE cft.supprime = false AND st_isvalid(s.the_geom_3857)
  ORDER BY s.dateobs DESC);

ALTER TABLE public.v_mobile_recherche
  OWNER TO geonatuser;
GRANT ALL ON TABLE public.v_mobile_recherche TO geonatuser;

--Vues pour le module export
CREATE OR REPLACE VIEW synthese.v_export_sinp AS 
 SELECT s.id_synthese,
    o.nom_organisme,
    s.dateobs,
    s.observateurs,
    t.cd_nom,
    t.nom_latin,
    c.nom_critere_synthese AS critere,
    s.effectif_total,
    s.remarques,
    p.nom_programme,
    s.insee,
    s.altitude_retenue AS altitude,
    st_x(st_transform(s.the_geom_point, 2154))::integer AS x,
    st_y(st_transform(s.the_geom_point, 2154))::integer AS y,
    s.derniere_action,
    s.date_insert,
    s.date_update
   FROM synthese.syntheseff s
     JOIN taxonomie.taxref tx ON tx.cd_nom = s.cd_nom
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = s.id_organisme
     JOIN taxonomie.bib_taxons t ON t.cd_nom = s.cd_nom
     LEFT JOIN synthese.bib_criteres_synthese c ON c.id_critere_synthese = s.id_critere_synthese
     LEFT JOIN meta.bib_lots l ON l.id_lot = s.id_lot
     LEFT JOIN meta.bib_programmes p ON p.id_programme = l.id_programme
  WHERE s.supprime = false;
ALTER TABLE synthese.v_export_sinp
  OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_export_sinp TO geonatuser;

CREATE OR REPLACE VIEW synthese.v_export_sinp_deleted AS 
 SELECT s.id_synthese
   FROM synthese.syntheseff s
     JOIN taxonomie.taxref tx ON tx.cd_nom = s.cd_nom
  WHERE s.supprime = true;
ALTER TABLE synthese.v_export_sinp_deleted
  OWNER TO geonatuser;
  
--FK MANQUANTE
ALTER TABLE contactflore.cor_unite_taxon_cflore
  ADD CONSTRAINT fk_cor_unite_taxon_cflore_bib_taxons FOREIGN KEY (id_taxon)
      REFERENCES taxonomie.bib_taxons (id_taxon) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;
      
--CORRECTION DE TRIGGERS A LA SOURCE D'UN BUG DE SAISIE POUR LES TAXONS DONT LE TAXON DE REFERENCE N'EST PAS PRESENT DANS 'taxonomie.bib_taxons'

-- Function: contactinv.synthese_insert_releve_inv()
-- DROP FUNCTION contactinv.synthese_insert_releve_inv();
CREATE OR REPLACE FUNCTION contactinv.synthese_insert_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
	fiche RECORD;
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
	unite integer;
	idsource integer;
	cdnom integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	
	--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;
	SELECT INTO mesobservateurs o.observateurs FROM contactinv.t_releves_inv r
	JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
	LEFT JOIN (
                SELECT id_inv, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactinv.cor_role_fiche_inv c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_inv
            ) o ON o.id_inv = f.id_inv
	WHERE r.id_releve_inv = new.id_releve_inv;
    
	--On fait le INSERT dans syntheseff
	INSERT INTO synthese.syntheseff (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		id_precision,
		cd_nom,
		insee,
		dateobs,
		observateurs,
		determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total
	)
	VALUES(
	idsource,
	new.id_releve_inv,
	'f'||new.id_inv||'-r'||new.id_releve_inv,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	cdnom,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
	new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na
	);
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.synthese_insert_releve_inv()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactinv.synthese_insert_releve_inv() TO geonatuser;
GRANT EXECUTE ON FUNCTION contactinv.synthese_insert_releve_inv() TO public;

-- Function: contactfaune.synthese_insert_releve_cf()
-- DROP FUNCTION contactfaune.synthese_insert_releve_cf();
CREATE OR REPLACE FUNCTION contactfaune.synthese_insert_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
	fiche RECORD;
	mesobservateurs character varying(255);
	criteresynthese integer;
	idsource integer;
	idsourcem integer;
	idsourcecf integer;
	unite integer;
	cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsourcem id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' AND nom_source = 'Mortalité';
	SELECT INTO idsourcecf id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' AND nom_source = 'Contact faune';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	--Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;
	-- Récupération du id_source selon le critère d'observation, Si critère = 2 alors on est dans une source mortalité (=2) sinon cf (=1)
	IF criteresynthese = 2 THEN idsource = idsourcem;
	ELSE
	    idsource = idsourcecf;
	END IF;
	SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
	JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
	LEFT JOIN (
                SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactfaune.cor_role_fiche_cf c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_cf
            ) o ON o.id_cf = f.id_cf
	WHERE r.id_releve_cf = new.id_releve_cf;
	
	INSERT INTO synthese.syntheseff (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		id_precision,
		cd_nom,
		insee,
		dateobs,
		observateurs,
		determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total
	)
	VALUES(
	idsource,
	new.id_releve_cf,
	'f'||new.id_cf||'-r'||new.id_releve_cf,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	cdnom,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
        new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
	);
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.synthese_insert_releve_cf()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_insert_releve_cf() TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_insert_releve_cf() TO public;

-- Function: contactflore.synthese_insert_releve_cflore()
-- DROP FUNCTION contactflore.synthese_insert_releve_cflore();
CREATE OR REPLACE FUNCTION contactflore.synthese_insert_releve_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
	fiche RECORD;
	mesobservateurs character varying(255);
	idsourcecflore integer;
    cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsourcecflore id_source FROM synthese.bib_sources  WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore' AND nom_source = 'Contact flore';
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	--Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactflore.t_fiches_cflore WHERE id_cflore = new.id_cflore;
	
	SELECT INTO mesobservateurs o.observateurs FROM contactflore.t_releves_cflore r
	JOIN contactflore.t_fiches_cflore f ON f.id_cflore = r.id_cflore
	LEFT JOIN (
                SELECT id_cflore, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactflore.cor_role_fiche_cflore c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_cflore
            ) o ON o.id_cflore = f.id_cflore
	WHERE r.id_releve_cflore = new.id_releve_cflore;
	
	INSERT INTO synthese.syntheseff (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		id_precision,
		cd_nom,
		insee,
		dateobs,
		observateurs,
		determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot
	)
	VALUES(
	idsourcecflore,
	new.id_releve_cflore,
	'f'||new.id_cflore||'-r'||new.id_releve_cflore,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	cdnom,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
        new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot
	);
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactflore.synthese_insert_releve_cflore()
  OWNER TO geonatuser;
  
-- Function: contactflore.synthese_update_releve_cflore()
-- DROP FUNCTION contactflore.synthese_update_releve_cflore();
CREATE OR REPLACE FUNCTION contactflore.synthese_update_releve_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
    test integer;
    sources RECORD;
    idsourcecflore integer;
    cdnom integer;
BEGIN
    
    --Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsourcecflore id_source FROM synthese.bib_sources  WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = old.id_releve_cflore::text AND (id_source = idsourcecflore);
	IF test IS NOT NULL THEN
		

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cflore,
			code_fiche_source = 'f'||new.id_cflore||'-r'||new.id_releve_cflore,
			cd_nom =cdnom,
			remarques = new.commentaire,
			determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime
		WHERE id_fiche_source = old.id_releve_cflore::text AND (id_source = idsourcecflore); -- Ici on utilise le OLD id_releve_cflore pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_cflore
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_cflore
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactflore.synthese_update_releve_cflore()
  OWNER TO geonatuser;

-- Function: contactfaune.synthese_update_releve_cf()
-- DROP FUNCTION contactfaune.synthese_update_releve_cf();
CREATE OR REPLACE FUNCTION contactfaune.synthese_update_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
    test integer;
    criteresynthese integer;
    sources RECORD;
    idsourcem integer;
    idsourcecf integer;
    cdnom integer;
BEGIN
    
	--on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
        FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
	    IF sources.url = 'cf' THEN
	        idsourcecf = sources.id_source;
	    ELSIF sources.url = 'mortalite' THEN
	        idsourcem = sources.id_source;
	    END IF;
        END LOOP;
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
	IF test IS NOT NULL THEN
		SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cf,
			code_fiche_source = 'f'||new.id_cf||'-r'||new.id_releve_cf,
			cd_nom = cdnom,
			remarques = new.commentaire,
			determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
		WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem); -- Ici on utilise le OLD id_releve_cf pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_cf
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_cf
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.synthese_update_releve_cf()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_update_releve_cf() TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_update_releve_cf() TO public;

-- Function: contactinv.synthese_update_releve_inv()
-- DROP FUNCTION contactinv.synthese_update_releve_inv();
CREATE OR REPLACE FUNCTION contactinv.synthese_update_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
        idsource integer;
        cdnom integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
	IF test IS NOT NULL THEN
		--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
		SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_inv,
			code_fiche_source = 'f'||new.id_inv||'-r'||new.id_releve_inv,
			cd_nom = cdnom,
			remarques = new.commentaire,
			determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na
		WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text; -- Ici on utilise le OLD id_releve_inv pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_inv
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_inv
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.synthese_update_releve_inv()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactinv.synthese_update_releve_inv() TO geonatuser;
GRANT EXECUTE ON FUNCTION contactinv.synthese_update_releve_inv() TO public;