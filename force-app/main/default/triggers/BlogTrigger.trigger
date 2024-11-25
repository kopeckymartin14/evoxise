trigger BlogTrigger on Blog__c (before insert, before update) {

    for(Blog__c b : Trigger.new) {
        if(String.isNotBlank(b.Banner_Image__c)) {
            b.Banner_Image__c = b.Banner_Image__c.removeEnd('</p>');
            b.Banner_Image__c = b.Banner_Image__c.removeStart('<p>');
        }
    }
}