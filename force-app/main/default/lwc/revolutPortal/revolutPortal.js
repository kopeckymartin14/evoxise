import { LightningElement, api } from 'lwc';

export default class revolutPortal extends LightningElement {
    @api revolutUrl;

    renderedCallback() {
        console.log("callback");
        const iframe = this.template.querySelector('iframe');
        iframe.src = "https://sandbox-checkout.revolut.com/payment-link/a48c225d-2b3f-4701-84e1-209844685c14";
        if (this.revolutUrl) {
            console.log(revolutUrl);
            const iframe = this.template.querySelector('iframe');
            iframe.src = this.revolutUrl;
        }
    }
}