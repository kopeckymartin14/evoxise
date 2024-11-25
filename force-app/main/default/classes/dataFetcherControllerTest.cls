/**
 * @description       : 
 * @author            : Josh Dayment
 * @group             : https://github.com/SalesforceLabs/Data-Fetcher/tree/main
 * @last modified on  : 2/6/23
 * @last modified by  : Ben Patterson
**/
@isTest
private class dataFetcherControllerTest{

	@IsTest
	static void canQuery() {
	  insert new List<SObject>{ new Account(Name = 'One'), new Account(Name = 'Two') };
  
	  dataFetcherController.QueryResult result = dataFetcherController.getSObjects(
		'SELECT Id, Name FROM Account ORDER BY Name' , false
	  );
	  dataFetcherController.AggQueryResult aggAmount = dataFetcherController.getAggregate('SELECT COUNT(Id) FROM Account', false );
  
	  Assert.areEqual(2, result.results.size());
	  Assert.areEqual('One', result.firstResult.get(Account.Name));
	}
	@IsTest
  static void testWOsharing() {
	  insert new List<SObject>{ new Account(Name = 'One'), new Account(Name = 'Two') };
  
	  dataFetcherWOsharingController.QueryResult result = dataFetcherWOsharingController.getSObjects(
		'SELECT Id, Name FROM Account ORDER BY Name', true
	  );
	  dataFetcherWOsharingController.AggQueryResult aggAmount = dataFetcherWOsharingController.getAggregate('SELECT COUNT(Id) FROM Account' , true );
  
	  Assert.areEqual(2, result.results.size());
	  Assert.areEqual('One', result.firstResult.get(Account.Name));
	}
	
  }