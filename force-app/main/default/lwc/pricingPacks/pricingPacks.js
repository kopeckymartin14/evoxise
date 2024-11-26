import { LightningElement,track,wire } from 'lwc';
import single from '@salesforce/resourceUrl/pricingPackSingle';
import double from '@salesforce/resourceUrl/pricingPackDouble';

import { createMessageContext, releaseMessageContext, subscribe, unsubscribe, publish } from 'lightning/messageService';
import MODAL_OPEN_CHANNEL from '@salesforce/messageChannel/Modal_ARX__c'

export default class PricingPacks extends LightningElement {
    img_single = single;
    img_double = double;
    context = createMessageContext();
    subscription = null;
    @track isModalOpen = false;

    connectedCallback() {

        if (!this.subscription) {
            this.subscription = subscribe(this.context, MODAL_OPEN_CHANNEL, (message) => this.openModal(message));
            console.log('this.subscription: ', this.subscription);
        }
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
        releaseMessageContext(this.context);

    }


    openModal(message) {
        let openModal = message.modal;
        this.isModalOpen = true;
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
}