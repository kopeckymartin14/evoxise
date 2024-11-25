/**
* @File Name : BlogController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 5, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 5, 2024 |   | Initial Version
**/

public without sharing class BlogController {
	@AuraEnabled(cacheable=true)
    public static List<BlogRecordWrapper> getBlogRecords() {
        // Query Blog records with linked ContentDocumentIds
        List<Blog__c> blogRecords = [
            SELECT Id, Name, Title__c, Summary__c, Content__c, Published_Date__c, Banner_Image__c
            FROM Blog__c
            WHERE Active__c = true
			ORDER BY Published_Date__c DESC
        ];

        List<BlogRecordWrapper> blogWrappers = new List<BlogRecordWrapper>();
        Pattern pattern = Pattern.compile('src="(.*?)"');

        for (Blog__c blog : blogRecords) {
            BlogRecordWrapper wrapper = new BlogRecordWrapper();
            wrapper.blogRecord = blog;

            if(String.isNotBlank(blog.Banner_Image__c)) {
                Matcher matcher = pattern.matcher(blog.Banner_Image__c);
                if (matcher.find()) {
                    wrapper.imageUrl = matcher.group(1);
                }
                System.debug('Extracted URL: ' + wrapper.imageUrl);
            }
            
            blogWrappers.add(wrapper);



        }
        return blogWrappers;
    }

    @AuraEnabled(cacheable=true)
    public static Blog__c getBlogRecordById(String blogId) {
        Blog__c blog = new Blog__c();
        if(blogId != null) {
            return [
                SELECT Id, Name, Title__c, Summary__c, Content__c, Published_Date__c, Banner_Image__c
                FROM Blog__c
                WHERE Id =: blogId
            ];
        }
        else {
            return [
                SELECT Id, Name, Title__c, Summary__c, Content__c, Published_Date__c, Banner_Image__c
                FROM Blog__c
                WHERE Active__c = true
                ORDER By Order__c ASC
                LIMIT 1
            ];
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Blog__c> getBlogsWithoutRecordId(String blogId) {
      
        
        return [
            SELECT Id, Name, Title__c, Summary__c, Content__c, Published_Date__c, Banner_Image__c
            FROM Blog__c
            WHERE Id !=: blogId
        ];
       
    }

    // Wrapper class to hold both the blog record and image URL
    public class BlogRecordWrapper {
        @AuraEnabled public Blog__c blogRecord;
        @AuraEnabled public String imageUrl;
    }

}