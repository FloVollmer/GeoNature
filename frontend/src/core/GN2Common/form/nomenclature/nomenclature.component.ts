import { Component, OnInit, Input, Output, EventEmitter, OnChanges, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';

@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit, OnChanges {
  labels: any[];
  nomenclature: any;
  selectedId: number;
  @Input() placeholder: string;
  @Input() parentFormControl: FormGroup;
  @Input() idTypeNomenclature: number;
  @Input() regne: string;
  @Input() group2Inpn: string;
  @Input() lang: string;
  @Output() valueSelected = new EventEmitter<any>();

  constructor(private _dfService: DataFormService) { }

  ngOnInit() {
    
    // load the data
     this._dfService.getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
      .subscribe(data => {
        this.initLabels(data);
      });
    
  }

  ngOnChanges(changes: SimpleChanges) {
    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this._dfService.getNomenclature(this.idTypeNomenclature, changes.regne.currentValue, changes.group2Inpn.currentValue)
        .subscribe(data => {
          this.initLabels(data);
        });
    }
    // if only change groupe2inpn
    if (changes.regne === undefined && changes.group2Inpn !== undefined && !changes.group2Inpn.firstChange) {
        this._dfService.getNomenclature(this.idTypeNomenclature, this.regne, this.group2Inpn)
          .subscribe(data => {
            this.initLabels(data);
          });
      }
    }

  initLabels(data){
    this.labels = data.values;
    // disable the input if undefined
    if(this.labels === undefined){
      this.parentFormControl.disable();
    }
  }

  // Output
  onLabelChange() {
    this.valueSelected.emit(this.selectedId);
  }
}