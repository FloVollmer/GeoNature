import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MetadataFormService } from '../services/metadata-form.service';
import { ModuleService } from '@geonature/services/module.service';

@Component({
  selector: 'pnx-datasets-form',
  templateUrl: './dataset-fiche.component.html',
  providers: [MetadataFormService]
})

export class DatasetFicheComponent implements OnInit {
  public organisms: Array<any>;
  public id_dataset: number;
  public dataset: any;
  public imports: Array<any>

  constructor(
    private _route: ActivatedRoute,
    private _dfs: DataFormService,
    public moduleService: ModuleService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe(params => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getDataset(this.id_dataset);
      }
    });

  }

  getDataset(id) {
    this._dfs.getDatasetDetails(id).subscribe(data => {
      this.dataset = data;

      this._dfs.getImports(id).subscribe(data => {
        this.imports = data;
        console.log(this.imports);
      })
    });
  }
  
}