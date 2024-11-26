import { LightningElement, wire } from 'lwc';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c';
import ben12 from '@salesforce/resourceUrl/ben12';
import ben11 from '@salesforce/resourceUrl/ben11';
import ben10 from '@salesforce/resourceUrl/ben10';
import ben9 from '@salesforce/resourceUrl/ben9';
import ben8 from '@salesforce/resourceUrl/ben8';
import ben7 from '@salesforce/resourceUrl/ben7';
import ben6 from '@salesforce/resourceUrl/ben6';
import ben5 from '@salesforce/resourceUrl/ben5';
import ben4 from '@salesforce/resourceUrl/ben4';
import ben3 from '@salesforce/resourceUrl/ben3';
import ben2 from '@salesforce/resourceUrl/ben2';
import ben1 from '@salesforce/resourceUrl/ben1';

export default class HomePageResults extends LightningElement {
    img_ben12 = ben12;
    img_ben11 = ben11;
    img_ben10 = ben10;
    img_ben9 = ben9;
    img_ben8 = ben8;
    img_ben7 = ben7;
    img_ben6 = ben6;
    img_ben5 = ben5;
    img_ben4 = ben4;
    img_ben3 = ben3;
    img_ben2 = ben2;
    img_ben1 = ben1;

    context = createMessageContext();
    subscription = null;

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(this.context, NAVIGATION_CHANNEL, (message) => this.handleNavigation(message));
            console.log('this.subscription: ', this.subscription);
        }
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