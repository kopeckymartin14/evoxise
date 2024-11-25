@isTest
@SuppressWarnings('PMD')
public without sharing class DataFactory {
    
    public static Account createAccountWithContact() {
        Account acc = DataFactory.createDetailedAccount();
        Contact con = DataFactory.createContactWhitAssignAcc(acc.Id);
        return acc;
    }

    public static Account createDetailedAccount(){
        Account acc =  new Account(
            Name = 'testAcc'
        );
    
        insert acc;
        return acc;
    }     
    
    public static Contact createContactWhitAssignAcc(Id accountId){
        Contact con = new Contact(
            LastName = 'test@test.com',
            Email = 'test@test.com',
            AccountId = accountId
            
        );

        insert con;
        return con;
   }

   public static Payment__c createPayment(Id accountId) {
        Payment__c payment = new Payment__c(Account__c = accountId, Status__c = 'Initiated'); 
        insert payment;
        return payment;
   }

}