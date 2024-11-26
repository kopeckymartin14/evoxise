import { LightningElement, wire } from 'lwc';
import imageResource from '@salesforce/resourceUrl/bannerGradientX';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c'

export default class BannerComponent extends LightningElement {
    imageUrl = imageResource;
    context = createMessageContext();
    subscription = null;

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(this.context, NAVIGATION_CHANNEL, (message) => this.handleNavigation(message));
        }
        // Get the value after /s/
        const pathName = window.location.pathname;
        const pagePath = pathName.split('/s/')[1]; // Extract the part after `/s/`
        this.pageValue = pagePath ? pagePath.split('/')[0] : ''; // Take the first part of the path after `/s/`
        
        // Get the query parameters (e.g., recordId)
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);

        // Store query parameters (e.g., recordId)
        urlParams.forEach((value, key) => {
            this.queryParams[key] = value;
        });

    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
        releaseMessageContext(this.context);
    }

    handleNavigation(message) {
        let sectionId = message.sectionId;
        let sectionIdUpdated = `.${sectionId}`;
        let sectionElement = this.template.querySelector(sectionIdUpdated);
        if (sectionElement) {
            sectionElement.scrollIntoView({ behavior: 'smooth' });
        }
    }
}