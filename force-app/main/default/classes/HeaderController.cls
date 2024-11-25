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
}