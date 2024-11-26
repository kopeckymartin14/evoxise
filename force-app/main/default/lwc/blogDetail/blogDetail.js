import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

import { createMessageContext, releaseMessageContext, publish } from 'lightning/messageService';
import BLOG_CHANNEL from '@salesforce/messageChannel/Blog_ARX__c';

import getBlogRecord from '@salesforce/apex/BlogController.getBlogRecordById';
import getBlogsWithoutRecordId from '@salesforce/apex/BlogController.getBlogsWithoutRecordId';

export default class BlogDetail extends NavigationMixin(LightningElement) {

    blogContext = createMessageContext();
    sanitizedContent
    test = '<p><img src="https://x-finityconsultingsro--devsch.sandbox.my.salesforce.com/servlet/rtaImage?eid=a179V00002774cz&feoid=00N9V00000AxoCj&refid=0EM9V000000TfcT#/" alt=\"Stroj.jpg\"></img></p>';
    recordId; // This will be passed when the component is used on a record page
    @track blog;
    @track error;
    @track isLoading = true;

    @track blogs = [];

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            this.recordId = pageRef.state.recordId; // Get the recordId from the URL parameters
        }
    }

    connectedCallback() {
        this.showContent();
    }

    disconnectedCallback() {
        releaseMessageContext(this.blogContext);
    }

    showContent() {
        getBlogRecord({ blogId: this.recordId })
        .then(result => {
            this.blog = result;
            this.isLoading = false;

        })
        .catch(error => {
          console.error('Error:', error);
          this.error = 'Error loading blog details';
          this.isLoading = false;
        });

        getBlogsWithoutRecordId({ blogId: this.recordId })
        .then(blogs => {
            this.blogs = blogs;
        //   this.isLoading = false;

        })
        .catch(error => {
            console.error('Error:', error);
            this.error = 'Error loading blogs';
            this.isLoading = false;
        });
    }


    handleBlogSelect(event) {
        this.recordId = event.currentTarget.dataset.id;
        this.isLoading = true;
        this.showContent();

        publish(this.blogContext, BLOG_CHANNEL, {
            recordId: this.recordId
        });
    }
}