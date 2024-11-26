import { LightningElement, wire, track } from 'lwc';

import imageResource from '@salesforce/resourceUrl/bannerGradientX';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import getHeader from '@salesforce/apex/HeaderController.getHeaderData';
import getBlogRecord from '@salesforce/apex/BlogController.getBlogRecordById';


import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c'
import BLOG_CHANNEL from '@salesforce/messageChannel/Blog_ARX__c'

export default class BannerComponent extends LightningElement {
    imageUrl = imageResource;
    context = createMessageContext();
    blogContext = createMessageContext();
    subscription = null;
    blogSubscription = null;
    @track metadata;
    recordId;
    @track isLoading = true;

    @track pageValue; // To store the value after `/s/`
    @track queryParams = {};



    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(this.context, NAVIGATION_CHANNEL, (message) => this.handleNavigation(message));
            console.log('this.subscription: ', this.subscription);
        }

        if (!this.blogSubscription) {
            this.blogSubscription = subscribe(this.blogContext, BLOG_CHANNEL, (blog) => this.changeTitle(blog));
            console.log('this.blogSubscription: ', this.blogSubscription);
        }

        // Get the value after /s/
        const pathName = window.location.pathname;

        const pagePath = pathName.split('/s/')[1]; // Extract the part after `/s/`

        this.pageValue = pagePath ? pagePath.split('/')[0] : ''; // Take the first part of the path after `/s/`

        getHeader({ pageName: this.pageValue })
        .then(result => {
            console.log('Result', result);
            
            this.metadata = result;
            this.isLoading = false;
            if(result.Is_Record_Page__c) {
                this.getTitle();
            }
        
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }

    getTitle() {
        // Get the query parameters (e.g., recordId)
         const queryString = window.location.search;
         const urlParams = new URLSearchParams(queryString);
 
         // Store query parameters (e.g., recordId)
         urlParams.forEach((value, key) => {
             this.queryParams[key] = value;
         });
        
        const blogId = this.queryParams['recordId'];
        console.log('Query Parameters: ', this.queryParams['recordId']); // Debugging
        if(blogId != null) {
            getBlogRecord({ blogId: blogId })
            .then(result => {
                console.log('Result in header', result);
                this.metadata.SubHeadline__c = result.Title__c;
            })
            .catch(error => {
                console.error('Error:', error);
          });
        }
        
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
        releaseMessageContext(this.context);

        unsubscribe(this.blogSubscription);
        this.blogSubscription = null;
        releaseMessageContext(this.blogContext);
    }

    handleNavigation(message) {
        let sectionId = message.sectionId;
        let sectionIdUpdated = `.${sectionId}`;
        let sectionElement = this.template.querySelector(sectionIdUpdated);
        if (sectionElement) {
            sectionElement.scrollIntoView({ behavior: 'smooth' });
        }
    }

    changeTitle(blog) {
        getBlogRecord({ blogId: blog.recordId })
        .then(result => {
            console.log('Result in header', result);
            this.metadata.SubHeadline__c = result.Title__c;
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }
}