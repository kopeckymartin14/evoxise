@isTest
public class RevolutApiTest {
    

    @testSetup
    static void setup() {
        Account acc = DataFactory.createAccountWithContact();
        Payment__c payment = DataFactory.createPayment(acc.Id);
         
    }

    @isTest
    public static void createOrderTests() {
        Payment__c payment = [SELECT Id FROM Payment__c LIMIT 1];

        RevolutMockFactory.getRevolutMockData(payment.Id); 

        Test.startTest();
        List<RevolutApi.InputVariables> inputs = new List<RevolutApi.InputVariables>();
        RevolutApi.InputVariables input = new RevolutApi.InputVariables();
        input.paymentId = payment.Id;
        input.customerId = null;
        input.appointmentIds = 'appointmentId';
        input.url = 'https://example.com';
        input.description = 'description';
        input.fullName = 'Test Test';
        input.email = 'test@test.com';
        input.amount = 1000;
        inputs.add(input);
        List<RevolutApi.OutputVariables> response =  RevolutApi.createOrder(inputs);
        Test.stopTest();


    }
}