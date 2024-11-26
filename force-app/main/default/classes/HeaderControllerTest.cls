@isTest
public class HeaderControllerTest {


    @TestSetup
    static void setupTestData() {
        // Create a test Account with a valid token
        Account testAccount = new Account(
            Name = 'Test Account',
            Unique_Code__c = '656986',
            Login_Token__c = '565365',
            Login_Token_Validity__c = Datetime.now().addDays(1) // Valid for one day
        );
        insert testAccount;
    }

    @isTest
    static void testCoverage() {

        Headline_Metadata__mdt result = HeaderController.getHeaderData('home');
        Headline_Metadata__mdt result2 = HeaderController.getHeaderData('');

        System.assertNotEquals(null, result, 'Header data should not be null for a valid page name');
        System.assertNotEquals(null, result2, 'Header data should not be null for a blank page name');
    }

    @IsTest
    static void testRemoveValidityToken() {
        // Retrieve the test account's token
        Account acc = [SELECT Login_Token__c FROM Account LIMIT 1];
        String token = acc.Login_Token__c;

        // Call the method to remove the validity token
        Boolean result = HeaderController.removeValidityToken(token);

        // Verify the method's behavior
        System.assertEquals(true, result, 'The method should return true.');

        // Query the account to verify the validity token was updated
        Account updatedAccount = [SELECT Login_Token_Validity__c FROM Account WHERE Login_Token__c = :token];
        System.assert(updatedAccount.Login_Token_Validity__c < Datetime.now(), 
                      'The Login_Token_Validity__c should be set to a past date.');
    }

    @IsTest
    static void testValidateToken_Valid() {
        // Retrieve the test account's token
        Account acc = [SELECT Login_Token__c FROM Account LIMIT 1];
        String token = acc.Login_Token__c;

        // Call the method to validate the token
        Boolean isValid = HeaderController.validateToken(token);

        // Verify the token is valid
        System.assertEquals(true, isValid, 'The token should be valid.');
    }

    @IsTest
    static void testValidateToken_Invalid() {
        // Retrieve the test account's token
        Account acc = [SELECT Login_Token__c FROM Account LIMIT 1];
        String token = acc.Login_Token__c;

        // Call the removeValidityToken method to invalidate the token
        HeaderController.removeValidityToken(token);

        // Call the method to validate the token
        Boolean isValid = HeaderController.validateToken(token);

        // Verify the token is invalid
        System.assertEquals(false, isValid, 'The token should be invalid.');
    }

    @IsTest
    static void testValidateToken_Null() {
        // Call the method with a null token
        Boolean isValid = HeaderController.validateToken(null);

        // Verify the method returns false
        System.assertEquals(false, isValid, 'The method should return false for null token.');
    }
    
}