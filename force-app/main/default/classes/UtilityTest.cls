@isTest
public class UtilityTest {

    @testSetup
    static void setup() {
        Account acc = DataFactory.createAccountWithContact();
        Payment__c payment = DataFactory.createPayment(acc.Id);
         
    }

    @isTest
    public static void UtilityTest() {

        Payment__c payment = [SELECT Id FROM Payment__c LIMIT 1];


        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('String','Test');
        requestMap.put('Map',new Map<String, Object>());
        requestMap.put('List',new List<Object>());
        requestMap.put('Id', payment.Id);
        requestMap.put('Decimal',5656.65);
        requestMap.put('Integer',5656);
        Boolean isSandbox = Utility.isSandbox();

        String stringData = Utility.getString(requestMap, 'String');
        Map<String, Object> mapData = Utility.getMap(requestMap, 'Map');
        List<Object> listData = Utility.GetList(requestMap, 'List');
        Id idData = Utility.getId(requestMap, 'Id');
        Decimal decimalData = Utility.getDecimal(requestMap, 'Decimal');
        Integer integerData = Utility.getInteger(requestMap, 'Integer');

    }
}