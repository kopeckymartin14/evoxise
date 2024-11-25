@isTest
public class HeaderControllerTest {

    @isTest
    static void testCoverage() {

        Headline_Metadata__mdt result = HeaderController.getHeaderData('home');
        Headline_Metadata__mdt result2 = HeaderController.getHeaderData('');

        System.assertNotEquals(null, result, 'Header data should not be null for a valid page name');
        System.assertNotEquals(null, result2, 'Header data should not be null for a blank page name');
    }
}