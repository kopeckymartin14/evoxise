import { LightningElement, api} from 'lwc';


export default class RedirectButton extends LightningElement {

    @api buttonName;
    @api url;


    connectedCallback() {

    }

    redirectTo() {
        this.isLoading = true;
        window.open(this.url, "_self");

    }
}