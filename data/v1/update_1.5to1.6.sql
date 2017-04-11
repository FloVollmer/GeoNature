﻿--ajout de la source 0 utilisée par la web api si l'id_source n'est pas transmis
INSERT INTO synthese.bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (0, 'Web API', 'Donnée externe non définie (insérée dans la synthese à partir du service reste de la web API sans id_source fourni)', 'localhost', 22, NULL, NULL, 'geonaturedb', 'synthese', 'syntheseff', 'id_fiche_source', NULL, NULL, NULL, 'NONE', false);

CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(id integer,maxdateobs date)
  RETURNS text AS
$BODY$
--fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation
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
ALTER FUNCTION contactinv.couleur_taxon(id integer,maxdateobs date) OWNER TO geonatuser;

CREATE OR REPLACE FUNCTION contactfaune.synthese_update_cor_role_fiche_cf()
  RETURNS trigger AS
$BODY$
DECLARE
	releves RECORD;
	test integer;
	mesobservateurs character varying(255);
	sources RECORD;
        idsource integer;
        idsourcem integer;
	idsourcecf integer;
BEGIN
	--
	--CE TRIGGER NE DEVRAIT SERVIR QU'EN CAS DE MISE A JOUR MANUELLE SUR CETTE TABLE cor_role_fiche_cf
	--L'APPLI WEB ET LES TABLETTES NE FONT QUE DES INSERTS QUI SONT GERER PAR LE TRIGGER INSERT DE t_releves_cf
	--
        --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
	FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
		IF sources.url = 'cf' THEN
			idsourcecf = sources.id_source;
		ELSIF sources.url = 'mortalite' THEN
			idsourcem = sources.id_source;
		END IF;
	END LOOP;
    
	--Récupération des enregistrements de la table t_releves_cf avec l'id_cf de la table cor_role_fiche_cf
	FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = new.id_cf LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff 
		WHERE (id_source = idsourcem OR id_source = idsourcecf) AND id_fiche_source = releves.id_releve_cf::text;
		IF test ISNULL THEN
		RETURN null;
		ELSE
			SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
			JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
			LEFT JOIN (
				SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactfaune.cor_role_fiche_cf c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_cf
			) o ON o.id_cf = f.id_cf
			WHERE r.id_releve_cf = releves.id_releve_cf;
			--mise à jour de l'enregistrement correspondant dans syntheseff ; uniquement le champ observateurs ici
			UPDATE synthese.syntheseff SET
				observateurs = mesobservateurs
			WHERE (id_source = idsourcem OR id_source = idsourcecf) AND id_fiche_source = releves.id_releve_cf::text; 
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.synthese_update_cor_role_fiche_cf() OWNER TO geonatuser;

--Amélioration des performances
CREATE INDEX i_fk_cor_cor_zonesstatut_synthese_syntheseff
  ON synthese.cor_zonesstatut_synthese
  USING btree
  (id_synthese);
  
--automatisation de la suppression en cascade dans la table de correspondance cor_taxon_liste
ALTER TABLE taxonomie.cor_taxon_liste DROP CONSTRAINT cor_taxon_liste_bib_listes_fkey;
ALTER TABLE taxonomie.cor_taxon_liste
  ADD CONSTRAINT cor_taxon_liste_bib_listes_fkey FOREIGN KEY (id_liste)
      REFERENCES taxonomie.bib_listes (id_liste) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE taxonomie.cor_taxon_liste DROP CONSTRAINT cor_taxon_liste_bib_taxons_fkey;
ALTER TABLE taxonomie.cor_taxon_liste
  ADD CONSTRAINT cor_taxon_liste_bib_taxons_fkey FOREIGN KEY (id_taxon)
      REFERENCES taxonomie.bib_taxons (id_taxon) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;
      
--Préparation à l'accueil du taxref V8
DROP TABLE import_taxref;
CREATE TABLE taxonomie.import_taxref
(
  regne character varying(20),
  phylum character varying(50),
  classe character varying(50),
  ordre character varying(50),
  famille character varying(50),
  group1_inpn character varying(50),
  group2_inpn character varying(50),
  cd_nom integer NOT NULL,
  cd_taxsup integer,
  cd_ref integer,
  rang character varying(10),
  lb_nom character varying(100),
  lb_auteur character varying(250),
  nom_complet character varying(255),
  nom_complet_html character varying(500),
  nom_valide character varying(255),
  nom_vern character varying(1000),
  nom_vern_eng character varying(500),
  habitat character varying(10),
  fr character varying(10),
  gf character varying(10),
  mar character varying(10),
  gua character varying(10),
  sm character varying(10),
  sb character varying(10),
  spm character varying(10),
  may character varying(10),
  epa character varying(10),
  reu character varying(10),
  taaf character varying(10),
  pf character varying(10),
  nc character varying(10),
  wf character varying(10),
  cli character varying(10),
  url text,
  CONSTRAINT pk_import_taxref PRIMARY KEY (cd_nom)
)
WITH (
  OIDS=FALSE
);

--Si besoin, vous pouvez utiliser le fichier taxref V8 de l'INPN fourni avec GeoNature 1.6 dans "data/inpn/TAXREF_INPN_v8.0.zip"
-- ainsi que la commande sql (commentée) ci-dessous :
--COPY import_taxref (regne, phylum, classe, ordre, famille, group1_inpn, group2_inpn, 
         -- cd_nom, cd_taxsup, cd_ref, rang, lb_nom, lb_auteur, nom_complet, nom_complet_html,
         -- nom_valide, nom_vern, nom_vern_eng, habitat, fr, gf, mar, gua, 
         -- sm, sb, spm, may, epa, reu, taaf, pf, nc, wf, cli, url)
--FROM  'PATH_TO_DIR/data/inpn/TAXREFv80.txt'
--WITH  CSV HEADER 
--DELIMITER E'\t'  encoding 'LATIN1';

--MISE A JOUR de la table taxonomie.taxref
ALTER TABLE taxonomie.taxref ALTER COLUMN lb_auteur TYPE character varying(250);
ALTER TABLE taxonomie.taxref ALTER COLUMN nom_vern TYPE character varying(1000);
ALTER TABLE taxonomie.taxref ALTER COLUMN nom_vern_eng TYPE character varying(500);
ALTER TABLE taxonomie.taxref ALTER COLUMN nom_complet_html TYPE character varying(500);
--ajout d'un statut non précisé
INSERT INTO bib_taxref_statuts (id_statut, nom_statut) VALUES (' ', 'Non précisé');

--Si besoin, voici les commandes (commentée) SQL à utiliser pour vider puis remplir la table taxonomie.taxef. Pour vider la table taxonomie.taxef, vous devrez préalablement désactiver toutes les clés étrangères pointant sur cette table.
--TRUNCATE TABLE taxref;
--INSERT INTO taxref
      --SELECT cd_nom, fr as id_statut, habitat::int as id_habitat, rang as  id_rang, regne, phylum, classe, 
             --ordre, famille, cd_taxsup, cd_ref, lb_nom, substring(lb_auteur, 1, 250), nom_complet, 
             --nom_valide, nom_vern, nom_vern_eng, group1_inpn, group2_inpn
        --FROM import_taxref
        --WHERE regne = 'Animalia'
        --OR regne = 'Fungi'
        --OR regne = 'Plantae';
        
--Taxref V8 est livré avec les mêmes tables que taxref V7 concernant les statuts juridiques.
-- * taxonomie.taxref_protection_articles
-- * taxonomie.taxref_protection_especes
--Il n'y a donc pas de mise à jour à faire concernant ces tables
