import { LightningElement, wire } from 'lwc';
import logo from '@salesforce/resourceUrl/ARXLogo';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c'


export default class HomePageResults extends LightningElement {

    context = createMessageContext();
    subscription = null;

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(this.context, NAVIGATION_CHANNEL, (message) => this.handleNavigation(message));
            console.log('this.subscription: ', this.subscription);
        }
        this.isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
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
    img_logo = logo;

    isMobile = false;


}