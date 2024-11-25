/**
 * @description       : 
 * @author            : Josh Dayment
 * @group             : https://github.com/SalesforceLabs/Data-Fetcher/tree/main
 * @last modified on  : 2/6/23
 * @last modified by  : Ben Patterson
**/
import { api,track, LightningElement } from "lwc";
import getSObjects from "@salesforce/apex/dataFetcherController.getSObjects";
import getAggregate from "@salesforce/apex/dataFetcherController.getAggregate";
import getSObjectsWOsharing from "@salesforce/apex/dataFetcherWOsharingController.getSObjects";
import getAggregateWOsharing from "@salesforce/apex/dataFetcherWOsharingController.getAggregate";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

export default class dataFetcher extends LightningElement {
  @api queryString;
  @api aggQueryString;
  @api aggQueryResult;
  @api withSharing =false;
  @api systemAccess=false;
  @api firstRetrievedRecord;
  @api retrievedRecords = [];
  @api error;
  @track oldQuery;
  @track oldAggQuery;

  
  renderedCallback() {
    if (this.queryString && this.queryString != this.oldQuery) {
    this._getRecords();}
    //console.log("Records are: " + JSON.stringify(this.retrievedRecords))
    if (this.aggQueryString && this.aggQueryString != this.oldAggQuery){
        this._getAggregate();
    }
  }

  handleOnChange() {
    this._debounceGetRecords();
  }

  _getRecords() {
    if (!this.withSharing){

    //run in system mode  
    getSObjectsWOsharing({ queryString: this.queryString , systemAccess: this.systemAccess})
        .then(({ results, firstResult }) => {
          this.error = undefined;
          this.retrievedRecords = results;
          this.firstRetrievedRecord = firstResult;
          this._fireFlowEvent("firstRetrievedRecord", this.firstRetrievedRecord);
          this._fireFlowEvent("retrievedRecords", this.retrievedRecords);
        })
        .catch(error => 
          {this.error = error?.body?.message ?? JSON.stringify(error);
          console.error(error.body.message);
          this._fireFlowEvent("error", this.error);});

        this.oldQuery = this.queryString;
          } else{
            //run in user mode  
            getSObjects({ queryString: this.queryString , systemAccess: this.systemAccess })
                .then(({ results, firstResult }) => {
                  this.error = undefined;
                  this.retrievedRecords = results;
                  this.firstRetrievedRecord = firstResult;
                  this._fireFlowEvent("firstRetrievedRecord", this.firstRetrievedRecord);
                  this._fireFlowEvent("retrievedRecords", this.retrievedRecords);
                })
                .catch(error => 
                  {this.error = error?.body?.message ?? JSON.stringify(error);
                  console.error(error.body.message);
                  this._fireFlowEvent("error", this.error);});
        
                this.oldQuery = this.queryString;    
          }
  }

  _getAggregate() {
    
    //console.log("Query String is " + this.aggQueryString)
    if (!this.withSharing){
      getAggregateWOsharing({ aggQueryString: this.aggQueryString, systemAccess: this.systemAccess } )
        .then(({ aggAmount, }) => {
          this.error = undefined;
          this.aggQueryResult = aggAmount;
          this._fireFlowEvent("aggQueryResult", this.aggQueryResult);
        })
        .catch(error => 
          {this.error = error?.body?.message ?? JSON.stringify(error);
          console.error(error.body.message);
          this._fireFlowEvent("error", this.error);});

        this.oldAggQuery = this.aggQueryString;
          }   else{
            getAggregate({ aggQueryString: this.aggQueryString, systemAccess: this.systemAccess } )
            .then(({ aggAmount, }) => {
              this.error = undefined;
              this.aggQueryResult = aggAmount;
              this._fireFlowEvent("aggQueryResult", this.aggQueryResult);
            })
            .catch(error => 
              {this.error = error?.body?.message ?? JSON.stringify(error);
              console.error(error.body.message);
              this._fireFlowEvent("error", this.error);});
    
            this.oldAggQuery = this.aggQueryString;
          }
  }

  _debounceGetRecords() {
    this._debounceTimer && clearTimeout(this._debounceTimer);
    if (this.queryString){
    this._debounceTimer = setTimeout(() => this._getRecords(), 300);
    }    
    if (this.aggQueryString){
      this._debounceTimer = setTimeout(() => this._getAggregate(), 300);
      }
  }  

  _fireFlowEvent(eventName, data) {
    this.dispatchEvent(new FlowAttributeChangeEvent(eventName, data));
  }

}