import { LightningElement,track,wire } from 'lwc';
import machine from '@salesforce/resourceUrl/ARXMachine';
import video from '@salesforce/resourceUrl/Video_ARX';
import { createMessageContext, releaseMessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c'
import MODAL_OPEN_CHANNEL from '@salesforce/messageChannel/Modal_ARX__c'
import './homePageARX.css';
export default class HomePageARX extends LightningElement {
    videoUrl = video;
    img_machine = machine
    context = createMessageContext();
    subscription = null;
    @track isModalOpen = false;
    context2 = createMessageContext();
    subscription2 = null;

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(this.context, NAVIGATION_CHANNEL, (message) => this.handleNavigation(message));
        }

        if (!this.subscription2) {
            this.subscription2 = subscribe(this.context2, MODAL_OPEN_CHANNEL, (message) => this.openModal(message));
        }
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
        releaseMessageContext(this.context);

        unsubscribe(this.subscription2);
        this.subscription2 = null;
        releaseMessageContext(this.context2);
    }


    openModal(message) {
        let openModal = message.modal;
        this.isModalOpen = true;
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
}