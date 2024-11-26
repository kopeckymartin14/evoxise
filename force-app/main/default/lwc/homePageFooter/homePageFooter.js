import { LightningElement, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c'
export default class HomePageFooter extends NavigationMixin(LightningElement) {
    @track isModalOpen = false;
    @track isModalOpen2 = false;

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

    handleButtonClick() {
        // Open the modal
        this.isModalOpen = true;
    }

    closeModal() {
        // Close the modal
        this.isModalOpen = false;
    }

    handleStatusChange(event) {
        // Optional: Close the modal when the flow finishes
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }
    handleButtonClick2() {
        // Open the modal
        this.isModalOpen2 = true;
    }

    closeModal2() {
        // Close the modal
        this.isModalOpen2 = false;
    }

    handleStatusChange2(event) {
        // Optional: Close the modal when the flow finishes
        if (event.detail.status === 'FINISHED') {
            this.closeModal2();
        }
    }

    goToPage(event) {
        event.preventDefault();
        const sectionId = event.target.getAttribute('data-section');
        console.log('sectionId: ', sectionId );
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: sectionId // API name of your Community page (adjust as per your setup)
            }
        });
    }
}