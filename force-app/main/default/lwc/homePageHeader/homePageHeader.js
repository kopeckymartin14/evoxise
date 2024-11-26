import { LightningElement, track, wire } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import removeValidityToken from '@salesforce/apex/HeaderController.removeValidityToken';
import validateToken from '@salesforce/apex/HeaderController.validateToken';

import logoHeader from '@salesforce/resourceUrl/logoBlue';
import imageResource from '@salesforce/resourceUrl/bannerGradientX'; // Import the static resource
import logoHeaderBlack from '@salesforce/resourceUrl/logoblack'; 

import { createMessageContext, releaseMessageContext, publish } from 'lightning/messageService';
import NAVIGATION_CHANNEL from '@salesforce/messageChannel/Navigation_ARX__c';
import MODAL_OPEN_CHANNEL from '@salesforce/messageChannel/Modal_ARX__c';

export default class HomePageHeader extends NavigationMixin(LightningElement) {

    @track token;


    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state) {
            this.token = pageRef.state.token; // Get the recordId from the URL parameters
        }
    }

    context = createMessageContext();

    imageUrl = imageResource;
    logoHeader2 = logoHeader;
    logoHeaderBlack = logoHeaderBlack; // New logo URL
    currentLogo = this.logoHeader2; // Default to the original logo
    body;
    header;
    navButton;
    navigation;
    menuItems;
    headingText;

    headerClass = '';
    // @track isMenuOpen = false;

    
    showModalOption = false;

    get isTokenAvailable() {
        return this.token && this.token != null;
    }

    renderedCallback() {
        // Selectors to target elements within the component's shadow DOM
        this.body = this.template.querySelector('.body');
        this.header = this.template.querySelector('header');
        this.navButton = this.template.querySelector('header button');
        this.navigation = this.template.querySelector('header nav');
        this.menuItems = this.template.querySelectorAll('header ul a');
        this.headingText = this.template.querySelector('h1');
        this.blogItems = this.template.querySelectorAll('blog-item');

        // Adding event listeners
        this.navButton.addEventListener('click', this.handleNavButtonClick.bind(this));
        this.menuItems.forEach(menuItem => {
            if(menuItem.getAttribute('data-section') !='zone__c') {                
                menuItem.addEventListener('click', this.closeMenu.bind(this));}
            });

        // this.blogItems.querySelectorAll('blog-item').forEach(blogItem => {
        //     blogItem.addEventListener('click', event => {
        //         // event.preventDefault();
        //         window.scrollTo({ top: 0, behavior: 'smooth' });
        //     });
        // });
    }

     // Toggle main menu on mobile
    toggleMenu(element) {
        // this.isMenuOpen = !this.isMenuOpen;
        // const primaryNav = this.template.querySelector('#primary-navigation');
        // primaryNav.classList.toggle('nav--open', this.isMenuOpen);
        element.classList.toggle('nav--open');
    }

    // Toggle sub-menu
    toggleSubmenu(event) {
        event.preventDefault();
        event.stopPropagation();

        // Get the submenu element
        const submenuItem = event.currentTarget;
        const submenu = submenuItem.querySelector('.submenu');

        // Toggle aria-expanded and submenu visibility
        const isExpanded = submenuItem.getAttribute('aria-expanded') === 'true';
        submenuItem.setAttribute('aria-expanded', !isExpanded);
        submenu.style.display = isExpanded ? 'none' : 'block';
    }

    // Close any open sub-menus when clicking outside
    handleClickOutside(event) {
        const openSubmenu = this.template.querySelector('.has-submenu[aria-expanded="true"]');
        if (openSubmenu && !openSubmenu.contains(event.target)) {
        openSubmenu.setAttribute('aria-expanded', 'false');
        const submenu = openSubmenu.querySelector('.submenu');
        submenu.style.display = 'none';
        }
    }

    navigateToSection(event) {
        event.preventDefault();
        const sectionId = event.target.getAttribute('data-section'); // Extract the ID from the data-section attribute
        // Publish the message
        publish(this.context, NAVIGATION_CHANNEL, {
            sectionId: sectionId
        });
    }

    openModal(event) {
        event.preventDefault();
        // const sectionId = event.target.getAttribute('data-section'); // Extract the ID from the data-section attribute
        // Publish the message
        publish(this.context, MODAL_OPEN_CHANNEL, {
            modal: true
        });
    }





    handleNavButtonClick() {
        const isOpened = this.navButton.getAttribute('aria-expanded') === "true";
        if (isOpened) {
            this.closeMenu();
        } else {
            this.openMenu();
        }
        this.header.classList.add('scrolled-to-top');
        this.header.style.boxShadow = 'var(--box-shadow-100)';
    }

    openMenu() {
        this.navButton.setAttribute('aria-expanded', 'true');
        this.navButton.classList.toggle('open');
        this.navigation.classList.toggle('nav--open');
    }

    closeMenu() {
        this.navButton.setAttribute('aria-expanded', 'false');
        this.navButton.classList.toggle('open');
        this.navigation.classList.toggle('nav--open');
    }

    connectedCallback() {
        window.addEventListener('scroll', this.handleScroll.bind(this));

        const pathName = window.location.pathname;

        const pagePath = pathName.split('/s/')[1]; // Extract the part after `/s/`

        this.pageValue = pagePath ? pagePath.split('/')[0] : '';

        if(!this.pageValue) {
            this.showModalOption = true;
        }

        document.addEventListener('click', this.handleClickOutside.bind(this));

    }

    disconnectedCallback() {
        releaseMessageContext(this.context);
        window.removeEventListener('scroll', this.handleScroll.bind(this));
        document.removeEventListener('click', this.handleClickOutside.bind(this));

    }


      handleScroll() {
        const header = this.template.querySelector('header');
        const logoImage = this.template.querySelector('header img');
        if (header) {
            const scroll = window.scrollY;
            if (scroll < 90) {
                header.classList.add('scrolled-to-top');
                header.style.boxShadow = 'none';
                header.style.backgroundColor = 'transparent';
                logoImage.src = this.logoHeader2; // Set to default logo
            } else {
                header.classList.remove('scrolled-to-top');
                header.style.boxShadow = '0 5px 25px -15px #425466';
                header.style.backgroundColor = 'white';
                logoImage.src = this.logoHeaderBlack; // Change to scrolled logo
            }
        }
    }

    @track isModalOpen = false;
    @track isClientZoneOpen = false;
    @track isTrainerZoneOpen = false;
    @track isContactPageOpen = false;

    handleButtonClick() {
        // Open the modal
        this.isModalOpen = true;
    }

    closeModal() {
        // Close the modal
        this.isModalOpen = false;

    }
    openClientZone() {
        
        // Open the modal
        this.isClientZoneOpen = true;
    }

    closeClientZone() {
        // Close the modal
        this.isClientZoneOpen = false;

    }
    openTrainerZone() {
        // Open the modal
        this.isTrainerZoneOpen = true;
    }

    closeTrainerZone() {
        // Close the modal
        this.isTrainerZoneOpen = false;

    }

    openContactPage() {
        // Open the modal
        this.isContactPageOpen = true;
    }

    closeContactPage() {
        // Close the modal
        this.isContactPageOpen = false;
    }


    handleStatusChange(event) {
        // Optional: Close the modal when the flow finishes
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }

    goToPage(event) {
        event.preventDefault();
        const sectionId = event.target.getAttribute('data-section');
        if(this.token && this.token != null) {
            if(sectionId == 'clientzone__c') {
                validateToken({ token : this.token })
                  .then(result => {
                    console.log('result client zone: ', result);
                    if(result) {
                        this[NavigationMixin.Navigate]({
                            type: 'comm__namedPage',
                            attributes: {
                                name: sectionId // API name of your Community page (adjust as per your setup)
                            },
                            state: {
                                redir: 'yes',
                                token: this.token
                            }
                        });
                    }
                    else {
                        this.token = null;
                        this.isClientZoneOpen = true;
                    }
                  })
                  .catch(error => {
                    console.error('Error:', error);
                });
            }
            else {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        name: sectionId // API name of your Community page (adjust as per your setup)
                    },
                    state: {
                        redir: 'yes',
                        token: this.token
                    }
                });
            }
            
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: sectionId // API name of your Community page (adjust as per your setup)
                }
            });
        }
    }

    handleLogout(event) {

        event.preventDefault();
       

        removeValidityToken({ token: this.token })
          .then(result => {
            this.token = null;
            console.log('result: ', result);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Home' // Replace with the API name of your login page
                }
            });
          })
          .catch(error => {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Home' // Replace with the API name of your login page
                }
            });
        });
        // Redirect to the login page or homepage
        
    }
}