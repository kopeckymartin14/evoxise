import { LightningElement, wire } from 'lwc';
import getBlogRecords from '@salesforce/apex/BlogController.getBlogRecords';
import { NavigationMixin } from 'lightning/navigation';

export default class BlogArxCard extends NavigationMixin(LightningElement) {
    blogRecords;

    @wire(getBlogRecords)
    wiredBlogs({ error, data }) {
        const baseUrl = window.location.origin;
        if (data) {
            this.blogRecords = data.map(blogWrapper => {
                let imageUrl = blogWrapper.imageUrl;

                if (imageUrl) {
                    // Replace &amp; with &
                    imageUrl = imageUrl.replace(/&amp;/g, '&');
                    
                    // If imageUrl is a relative path, prepend the base URL
                    if (imageUrl.startsWith('/GuestAccess')) {
                        imageUrl = `${baseUrl}${imageUrl}`;
                    }
                } else {
                    // Fallback to an empty string if imageUrl is not available
                    imageUrl = '';
                }
    
                return {
                    ...blogWrapper,
                    imageUrl // Updated imageUrl
                };
                // return {
                //     ...blogWrapper,
                //     imageUrl: blogWrapper.imageUrl ? blogWrapper.imageUrl : '' // Fallback image
                // };
            });
        } else if (error) {
            this.blogRecords = undefined;
            console.error('Error fetching blog records:', error);
        }
    }

    handleCardClick(event) {
        const recordId = event.currentTarget.dataset.id;

        // Navigate to the record page
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: recordId,
        //         objectApiName: 'Blog__c', // Adjust for your object
        //         actionName: 'view',
        //     },
        // });
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'blog_detail__c' // API name of your Community page (adjust as per your setup)
            },
            state: {
                recordId: recordId // This is the parameter passed to the page
            }
        });
    }
}