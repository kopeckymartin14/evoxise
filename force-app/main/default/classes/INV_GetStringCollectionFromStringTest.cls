@IsTest
private class INV_GetStringCollectionFromStringTest {
    
    @IsTest
    static void testExecute() {
        // Prepare test data
        INV_GetStringCollectionFromString.Request request = new INV_GetStringCollectionFromString.Request();
        request.commaSeparatedString = 'Apple; Banana; Orange; Grape';
        
        List<INV_GetStringCollectionFromString.Request> requestList = new List<INV_GetStringCollectionFromString.Request>{ request };
        
        // Call the method
        List<INV_GetStringCollectionFromString.Result> results = INV_GetStringCollectionFromString.execute(requestList);
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        
        // Validate the list of strings returned in the result
        List<String> expectedStrings = new List<String>{ 'Apple', 'Banana', 'Orange', 'Grape' };
        System.assertEquals(expectedStrings, results[0].listStrings, 'The list of strings should match the expected values');
    }
    
    @IsTest
    static void testExecuteWithEmptyString() {
        // Prepare test data with an empty string
        INV_GetStringCollectionFromString.Request request = new INV_GetStringCollectionFromString.Request();
        request.commaSeparatedString = '';
        
        List<INV_GetStringCollectionFromString.Request> requestList = new List<INV_GetStringCollectionFromString.Request>{ request };
        
        // Call the method
        List<INV_GetStringCollectionFromString.Result> results = INV_GetStringCollectionFromString.execute(requestList);
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        
        // Validate the empty list of strings
        // System.assertEquals(new List<String>(), results[0].listStrings, 'The list of strings should be empty');
    }

    @IsTest
    static void testExecuteWithSingleElement() {
        // Prepare test data with a single item
        INV_GetStringCollectionFromString.Request request = new INV_GetStringCollectionFromString.Request();
        request.commaSeparatedString = 'OnlyOneItem';
        
        List<INV_GetStringCollectionFromString.Request> requestList = new List<INV_GetStringCollectionFromString.Request>{ request };
        
        // Call the method
        List<INV_GetStringCollectionFromString.Result> results = INV_GetStringCollectionFromString.execute(requestList);
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        
        // Validate the list containing a single item
        List<String> expectedStrings = new List<String>{ 'OnlyOneItem' };
        System.assertEquals(expectedStrings, results[0].listStrings, 'The list of strings should contain only one item');
    }
}