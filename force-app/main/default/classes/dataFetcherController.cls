/**
 * @description       : 
 * @author            : Josh Dayment
 * @group             : https://github.com/SalesforceLabs/Data-Fetcher/tree/main
 * @last modified on  : 2/6/23
 * @last modified by  : Ben Patterson - added option to run without sharing and/or system mode (field access)
**/
public with sharing class dataFetcherController {
    @AuraEnabled
    
      public static QueryResult getSObjects(String queryString, boolean systemAccess) {
      /* included in source code, but the search.find wasn't working for me and it's for sosl anyhow 
      if(queryString.startsWith('FIND')) {
          return new QueryResult(Search.find(queryString, System.AccessLevel.USER_MODE));
        }else{
        return new QueryResult(Database.query(queryString, System.AccessLevel.USER_MODE));
        }*/
        //different query based on parameter input.
        if (systemAccess){
          return new QueryResult(Database.query(queryString , System.AccessLevel.SYSTEM_MODE));
        } else {
          return new QueryResult(Database.query(queryString , System.AccessLevel.USER_MODE));
        }
      }
      
      @AuraEnabled
      public static AggQueryResult getAggregate(String aggQueryString, boolean systemAccess) {
        if (systemAccess){
          return new AggQueryResult(Database.query(aggQueryString, System.AccessLevel.SYSTEM_MODE));
        } else {
          return new AggQueryResult(Database.query(aggQueryString, System.AccessLevel.USER_MODE));
        }
      }
        
    
      public class QueryResult {
        public QueryResult(List<SObject> results) {
          this.results = results;
          if (this.results.isEmpty() == false) {
            this.firstResult = this.results.get(0);
          }
        }        
      
    
        @AuraEnabled
        public final List<SObject> results;
        @AuraEnabled
        public final SObject firstResult;
        
      }   
      
      
      public class AggQueryResult {
        public AggQueryResult(List<AggregateResult> aggResult) {
          Decimal aggAmount = (Decimal)aggResult[0].get('expr0');
          this.aggAmount = aggAmount;
            System.debug('AggQueryResult: ' + aggAmount);
        } 
          
        @AuraEnabled
        public final Decimal aggAmount;
      }  
    }