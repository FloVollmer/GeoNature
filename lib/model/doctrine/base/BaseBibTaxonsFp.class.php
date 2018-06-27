<?php

/**
 * BaseBibTaxonsFp
 * 
 * This class has been auto-generated by the Doctrine ORM Framework
 * 
 * @property integer $cd_nom
 * @property integer $echelle
 * @property string $francais
 * @property string $latin
 * @property Doctrine_Collection $TZprospection
 * 
 * @method integer             get()              Returns the current record's "cd_nom" value
 * @method integer             get()              Returns the current record's "echelle" value
 * @method string              get()              Returns the current record's "francais" value
 * @method string              get()              Returns the current record's "latin" value
 * @method Doctrine_Collection get()              Returns the current record's "TZprospection" collection
 * @method BibTaxonsFp         set()              Sets the current record's "cd_nom" value
 * @method BibTaxonsFp         set()              Sets the current record's "echelle" value
 * @method BibTaxonsFp         set()              Sets the current record's "francais" value
 * @method BibTaxonsFp         set()              Sets the current record's "latin" value
 * @method BibTaxonsFp         set()              Sets the current record's "TZprospection" collection
 * 
 * @package    geonature
 * @subpackage model
 * @author     Gil Deluermoz
 * @version    SVN: $Id: Builder.php 7490 2010-03-29 19:53:27Z jwage $
 */
abstract class BaseBibTaxonsFp extends sfDoctrineRecord
{
    public function setTableDefinition()
    {
        $this->setTableName('florepatri.bib_taxons_fp');
        $this->hasColumn('cd_nom', 'integer', 4, array(
             'type' => 'integer',
             'primary' => true,
             'length' => 4,
             ));
        $this->hasColumn('echelle', 'integer', 2, array(
             'type' => 'integer',
             'notnull' => true,
             'length' => 2,
             ));
        $this->hasColumn('francais', 'string', 100, array(
             'type' => 'string',
             'length' => 100,
             ));
        $this->hasColumn('latin', 'string', 100, array(
             'type' => 'string',
             'length' => 100,
             ));
    }

    public function setUp()
    {
        parent::setUp();
        $this->hasMany('TZprospection', array(
             'local' => 'cd_nom',
             'foreign' => 'cd_nom'));
    }
}