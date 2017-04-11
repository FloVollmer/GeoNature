﻿--Optimisation des vues permettant le chargement de la liste des taxons
CREATE TABLE cor_boolean
(
  expression character varying(25) NOT NULL,
  bool boolean,
  CONSTRAINT cor_boolean_pkey PRIMARY KEY (expression)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE cor_boolean OWNER TO geonatuser;
INSERT INTO cor_boolean VALUES('oui',true);
INSERT INTO cor_boolean VALUES('non',false);

DROP VIEW synthese.v_taxons_synthese;
CREATE OR REPLACE VIEW synthese.v_taxons_synthese AS 
SELECT DISTINCT
    t.nom_francais,
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
JOIN taxonomie.bib_listes l ON l.id_liste = ctl.id_liste AND (l.id_liste = ANY (ARRAY[3, 101, 105, 106, 107, 108, 109, 110, 111, 112, 113]))
LEFT JOIN 
	( 
	SELECT cd_nom, STRING_AGG(((((arrete || ' '::text) || article::text) || '__'::text) || url::text), '#'::text) AS protections
        FROM taxonomie.taxref_protection_especes tpe
        JOIN taxonomie.taxref_protection_articles tpa ON tpa.cd_protection::text = tpe.cd_protection::text AND tpa.concerne_mon_territoire = true
        GROUP BY cd_nom
        ) prot ON prot.cd_nom = t.cd_nom
JOIN public.cor_boolean f2 ON f2.expression = t.filtre2
JOIN public.cor_boolean f3 ON f3.expression = t.filtre3
JOIN (SELECT DISTINCT cd_nom FROM synthese.syntheseff) s ON s.cd_nom = t.cd_nom
ORDER BY t.nom_francais;

ALTER TABLE synthese.v_taxons_synthese
  OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_taxons_synthese TO geonatuser;
GRANT ALL ON TABLE synthese.v_taxons_synthese TO postgres;


 WITH taxon AS (
         SELECT 
	    tx.id_taxon,
            tx.nom_latin,
            tx.nom_francais,
            taxref.cd_nom,
            taxref.id_statut,
            taxref.id_habitat,
            taxref.id_rang,
            taxref.regne,
            taxref.phylum,
            taxref.classe,
            taxref.ordre,
            taxref.famille,
            taxref.cd_taxsup,
            taxref.cd_ref,
            taxref.lb_nom,
            taxref.lb_auteur,
            taxref.nom_complet,
            taxref.nom_valide,
            taxref.nom_vern,
            taxref.nom_vern_eng,
            taxref.group1_inpn,
            taxref.group2_inpn
	FROM 
	( 
		SELECT tx_1.id_taxon,
                    taxref_1.cd_nom,
                    taxref_1.cd_ref,
                    taxref_1.lb_nom AS nom_latin,
                        CASE
                            WHEN tx_1.nom_francais IS NULL THEN taxref_1.lb_nom
                            WHEN tx_1.nom_francais::text = ''::text THEN taxref_1.lb_nom
                            ELSE tx_1.nom_francais
                        END AS nom_francais
		FROM taxonomie.taxref taxref_1
		LEFT JOIN taxonomie.bib_taxons tx_1 ON tx_1.cd_nom = taxref_1.cd_nom
		WHERE (taxref_1.cd_nom IN (SELECT DISTINCT cd_nom FROM synthese.syntheseff))
	) tx
        JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
)
SELECT t.id_taxon,
    t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre,
    COALESCE(t.id_famille, t.id_ordre) AS id_famille,
    COALESCE(t.nom_famille, ' Sans famille dans taxref'::character varying) AS nom_famille
FROM 
	( 
	SELECT DISTINCT t_1.id_taxon,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT taxref.cd_nom FROM taxonomie.taxref WHERE taxref.id_rang = 'KD'::bpchar AND taxref.lb_nom::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre,
            f.cd_nom AS id_famille,
            t_1.famille AS nom_famille
	FROM taxon t_1
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.lb_nom
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'PH'::bpchar AND taxref.cd_nom = taxref.cd_ref) ph ON ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.lb_nom
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'CL'::bpchar AND taxref.cd_nom = taxref.cd_ref) cl ON cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.lb_nom
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'OR'::bpchar AND taxref.cd_nom = taxref.cd_ref) ord ON ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL
	LEFT JOIN ( SELECT taxref.cd_nom,
                    taxref.id_rang,
                    taxref.lb_nom,
                    taxref.phylum,
                    taxref.famille
                   FROM taxonomie.taxref
                   WHERE taxref.id_rang = 'FM'::bpchar AND taxref.cd_nom = taxref.cd_ref) f ON f.lb_nom::text = t_1.famille::text AND f.phylum::text = t_1.phylum::text AND NOT t_1.famille IS NULL
	) t;
    

DROP VIEW synthese.v_tree_taxons_synthese;

CREATE OR REPLACE VIEW synthese.v_tree_taxons_synthese AS 
 WITH taxon AS (
         SELECT tx.id_taxon,
            tx.nom_latin,
            tx.nom_francais,
            taxref.cd_nom,
            taxref.id_statut,
            taxref.id_habitat,
            taxref.id_rang,
            taxref.regne,
            taxref.phylum,
            taxref.classe,
            taxref.ordre,
            taxref.famille,
            taxref.cd_taxsup,
            taxref.cd_ref,
            taxref.lb_nom,
            taxref.lb_auteur,
            taxref.nom_complet,
            taxref.nom_valide,
            taxref.nom_vern,
            taxref.nom_vern_eng,
            taxref.group1_inpn,
            taxref.group2_inpn
           FROM ( SELECT tx_1.id_taxon,
                    taxref_1.cd_nom,
                    taxref_1.cd_ref,
                    taxref_1.lb_nom AS nom_latin,
                        CASE
                            WHEN tx_1.nom_francais IS NULL THEN taxref_1.lb_nom
                            WHEN tx_1.nom_francais::text = ''::text THEN taxref_1.lb_nom
                            ELSE tx_1.nom_francais
                        END AS nom_francais
                   FROM taxonomie.taxref taxref_1
                     LEFT JOIN taxonomie.bib_taxons tx_1 ON tx_1.cd_nom = taxref_1.cd_nom
                  WHERE (taxref_1.cd_nom IN ( SELECT DISTINCT syntheseff.cd_nom
                           FROM synthese.syntheseff))) tx
             JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
        )
 SELECT t.id_taxon,
    t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre,
    COALESCE(t.id_famille, t.id_ordre) AS id_famille,
    COALESCE(t.nom_famille, ' Sans famille dans taxref'::character varying) AS nom_famille
   FROM ( SELECT DISTINCT t_1.id_taxon,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT taxref.cd_nom
                   FROM taxonomie.taxref
                  WHERE taxref.id_rang = 'KD'::bpchar AND taxref.lb_nom::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre,
            f.cd_nom AS id_famille,
            t_1.famille AS nom_famille
           FROM taxon t_1
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang = 'PH'::bpchar AND ph.cd_nom = ph.cd_ref AND ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang = 'CL'::bpchar AND cl.cd_nom = cl.cd_ref AND cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang = 'OR'::bpchar AND ord.cd_nom = ord.cd_ref AND ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL
             LEFT JOIN taxonomie.taxref f ON f.id_rang = 'FM'::bpchar AND f.cd_nom = f.cd_ref AND f.lb_nom::text = t_1.famille::text AND f.phylum::text = t_1.phylum::text AND NOT t_1.famille IS NULL) t;

ALTER TABLE synthese.v_tree_taxons_synthese
  OWNER TO geonatuser;
GRANT ALL ON TABLE synthese.v_tree_taxons_synthese TO geonatuser;

--Généricité
ALTER TABLE meta.bib_programmes RENAME sitpn TO programme_public;
ALTER TABLE meta.bib_programmes RENAME desc_programme_sitpn TO desc_programme_public;
--Gestion du contenu du "Comment ?" dans la synthèse
ALTER TABLE meta.bib_programmes ADD COLUMN actif boolean;
UPDATE meta.bib_programmes SET actif = true;

--gestion dynamique des liens d'accès aux formulaires sur la page d'accueil
ALTER TABLE synthese.bib_sources ADD COLUMN url character varying(255);
COMMENT ON COLUMN synthese.bib_sources.url IS 'Définir l''url d''accès au formulaire de saisie de cette source de données - optionnel';
ALTER TABLE synthese.bib_sources ADD COLUMN target character varying(10);
COMMENT ON COLUMN synthese.bib_sources.url IS 'Indiquer si le formulaire de saisie de cette source de données s''ouvre dans un nouvel onglet - optionnel';
ALTER TABLE synthese.bib_sources ADD COLUMN picto character varying(255);
COMMENT ON COLUMN synthese.bib_sources.url IS 'Définir le chemin du pictogramme identifiant le protocole en lien avec la source de données - optionnel';
ALTER TABLE synthese.bib_sources ADD COLUMN groupe character varying(50);
COMMENT ON COLUMN synthese.bib_sources.url IS 'Placer cette source de données dans un groupe (exemple FAUNE ou FLORE) - optionnel';
ALTER TABLE synthese.bib_sources ADD COLUMN actif boolean;
COMMENT ON COLUMN synthese.bib_sources.url IS 'Définir si le formulaire de saisie de cette source de données doit aparaitre ou non sur la page d''accueil - optionnel';
--Attention si vous avez déjà une sources avec l'identifiant 2, vous devez adapter la ligne ci-dessous
INSERT INTO synthese.bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (2, 'Mortalité', 'contenu des tables t_fiche_cf et t_releves_cf de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactfaune', 't_releves_cf', 'id_releve_cf', 'mortalite', NULL, 'images/pictos/squelette.png', 'FAUNE', true);
UPDATE synthese.bib_sources SET actif = true;
UPDATE synthese.bib_sources SET actif = false WHERE id_source = 4;
UPDATE synthese.bib_sources SET groupe = 'FAUNE' WHERE id_source IN(1,2,3);
UPDATE synthese.bib_sources SET groupe = 'FLORE' WHERE id_source IN(4,5,6);
UPDATE synthese.bib_sources SET url = 'cf' WHERE id_source = 1;
UPDATE synthese.bib_sources SET url = 'mortalite' WHERE id_source = 2;
UPDATE synthese.bib_sources SET url = 'invertebre' WHERE id_source = 3;
UPDATE synthese.bib_sources SET url = 'pda' WHERE id_source = 4;
UPDATE synthese.bib_sources SET url = 'fs' WHERE id_source = 5;
UPDATE synthese.bib_sources SET url = 'bryo' WHERE id_source = 6;
UPDATE synthese.bib_sources SET picto = 'images/pictos/amphibien.gif' WHERE id_source = 1;
UPDATE synthese.bib_sources SET picto = 'images/pictos/squelette.png' WHERE id_source = 2;
UPDATE synthese.bib_sources SET picto = 'images/pictos/insecte.gif' WHERE id_source = 3;
UPDATE synthese.bib_sources SET picto = 'images/pictos/plante.gif' WHERE id_source = 4;
UPDATE synthese.bib_sources SET picto = 'images/pictos/plante.gif' WHERE id_source = 5;
UPDATE synthese.bib_sources SET picto = 'images/pictos/mousse.gif' WHERE id_source = 6;

--mise à jour du trigger contactfaune.synthese_insert_releve_cf
CREATE OR REPLACE FUNCTION contactfaune.synthese_insert_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
	fiche RECORD;
	test integer;
	mesobservateurs character varying(255);
	criteresynthese integer;
	idsource integer;
	danslecoeur boolean;
	unite integer;
BEGIN
	--Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;
	-- Récupération du id_source selon le critère d'observation, Si critère = 2 alors on est dans une source mortalité (=2) sinon cf (=1)
    IF criteresynthese = 2 THEN idsource = 2;
	ELSE
	    idsource = 1;
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
	-- on calcul si on est dans le coeur
	IF st_intersects((SELECT the_geom FROM layers.l_zonesstatut WHERE id_zone = 3249), fiche.the_geom_2154) THEN 
	    danslecoeur = true;
	ELSE
	    danslecoeur = false;
	END IF;
	
	INSERT INTO synthese.synthesefaune (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		codeprotocole,
		ids_protocoles,
		id_precision,
		cd_nom,
		id_taxon,
		insee,
		dateobs,
		observateurs,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total,
		coeur
	)
	VALUES(
	idsource,
	new.id_releve_cf,
	'f'||new.id_cf||'-r'||new.id_releve_cf,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	fiche.id_protocole,
	1,
	new.cd_ref_origine,
	new.id_taxon,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai,
	danslecoeur
	);
	
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.synthese_insert_releve_cf()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_insert_releve_cf() TO geonatuser;

--mise à jour des vous taxonomique faune

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
          WHERE l.id_liste >= 100 AND l.id_liste < 200
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
          WHERE l.id_liste >= 100
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text <> 'Chordata'::text AND t.regne::text = 'Animalia'::text;
  
CREATE OR REPLACE VIEW contactfaune.v_nomade_taxons_faune AS 
 SELECT DISTINCT t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
        CASE
            WHEN tx.cd_nom = ANY (ARRAY[61098, 61119, 61000]) THEN 6
            ELSE 5
        END AS denombrement,
    f2.bool AS patrimonial,
    m.texte_message_cf AS message,
        CASE
            WHEN tx.cd_nom = ANY (ARRAY[60577, 60612]) THEN false
            ELSE true
        END AS contactfaune,
    true AS mortalite
   FROM taxonomie.bib_taxons t
     LEFT JOIN contactfaune.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
     LEFT JOIN contactfaune.bib_messages_cf m ON m.id_message_cf = cmt.id_message_cf
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN contactfaune.v_nomade_classes g ON g.id_classe = ctl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
     JOIN public.cor_boolean f2 ON f2.expression::text = t.filtre2::text
  WHERE t.filtre1::text = 'oui'::text
  ORDER BY t.id_taxon, taxonomie.find_cdref(tx.cd_nom), t.nom_latin, t.nom_francais, g.id_classe, f2.bool, m.texte_message_cf;
  
CREATE OR REPLACE VIEW contactinv.v_nomade_taxons_inv AS 
 SELECT DISTINCT t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
    f2.bool AS patrimonial,
    m.texte_message_inv AS message
   FROM taxonomie.bib_taxons t
     LEFT JOIN contactinv.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
     LEFT JOIN contactinv.bib_messages_inv m ON m.id_message_inv = cmt.id_message_inv
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon
     JOIN contactinv.v_nomade_classes g ON g.id_classe = ctl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
     JOIN public.cor_boolean f2 ON f2.expression::text = t.filtre2::text;

-- Pour le fun
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (201, 'Bivalves',null, 'images/pictos/nopicto.gif');
INSERT INTO bib_listes (id_liste ,nom_liste,desc_liste,picto) VALUES (202, 'Gastéropodes',null, 'images/pictos/nopicto.gif');

------------Correction d'un bug à l'enregistrement
CREATE OR REPLACE FUNCTION contactfaune.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
--fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
--
--Gil DELUERMOZ mars 2012

  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT filtre2 INTO patri 
    FROM taxonomie.bib_taxons
    WHERE id_taxon = id;
	IF patri = 'oui' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'non' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
--fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
--
--Gil DELUERMOZ mars 2012

  DECLARE
  couleur text;
  patri boolean;
  BEGIN
    SELECT filtre2 INTO patri 
    FROM taxonomie.bib_taxons
    WHERE id_taxon = id;
	IF patri = 'oui' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'non' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION contactfaune.insert_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
cdnom integer;
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
   --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
   --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon, on commence par récupérer l'unité à partir du pointage (table t_fiches_cf)
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		--si la ligne existe dans cor_unite_taxon on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactfaune.cor_unite_taxon VALUES(unite,new.id_taxon,fiche.dateobs,contactfaune.couleur_taxon(new.id_taxon,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION contactinv.insert_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
cdnom integer;
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
   --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
   --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon_inv, on commence par récupérer l'unité à partir du pointage (table t_fiches_inv)
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_inv, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		--si la ligne existe dans cor_unite_taxon_inv on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactinv.cor_unite_taxon_inv VALUES(unite,new.id_taxon,fiche.dateobs,contactinv.couleur_taxon(new.id_taxon,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION synthese.maj_cor_unite_taxon()
  RETURNS trigger AS
$BODY$
DECLARE
monembranchement varchar;
monregne varchar;
monidtaxon integer;
BEGIN

IF (TG_OP = 'DELETE') THEN
	--retrouver le id_taxon
	SELECT INTO monidtaxon id_taxon FROM taxonomie.bib_taxons WHERE cd_nom = old.cd_nom LIMIT 1; 
	--calcul du règne du taxon supprimé
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
	IF monregne = 'Animalia' THEN
		--calcul de l'embranchement du taxon supprimé
			SELECT  INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
		-- puis recalul des couleurs avec old.id_unite_geo et old.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
			IF monembranchement = 'Chordata' THEN
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactfaune.cor_unite_taxon WHERE id_taxon = monidtaxon AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM synthese.calcul_cor_unite_taxon_cf(monidtaxon, old.id_unite_geo);
				END IF;
			ELSE
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_taxon = monidtaxon AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM synthese.calcul_cor_unite_taxon_inv(monidtaxon, old.id_unite_geo);
				END IF;
			END IF;
		END IF;
		RETURN OLD;		
ELSIF (TG_OP = 'INSERT') THEN
	--retrouver le id_taxon
	SELECT INTO monidtaxon id_taxon FROM taxonomie.bib_taxons WHERE cd_nom = new.cd_nom LIMIT 1;
	--calcul du règne du taxon inséré
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
	IF monregne = 'Animalia' THEN
		--calcul de l'embranchement du taxon inséré
		SELECT INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
		-- puis recalul des couleurs avec new.id_unite_geo et new.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
		IF monembranchement = 'Chordata' THEN
		    PERFORM synthese.calcul_cor_unite_taxon_cf(monidtaxon, new.id_unite_geo);
		ELSE
		    PERFORM synthese.calcul_cor_unite_taxon_inv(monidtaxon, new.id_unite_geo);
		END IF;
        END IF;
	RETURN NEW;
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION contactfaune.synthese_update_fiche_cf()
  RETURNS trigger AS
$BODY$
DECLARE
    releves RECORD;
    test integer;
    mesobservateurs character varying(255);
    sources RECORD;
    idsourcem integer;
    idsourcecf integer;
BEGIN

    --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
    FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
	IF sources.url = 'cf' THEN
	    idsourcecf = sources.id_source;
	ELSIF sources.url = 'mortalite' THEN
	    idsourcem = sources.id_source;
	END IF;
    END LOOP;
	--Récupération des données de la table t_releves_cf avec l'id_cf de la fiche modifié
	-- Ici on utilise le OLD id_cf pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_cf
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = old.id_cf LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
		IF test IS NOT NULL THEN
			SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
			JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
			LEFT JOIN (
				SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactfaune.cor_role_fiche_cf c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_cf
			) o ON o.id_cf = f.id_cf
			WHERE r.id_releve_cf = releves.id_releve_cf;
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
				
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cf||'-r'||releves.id_releve_cf,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot
				WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem) ;
			ELSE
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cf||'-r'||releves.id_releve_cf,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot
			    WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
			END IF;
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
CREATE OR REPLACE FUNCTION contactfaune.synthese_update_releve_cf()
  RETURNS trigger AS
$BODY$
DECLARE
    test integer;
    criteresynthese integer;
    sources RECORD;
    idsourcem integer;
    idsourcecf integer;
BEGIN
    
	--on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
        FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
	    IF sources.url = 'cf' THEN
	        idsourcecf = sources.id_source;
	    ELSIF sources.url = 'mortalite' THEN
	        idsourcem = sources.id_source;
	    END IF;
        END LOOP;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
	IF test IS NOT NULL THEN
		SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cf,
			code_fiche_source = 'f'||new.id_cf||'-r'||new.id_releve_cf,
			cd_nom = new.cd_ref_origine,
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
  
CREATE OR REPLACE FUNCTION contactinv.synthese_update_releve_inv()
  RETURNS trigger AS
$BODY$
DECLARE
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
    idsource integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
	IF test IS NOT NULL THEN
		--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
		SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_inv,
			code_fiche_source = 'f'||new.id_inv||'-r'||new.id_releve_inv,
			cd_nom = new.cd_ref_origine,
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
  
CREATE OR REPLACE FUNCTION public.application_aggregate_taxons_rang_sp(id integer)
  RETURNS text AS
$BODY$
--fonction permettant de regroupper dans un tableau tous les cd_nom d'une espèce et de ces sous espèces, variétés et convariétés à partir du cd_nom d'un taxon
--si le cd_nom passé est d'un rang différent de l'espèce (genre, famille... ou sous-espèce, variété...), la fonction renvoie simplement le cd_ref du cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011
  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  cd integer;
  tab integer;
  r text; 
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='ES') THEN
		cd = taxonomie.find_cdref(id);
		--SELECT INTO tab cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = taxonomie.find_cdref(id);
		SELECT INTO r array_agg(a.cd_nom) FROM (
		SELECT cd_nom FROM taxonomie.taxref WHERE cd_ref = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		) a;   
	ELSE
	   SELECT INTO r array_agg(cd_ref) FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return r;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.application_aggregate_taxons_rang_sp(integer)
  OWNER TO geonatuser;


CREATE OR REPLACE FUNCTION public.application_aggregate_taxons_all_rang_sp(id integer)
  RETURNS text AS
$BODY$
--fonction permettant de regroupper dans un tableau au rang espèce tous les cd_nom d'une espèce et de ces sous espèces, variétés et convariétés à partir du cd_nom d'un taxon
--si le cd_nom passé est d'un rang supérieur à l'espèce (genre, famille...), la fonction renvoie simplement le cd_ref du cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011
  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  cd integer;
  tab integer;
  r text; 
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='ES' OR rang='SSES' OR rang = 'VAR' OR rang = 'CVAR') THEN
	    IF(rang = 'ES') THEN
		cd = taxonomie.find_cdref(id);
	    END IF;
	    IF(rang = 'SSES') THEN
		SELECT INTO cd cd_taxsup FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(id);
	    END IF;
	    IF(rang = 'VAR' OR rang = 'CVAR') THEN
		SELECT INTO sup cd_taxsup FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(id);
		SELECT INTO rangsup id_rang FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(sup);
		IF(rangsup = 'ES') THEN
			cd = sup;
		ELSE
			SELECT INTO cd cd_taxsup FROM taxonomie.taxref WHERE cd_nom = taxonomie.find_cdref(sup);
		END IF;
	    END IF;

		--SELECT INTO tab cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = taxonomie.find_cdref(id);
		SELECT INTO r array_agg(a.cd_nom) FROM (
		SELECT cd_nom FROM taxonomie.taxref WHERE cd_ref = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup = cd
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'VAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		UNION
		SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'CVAR' AND cd_taxsup IN (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang = 'SSES' AND cd_taxsup = cd)
		) a;   
	ELSE
	   SELECT INTO r cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return r;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.application_aggregate_taxons_all_rang_sp(integer)
  OWNER TO geonatuser;