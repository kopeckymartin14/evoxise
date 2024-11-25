@isTest
public class BlogControllerTest {
    @isTest
    static void testCoverage() {
        Blog__c blogRecord = new Blog__c (Banner_Image__c = '<p><img src="https://test.com"></img></p>',
                                    Summary__c = 'test1',
                                    Active__c = true,
                                    Published_Date__c = Date.today(),
                                    Order__c = 1,
                                    Title__c = 'Test 1',
                                    Content__c = 'Test1');
        insert blogRecord;

        List<BlogController.BlogRecordWrapper> records =  BlogController.getBlogRecords();

        Blog__c blog1 = BlogController.getBlogRecordById(null);
        Blog__c blog2 = BlogController.getBlogRecordById(blogRecord.Id);

        List<Blog__c> blogs = BlogController.getBlogsWithoutRecordId(blogRecord.Id);
    }
}