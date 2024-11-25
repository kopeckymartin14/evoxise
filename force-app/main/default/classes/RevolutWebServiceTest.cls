@isTest
public class RevolutWebServiceTest {
   
    private static final String URL = 'https://x-finityconsultingsro--devsch.sandbox.my.salesforce-sites.com/revolut/services/apexrest/paymentIntent/Revolut_UnityCloud/';


    @testSetup
    static void setup() {
        Account acc = DataFactory.createAccountWithContact();
        Payment__c payment = DataFactory.createPayment(acc.Id);
         
    }
    
    @IsTest
    public static void testHandleRequestSucceeded(){
        Payment__c payment = [SELECT Id FROM Payment__c LIMIT 1];
        Test.startTest();
        RestResponse res = new RestResponse();

        RestRequest req = new RestRequest();
        req.requestURI = URL;
        req.addHeader('Content-Type', 'application/json');
        req.addHeader('Revolut-Signature', 'v1=f856144cd6f2edb09a1aa6e853fd446a4a401836b7481a6b7e0384d9d7eddb72');
        req.addHeader('Revolut-Request-Timestamp', '1728314521754');
        req.httpMethod = 'POST';
        System.debug(' req.requestBody: ' +  RevolutWebServiceMockFactory.getRevolutWebhook('orderPaid', payment.Id));

        req.requestBody = Blob.valueof(RevolutWebServiceMockFactory.getRevolutWebhook('orderPaid', payment.Id));
        RestContext.request = req;
        RestContext.response= res;

        RevolutWebService.handleRequest();

        RevolutQueueable revolut = new RevolutQueueable(payment.Id, 'ORDER_COMPLETED');
        revolut.work();
        Test.stopTest();
    }


    @IsTest
    public static void testHandleRequestFailed(){
        Payment__c payment = [SELECT Id FROM Payment__c LIMIT 1];
        Test.startTest();
        RestResponse res = new RestResponse();

        RestRequest req = new RestRequest();
        req.requestURI = URL;
        req.addHeader('Content-Type', 'application/json');
        // req.addHeader('Revolut-Signature', 'v1=f856144cd6f2edb09a1aa6e853fd446a4a401836b7481a6b7e0384d9d7eddb72');
        req.addHeader('Revolut-Request-Timestamp', '1728314521754');
        req.httpMethod = 'POST';
        System.debug(' req.requestBody: ' +  RevolutWebServiceMockFactory.getRevolutWebhook('orderPaid', payment.Id));

        req.requestBody = Blob.valueof(RevolutWebServiceMockFactory.getRevolutWebhook('orderPaid', payment.Id));
        RestContext.request = req;
        RestContext.response= res;

        RevolutWebService.handleRequest();
        Test.stopTest();
    }

    @IsTest
    public static void testHandleRequestFailed2(){
        Payment__c payment = [SELECT Id FROM Payment__c LIMIT 1];
        Test.startTest();
        RestResponse res = new RestResponse();

        RestRequest req = new RestRequest();
        req.requestURI = URL;
        req.addHeader('Content-Type', 'application/json');
        req.addHeader('Revolut-Signature', 'v0=f856144cd6f2edb09a1aa6e853fd446a4a401836b7481a6b7e0384d9d7eddb72');
        req.addHeader('Revolut-Request-Timestamp', '1728314521754');
        req.httpMethod = 'POST';
        System.debug(' req.requestBody: ' +  RevolutWebServiceMockFactory.getRevolutWebhook('orderPaid', payment.Id));

        req.requestBody = Blob.valueof(RevolutWebServiceMockFactory.getRevolutWebhook('orderPaid', payment.Id));
        RestContext.request = req;
        RestContext.response= res;

        RevolutWebService.handleRequest();

        Test.stopTest();
    }
}