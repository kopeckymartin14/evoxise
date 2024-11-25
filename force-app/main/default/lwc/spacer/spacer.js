import { LightningElement, api } from 'lwc';

export default class Spacer extends LightningElement {
    @api height = 0;

    get style() {
        return `height: ${this.height}px; padding: 0; margin: 0; display: block;`;
    }

    renderedCallback() {
        this.template.querySelector('div').classList.add('slds-p-bottom_none');
    }
}