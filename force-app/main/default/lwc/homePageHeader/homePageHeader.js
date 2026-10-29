import { LightningElement, track } from "lwc";

import { NavigationMixin } from "lightning/navigation";
import removeValidityToken from "@salesforce/apex/HeaderController.removeValidityToken";
import validateToken from "@salesforce/apex/HeaderController.validateToken";
import validateTrainerToken from "@salesforce/apex/HeaderController.validateTrainerToken";
import removeTrainerToken from "@salesforce/apex/HeaderController.removeTrainerToken";
import { saveSession, loadSession, clearSession } from "c/zoneSession";

import logoHeader from "@salesforce/resourceUrl/logoBlue";
import imageResource from "@salesforce/resourceUrl/bannerGradientX"; // Import the static resource
import logoHeaderBlack from "@salesforce/resourceUrl/logoblack";
import logoGradientMobile from "@salesforce/resourceUrl/logoGradientMobile";

import {
  createMessageContext,
  releaseMessageContext,
  publish
} from "lightning/messageService";
import NAVIGATION_CHANNEL from "@salesforce/messageChannel/Navigation_ARX__c";
import MODAL_OPEN_CHANNEL from "@salesforce/messageChannel/Modal_ARX__c";

// URL segment after /s/ → zone whose login token that page consumes.
const ZONE_BY_PAGE = { "trainer-zone": "trainer", "client-zone": "client" };
// Home URL parameter that opens the trainer login (after "Zmeniť trénera").
const TRAINER_LOGIN_PARAM = "trainerLogin";

// Studio submenus: each item jumps to a section of the studio page by URL anchor.
// The sections own the anchors (c/anchorScroll); "" is the top of the page.
const STUDIO_MENUS = [
  {
    key: "bratislava",
    label: "Bratislava",
    path: "/s/bratislava",
    items: [
      ["", "Prehľad štúdia"],
      ["arx", "Čo je ARX"],
      ["recenzie", "Recenzie"],
      ["porovnanie", "ARX vs posilňovňa"],
      ["treningy", "Tréningy"],
      ["sluzby", "Analýza a členstvá"],
      ["regeneracia", "Meranie a regenerácia"],
      ["darovat", "Darovať Evoxise"],
      ["pre-koho", "Pre koho"]
    ]
  },
  {
    key: "pezinok",
    label: "Pezinok",
    path: "/s/pezinok",
    items: [
      ["", "Prehľad štúdia"],
      ["arx", "Čo je ARX"],
      ["treneri", "Tréneri"],
      ["treningy", "Tréningy a cenník"]
    ]
  },
  {
    key: "8-challenge",
    label: "Eight Challenge",
    path: "/s/8-challenge",
    // The race page reads no token; the plain link it replaces passed none.
    token: false,
    items: [
      ["", "Prehľad"],
      ["full", "8 Challenge"],
      ["half", "8 Challenge HALF"],
      ["kids", "Eight Challenge KIDS"]
    ]
  }
];
// Phones get the full-screen menu, the same breakpoint as the header CSS
const MOBILE_MENU_QUERY = "(max-width: 767px)";

export default class HomePageHeader extends NavigationMixin(LightningElement) {
  // ── Zone session state ────────────────────────────────────
  // Set only after the server confirms the token (from the URL or this tab's storage).
  trainerToken = null;
  clientToken = null;
  // Bumped on logout and when the header leaves the page; a validation that
  // answers under an older epoch is ignored (no late re-login, no late redirect).
  _sessionEpoch = 0;
  // The token this page arrived with, so logout can revoke it even while its
  // validation is still pending (it is not in state or storage yet).
  _urlSession = null;

  // Stable references: renderedCallback runs again whenever the session state
  // re-renders the menu, and addEventListener ignores a listener that is already
  // registered — a fresh .bind() per render would stack duplicates and make the
  // hamburger toggle twice per click (never opening on mobile).
  _onNavButtonClick = () => this.handleNavButtonClick();
  _onMenuItemClick = () => this.closeMenu();

  isMobile = false;
  context = createMessageContext();
  logoHeaderMobile = logoGradientMobile;
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

  headerClass = "";
  // @track isMenuOpen = false;

  showModalOption = false;

  get hasTrainerSession() {
    return Boolean(this.trainerToken);
  }

  get hasClientSession() {
    return Boolean(this.clientToken);
  }

  get hasAnySession() {
    return this.hasTrainerSession || this.hasClientSession;
  }

  // Only the client token travels with public pages, as in goToPage
  get studioMenus() {
    const query = this.clientToken
      ? `?redir=yes&token=${encodeURIComponent(this.clientToken)}`
      : "";
    return STUDIO_MENUS.map((menu) => ({
      key: menu.key,
      label: menu.label,
      items: menu.items.map(([anchor, label]) => ({
        id: `${menu.key}-${anchor || "top"}`,
        label,
        href: `${menu.path}${menu.token === false ? "" : query}${anchor ? `#${anchor}` : ""}`
      }))
    }));
  }

  renderedCallback() {
    // Selectors to target elements within the component's shadow DOM
    this.body = this.template.querySelector(".body");
    this.header = this.template.querySelector("header");
    this.navButton = this.template.querySelector("header button");
    this.navigation = this.template.querySelector("header nav");
    this.menuItems = this.template.querySelectorAll("header ul a");
    this.headingText = this.template.querySelector("h1");
    this.blogItems = this.template.querySelectorAll("blog-item");

    // Adding event listeners
    this.navButton.addEventListener("click", this._onNavButtonClick);
    this.menuItems.forEach((menuItem) => {
      // submenu parents only open their list; they must not close the menu
      if (
        menuItem.getAttribute("data-section") != "zone__c" &&
        !menuItem.hasAttribute("data-submenu-toggle")
      ) {
        menuItem.addEventListener("click", this._onMenuItemClick);
      }
    });

    // this.blogItems.querySelectorAll('blog-item').forEach(blogItem => {
    //     blogItem.addEventListener('click', event => {
    //         // event.preventDefault();
    //         window.scrollTo({ top: 0, behavior: 'smooth' });
    //     });
    // });
  }

  // Toggle a sub-menu; at most one is open. Visibility follows aria-expanded in CSS
  // (no inline display, which used to outlive the desktop :hover rule).
  toggleSubmenu(event) {
    event.preventDefault();
    event.stopPropagation();
    // A click on an item inside the submenu closes it (the item's own handler navigates)
    if (event.target.closest(".submenu")) {
      this._closeSubmenus();
      return;
    }
    const submenuItem = event.currentTarget;
    const open = submenuItem.getAttribute("aria-expanded") !== "true";
    this._closeSubmenus();
    submenuItem.setAttribute("aria-expanded", open ? "true" : "false");
  }

  _closeSubmenus() {
    this.template
      .querySelectorAll('.has-submenu[aria-expanded="true"]')
      .forEach((item) => item.setAttribute("aria-expanded", "false"));
  }

  // Close any open sub-menus when clicking outside
  handleClickOutside(event) {
    const openSubmenu = this.template.querySelector(
      '.has-submenu[aria-expanded="true"]'
    );
    if (openSubmenu && !openSubmenu.contains(event.target)) {
      this._closeSubmenus();
    }
  }

  navigateToSection(event) {
    event.preventDefault();
    const sectionId = event.target.getAttribute("data-section"); // Extract the ID from the data-section attribute
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
    const isOpened = this.navButton.getAttribute("aria-expanded") === "true";
    const scroll = window.scrollY;
    if (isOpened) {
      if (scroll < 45) {
        this.header.classList.add("scrolled-to-top");
      } else {
        this.header.classList.remove("scrolled-to-top");
      }
      this.closeMenu();
    } else {
      if (scroll < 45) {
        this.header.classList.add("scrolled-to-top");
      } else {
        this.header.classList.remove("scrolled-to-top");
      }

      this.openMenu();
    }
    // this.header.classList.add('scrolled-to-top');
    this.header.style.boxShadow = "var(--box-shadow-100)";
  }

  // add/remove, not toggle: every menu link calls closeMenu, also while the menu is closed
  openMenu() {
    this.navButton.setAttribute("aria-expanded", "true");
    this.navButton.classList.add("open");
    this.navigation.classList.add("nav--open");
    this._lockPageScroll(true);
  }

  closeMenu() {
    this.navButton.setAttribute("aria-expanded", "false");
    this.navButton.classList.remove("open");
    this.navigation.classList.remove("nav--open");
    this._lockPageScroll(false);
  }

  // The phone menu covers the page, so the page behind it must not scroll
  _lockPageScroll(lock) {
    const phone =
      window.matchMedia && window.matchMedia(MOBILE_MENU_QUERY).matches;
    try {
      document.documentElement.style.overflow = lock && phone ? "hidden" : "";
    } catch (e) {
      // Style access blocked: the menu still opens, the page can scroll behind it
    }
  }

  connectedCallback() {
    this.isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
    if (this.isMobile) {
      this.logoHeader2 = this.logoHeaderMobile;
    }
    window.addEventListener("scroll", this.handleScroll.bind(this));

    const pathName = window.location.pathname;

    const pagePath = pathName.split("/s/")[1]; // Extract the part after `/s/`

    this.pageValue = pagePath ? pagePath.split("/")[0] : "";

    if (!this.pageValue) {
      this.showModalOption = true;
    }

    document.addEventListener("click", this.handleClickOutside.bind(this));
    this._handleKeyDown = this.handleKeyDown.bind(this);
    document.addEventListener("keydown", this._handleKeyDown);

    this.restoreSessions();
    // Arrived from "Zmeniť trénera": offer the trainer login straight away
    if (new URLSearchParams(window.location.search).get(TRAINER_LOGIN_PARAM)) {
      this.isTrainerZoneOpen = true;
    }
  }

  disconnectedCallback() {
    this._sessionEpoch += 1;
    releaseMessageContext(this.context);
    window.removeEventListener("scroll", this.handleScroll.bind(this));
    document.removeEventListener("click", this.handleClickOutside.bind(this));
    document.removeEventListener("keydown", this._handleKeyDown);
    this._lockPageScroll(false);
  }

  handleScroll() {
    const header = this.template.querySelector("header");
    const logoImage = this.template.querySelector("header img");
    if (header) {
      const scroll = window.scrollY;
      if (scroll < 45) {
        header.classList.add("scrolled-to-top");
        header.style.boxShadow = "none";
        header.style.backgroundColor = "transparent";
        logoImage.src = this.logoHeader2; // Set to default logo
      } else {
        header.classList.remove("scrolled-to-top");
        header.style.boxShadow = "0 5px 25px -15px #425466";
        header.style.backgroundColor = "white";
        if (!this.isMobile) {
          logoImage.src = this.logoHeaderBlack; // Change to scrolled logo
        }
      }
    }
  }

  @track isModalOpen = false;
  @track isClientZoneOpen = false;
  @track isTrainerZoneOpen = false;
  @track isContactPageOpen = false;
  @track isFirstTrainingOpen = false;
  @track isGiftOpen = false;
  @track isContactUsOpen = false;

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

  get firstTrainingInputVars() {
    return [{ name: "machineType", type: "String", value: "ARX" }];
  }

  openFirstTrainingPage() {
    // Open the modal
    this.isFirstTrainingOpen = true;
  }

  closeFirstTrainingPage() {
    // Close the modal
    this.isFirstTrainingOpen = false;
  }
  openGift() {
    // Open the modal
    this.isGiftOpen = true;
  }

  closeGift() {
    // Close the modal
    this.isGiftOpen = false;
  }

  openContactUs() {
    // Open the modal
    this.isContactUsOpen = true;
  }

  closeContactUs() {
    // Close the modal
    this.isContactUsOpen = false;
  }

  handleKeyDown(event) {
    if (event.key === "Escape") {
      if (this.isContactUsOpen) this.closeContactUs();
      else if (this.isFirstTrainingOpen) this.closeFirstTrainingPage();
      else if (this.isGiftOpen) this.closeGift();
      else if (this.isClientZoneOpen) this.closeClientZone();
      else if (this.isTrainerZoneOpen) this.closeTrainerZone();
      else if (this.isContactPageOpen) this.closeContactPage();
      else if (this.isModalOpen) this.closeModal();
    }
  }

  handleStatusChange(event) {
    // Optional: Close the modal when the flow finishes
    if (event.detail.status === "FINISHED") {
      this.closeModal();
    }
  }

  goToPage(event) {
    event.preventDefault();
    const sectionId = event.target.getAttribute("data-section");
    const pageReference = {
      type: "comm__namedPage",
      attributes: {
        name: sectionId // API name of your Community page (adjust as per your setup)
      }
    };
    // Only the client token travels with public pages. The trainer token is
    // never sent there: it would be validated against Account and dropped.
    if (this.clientToken) {
      pageReference.state = { redir: "yes", token: this.clientToken };
    }
    this[NavigationMixin.Navigate](pageReference);
  }

  // Same page: only the hash changes, so the section scrolls without a reload (hashchange).
  // Another page: a full load, which keeps the hash (probed on dev9 2026-10-28).
  goToSection(event) {
    event.preventDefault();
    const href = event.currentTarget.getAttribute("href");
    const at = href.indexOf("#");
    const hash = at >= 0 ? href.slice(at) : "";
    const path = href.split(/[?#]/)[0];
    const loc = window.location;
    if (loc.pathname !== path) {
      loc.assign(href);
      return;
    }
    const bare = loc.pathname + loc.search;
    if (!hash) {
      window.history.replaceState(window.history.state, "", bare);
      window.scrollTo({ top: 0, behavior: "smooth" });
      return;
    }
    // The same item again: clear the hash first, or no hashchange fires
    if (loc.hash === hash) {
      window.history.replaceState(window.history.state, "", bare);
    }
    loc.hash = hash;
  }

  goToTrainerZone(event) {
    event.preventDefault();
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: { url: this.zoneUrl("trainer") }
    });
  }

  // ── Zone sessions ─────────────────────────────────────────
  // The zone login flows hand the session over only as ?token= in the URL.
  // A token (from the URL, or remembered in this tab's sessionStorage) becomes a
  // session only after the server confirms it, so Back / reload keep the user
  // signed in while logged-out or expired tokens never come back.
  restoreSessions() {
    const pageZone = ZONE_BY_PAGE[(this.pageValue || "").toLowerCase()] || null;
    const urlToken = new URLSearchParams(window.location.search).get("token");
    // Public pages only ever carry the client token (goToPage adds it).
    const urlZone = urlToken ? pageZone || "client" : null;
    this._urlSession = urlZone ? { zone: urlZone, token: urlToken } : null;

    ["trainer", "client"].forEach((zone) => {
      const fromUrl = zone === urlZone;
      this.restoreZone(zone, {
        token: fromUrl ? urlToken : loadSession(zone),
        fromUrl,
        onZonePage: zone === pageZone
      });
    });
  }

  restoreZone(zone, { token, fromUrl, onZonePage }) {
    // Kept from before: the client zone without a valid token sends the visitor
    // Home; the trainer zone page flow shows its own no-access screen instead.
    const leaveIfClientZone = () => {
      if (onZonePage && zone === "client") {
        this.goHome();
      }
    };
    if (!token) {
      leaveIfClientZone();
      return;
    }
    const epoch = this._sessionEpoch;
    const validate = zone === "trainer" ? validateTrainerToken : validateToken;
    validate({ token })
      .then((isValid) => {
        // Logged out, or this header left the page, while the server answered.
        if (epoch !== this._sessionEpoch) {
          return;
        }
        if (!isValid) {
          // A rejected URL token says nothing about a different stored one.
          if (!fromUrl) {
            clearSession(zone);
          }
          leaveIfClientZone();
          return;
        }
        saveSession(zone, token);
        this.setZoneToken(zone, token);
        if (onZonePage && !fromUrl) {
          // Full load, not NavigationMixin: the page flow reads {!token} only
          // when the page is built, so it must start again with the token.
          window.location.replace(this.zoneUrl(zone));
        }
      })
      .catch((error) => {
        // Server or network hiccup: keep the stored token for the next page.
        console.error("Zone session restore failed:", error);
      });
  }

  setZoneToken(zone, token) {
    if (zone === "trainer") {
      this.trainerToken = token;
    } else {
      this.clientToken = token;
    }
  }

  urlTokenFor(zone) {
    return this._urlSession && this._urlSession.zone === zone
      ? this._urlSession.token
      : null;
  }

  zoneUrl(zone) {
    return zone === "trainer"
      ? `/s/trainer-zone?token=${encodeURIComponent(this.trainerToken)}`
      : `/s/client-zone?redir=yes&token=${encodeURIComponent(this.clientToken)}`;
  }

  goHome() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: "Home"
      }
    });
  }

  handleLogout(event) {
    event.preventDefault();
    // A validation may still be in flight: revoke what this tab holds, not only
    // what the menu shows, and make any late answer stale.
    this._sessionEpoch += 1;
    const trainerToken =
      this.trainerToken ||
      loadSession("trainer") ||
      this.urlTokenFor("trainer");
    const clientToken =
      this.clientToken || loadSession("client") || this.urlTokenFor("client");
    this._urlSession = null;
    const pending = [];
    if (trainerToken) {
      pending.push(removeTrainerToken({ token: trainerToken }));
    }
    if (clientToken) {
      pending.push(removeValidityToken({ token: clientToken }));
    }
    clearSession("trainer");
    clearSession("client");
    this.trainerToken = null;
    this.clientToken = null;
    // Home either way: a failed server call must not keep this tab signed in.
    Promise.allSettled(pending).then(() => this.goHome());
  }

  // Shared trainer PC: end only this trainer's session, then a full load of Home
  // (nothing of the previous trainer's page survives) with the trainer login open.
  handleSwitchTrainer(event) {
    event.preventDefault();
    this._sessionEpoch += 1;
    const trainerToken =
      this.trainerToken ||
      loadSession("trainer") ||
      this.urlTokenFor("trainer");
    if (this.urlTokenFor("trainer")) {
      this._urlSession = null;
    }
    clearSession("trainer");
    this.trainerToken = null;
    const pending = trainerToken
      ? [removeTrainerToken({ token: trainerToken })]
      : [];
    Promise.allSettled(pending).then(() =>
      window.location.assign(`/s/?${TRAINER_LOGIN_PARAM}=1`)
    );
  }
}