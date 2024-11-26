import { LightningElement,track,wire } from 'lwc';
import machine from '@salesforce/resourceUrl/jobAvatar';
import machine2 from '@salesforce/resourceUrl/jobAvatar2';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';

import MODAL_OPEN_CHANNEL from '@salesforce/messageChannel/Modal_ARX__c'
export default class jobXComp extends LightningElement {
    img_machine = machine;
    img_machine2 = machine2;
    // context = createMessageContext();
    subscription = null;
    @track isModalOpen = false;
    context2 = createMessageContext();
    subscription2 = null;
    activeTile = null;

    connectedCallback() {


        if (!this.subscription2) {
            this.subscriptio2 = subscribe(this.context2, MODAL_OPEN_CHANNEL, (message) => this.openModal(message));
            console.log('this.subscription2: ', this.subscription2);
        }
    }

    disconnectedCallback() {
        // unsubscribe(this.subscription);
        // this.subscription = null;
        // releaseMessageContext(this.context);

        unsubscribe(this.subscription2);
        this.subscription2 = null;
        releaseMessageContext(this.context2);
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


    handleClick(event) {
        const clickedTile = event.currentTarget;
        const info = clickedTile.nextElementSibling;

        if (this.activeTile && this.activeTile !== clickedTile) {
            // Collapse the currently active tile
            this.activeTile.classList.remove('active');
            this.activeTile.nextElementSibling.style.maxHeight = 0;
        }

        // Toggle the clicked tile
        clickedTile.classList.toggle('active');

        if (clickedTile.classList.contains('active')) {
            // Expand the clicked tile
            info.style.maxHeight = info.scrollHeight + 'px';
            this.activeTile = clickedTile; // Update active tile
        } else {
            // Collapse the clicked tile
            info.style.maxHeight = 0;
            this.activeTile = null; // Clear active tile
        }
    }
}