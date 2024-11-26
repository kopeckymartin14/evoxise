import { LightningElement, wire } from 'lwc';
import BCK_siluette from '@salesforce/resourceUrl/siluette';
import BCK_Strength from '@salesforce/resourceUrl/resultsStrength';
import BCK_Muscle from '@salesforce/resourceUrl/resultsMuscle';
import BCK_VO2Max from '@salesforce/resourceUrl/resultsVO2Max';
import BCK_Fat from '@salesforce/resourceUrl/resultsFat';
import BCK_Time from '@salesforce/resourceUrl/resultsTime';
import BCK_Safety from '@salesforce/resourceUrl/resultsSafety';
import BCK_card from '@salesforce/resourceUrl/resultsCard';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c'

export default class HomePageResults extends LightningElement {
    siluette = BCK_siluette;
    strength = BCK_Strength;
    muscle = BCK_Muscle;
    vo2max = BCK_VO2Max;
    fat = BCK_Fat;
    time = BCK_Time;
    safety = BCK_Safety;
    card = BCK_card;

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