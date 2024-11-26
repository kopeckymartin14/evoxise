public without sharing class HeaderController {
    
    @AuraEnabled
    public static Headline_Metadata__mdt getHeaderData(String pageName) {

        if(!String.isBlank(pageName)) {
            System.debug('pageName: ' + pageName);
            return [SELECT DeveloperName, Headline__c, Is_Record_Page__c, SubHeadline__c FROM Headline_Metadata__mdt WHERE Page_Name__c =: pageName LIMIT 1];
        }
        else {
            return Headline_Metadata__mdt.getInstance('home');
        }

    }

    @AuraEnabled
    public static Boolean removeValidityToken(String token){
        if(token != null) {
            List<Account> accounts = [SELECT Id, Unique_Code__c, Login_Token__c,Login_Token_Validity__c FROM Account WHERE Login_Token__c =: token];
            if(!accounts.isEmpty()) {
                Account acc = accounts.get(0);
                acc.Login_Token_Validity__c = Datetime.now() - 1;
                update acc;
            }
        }
        return true;
    }

    @AuraEnabled
    public static Boolean validateToken(String token){
        if(token != null) {
            List<Account> accounts = [SELECT Id, Unique_Code__c, Login_Token__c,Login_Token_Validity__c FROM Account WHERE Login_Token__c =: token];
            if(!accounts.isEmpty()) {
                Account acc = accounts.get(0);
                return acc.Login_Token_Validity__c > Datetime.now();
            }
        }
        return false;
    }
}