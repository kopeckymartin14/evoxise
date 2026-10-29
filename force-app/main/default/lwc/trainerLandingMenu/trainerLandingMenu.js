import { LightningElement, api, track } from "lwc";
import { FlowNavigationNextEvent } from "lightning/flowSupport";
import getDashboardData from "@salesforce/apex/trainerLandingController.getDashboardData";
import cancelMeasure from "@salesforce/apex/trainerLandingController.cancelMeasure";
import markContacted from "@salesforce/apex/trainerLandingController.markContacted";
import markPortalSupportProcessed from "@salesforce/apex/trainerLandingController.markPortalSupportProcessed";
import updateLeadBookingStatus from "@salesforce/apex/trainerLandingController.updateLeadBookingStatus";

const INITIAL_VISIBLE_ROWS = 3;
const TERRITORY_TABS = ["Pezinok", "Bratislava"];
const TOAST_MS = 3000;
const CHANGE_REASON_LABELS = {
  Move_Date: "Presunúť termín",
  Change_Trainer: "Zmeniť trénera",
  Change_Type: "Zmeniť typ tréningu",
  Cancel_Training: "Zrušiť tréning",
  Other: "Iné"
};

export default class TrainerLandingMenu extends LightningElement {
  // ── Flow inputs ──────────────────────────────────────────
  @api serviceResourceId = "";
  @api trainerName = "";
  // SFSCH-slot-board-booking: true when the running user's profile is
  // "System Administrator" (formula isAdminProfile in the landing flow).
  @api isAdmin = false;

  // ── Flow outputs ─────────────────────────────────────────
  @api selectedAction = "";
  @api selectedRecordId = "";
  @api selectedPayerId = "";
  @api selectedSubProductsJson = "[]";
  @api buyProductsJson = "[]";
  @api blackHole = false;

  // ── Internal state ────────────────────────────────────────
  @track _todayTerritories = [];
  @track _activeTerritory = "Pezinok";
  @track _measures = [];
  @track _attendees = [];
  @track _measuresExpanded = false;
  @track _attendeesExpanded = false;
  @track _cancelMessage = null;
  _cancelTimer = null;
  @track _requests = [];
  @track _requestsExpanded = false;
  @track _contactedMessage = null;
  _contactedTimer = null;
  @track _changeRequests = [];
  @track _changeRequestsExpanded = false;
  @track _expandedChangeRequestId = null;
  @track _changeHandledMessage = null;
  _changeHandledTimer = null;
  @track _hyroxNotes = [];
  @track _hyroxNotesExpanded = false;
  @track _expandedHyroxNoteId = null;
  @track _hyroxNoteMessage = "";
  _hyroxNoteTimer;
  @track _support = [];
  @track _supportExpanded = false;
  @track _supportMessage = null;
  _supportTimer = null;
  @track _expandedSupportId = null;
  @track _leadAppointments = [];
  @track _leadAppointmentsExpanded = false;
  @track _leadStatusMessage = null;
  _leadStatusTimer = null;
  @track _subProductAppointments = [];
  @track _subProductsExpanded = false;
  @track _expandedSaId = null;
  @track _checkedJunctionIds = [];
  @track _selectedPayerAccountId = "";
  @track _blackHole = false;
  @track _isSuperUser = false;

  // UX state: loading, load failure, in-flight rows, confirm sheet,
  // and the screen-reader live region.
  @track _isLoading = true;
  @track _loadError = false;
  @track _busyIds = [];
  @track _liveMessage = "";
  @track _confirm = null;

  connectedCallback() {
    this._load();
  }

  disconnectedCallback() {
    [
      this._cancelTimer,
      this._contactedTimer,
      this._changeHandledTimer,
      this._supportTimer,
      this._leadStatusTimer
    ].forEach((t) => {
      if (t) clearTimeout(t);
    });
  }

  _load() {
    this._isLoading = true;
    this._loadError = false;
    getDashboardData({ serviceResourceId: this.serviceResourceId })
      .then((data) => {
        this._isLoading = false;
        if (!data) return;
        this._isSuperUser = data.isSuperUser === true;
        this._todayTerritories = data.todayAppointmentTerritories || [];
        this._measures = (data.accuniqMeasures || []).map((m) => ({
          id: m.id,
          clientName: m.clientName,
          status: m.status,
          isNotProcessed: m.isNotProcessed,
          branch: m.branch || "",
          priceFormatted: this._formatPrice(m.price)
        }));
        this._attendees = (data.negativeTokenAttendees || []).map((a) => ({
          id: a.id,
          accountId: a.accountId,
          territoryName: a.territoryName || "",
          accountName: a.accountName,
          availableCredit: this._formatCredit(a.availableCredit)
        }));
        this._requests = (data.bookingRequests || []).map((r) => ({
          id: r.id,
          name: r.name || r.email || "—",
          email: r.email || "—",
          phone: r.phone || "—",
          territoryName: r.territoryName || "",
          preferredDates: this._formatDates(r.preferredDates),
          trainerName: r.trainerName || "—"
        }));
        this._changeRequests = (data.changeRequests || []).map((c) => ({
          id: c.id,
          serviceAppointmentId: c.serviceAppointmentId,
          name: c.name || c.email || "—",
          phone: c.phone || "—",
          email: c.email || "—",
          territoryName: c.territoryName || "",
          whenFormatted: this._formatDayTime(c.apptStart),
          resourceName: c.resourceName || c.worktype || "—",
          reasonLabel: CHANGE_REASON_LABELS[c.reason] || c.reason || "—",
          reasonClass:
            c.reason === "Cancel_Training"
              ? "reason-pill reason-pill--danger"
              : "reason-pill",
          preferredDates: c.preferredDates || "—",
          message: c.message || "—",
          sentFormatted: this._formatDayTime(c.createdDate),
          trainerName: c.trainerName || "—"
        }));
        this._hyroxNotes = (data.hyroxNotes || []).map((n) => ({
          ...n,
          raceLabel: n.raceNumber ? `#${n.raceNumber}` : "—",
          nameLabel: n.participantNames || n.email,
          createdLabel: new Intl.DateTimeFormat("sk-SK", {
            day: "numeric",
            month: "numeric",
            hour: "2-digit",
            minute: "2-digit"
          }).format(new Date(n.createdDate))
        }));
        this._leadAppointments = (data.leadAppointments || []).map((la) => ({
          id: la.leadId,
          leadName: la.leadName || "—",
          email: la.email || "",
          territoryName: la.territoryName || "",
          timeFormatted: this._formatTime(la.startTime)
        }));
        this._support = (data.portalSupportRequests || []).map((s) => ({
          id: s.id,
          name: s.name || s.email || "—",
          email: s.email || "—",
          phone: s.phone || "—",
          category: s.category || "—",
          subject: s.subject || "—",
          question: s.question || "—",
          branch: s.branch || ""
        }));
        this._subProductAppointments = (data.subProductAppointments || []).map(
          (sa) => ({
            saId: sa.saId,
            clientName: sa.clientName || "—",
            timeFormatted: this._formatDayTime(sa.startTime),
            territoryName: sa.territoryName || "",
            subProducts: (sa.subProducts || []).map((l) => ({
              junctionId: l.junctionId,
              productId: l.productId,
              productName: l.productName,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              creditCost: l.creditCost
            })),
            payerCandidates:
              (sa.attendees || []).length > 0
                ? sa.attendees.map((a) => ({
                    accountId: a.accountId,
                    accountName: a.accountName
                  }))
                : sa.parentAccountId
                  ? [
                      {
                        accountId: sa.parentAccountId,
                        accountName: sa.parentAccountName || sa.clientName
                      }
                    ]
                  : []
          })
        );
      })
      .catch(() => {
        // Was an empty catch: the user saw an empty dashboard with no
        // explanation. Surface it instead.
        this._isLoading = false;
        this._loadError = true;
        this._announce("Dáta sa nepodarilo načítať.");
      });
  }

  handleRetryLoad() {
    this._load();
  }

  get isLoading() {
    return this._isLoading;
  }
  get loadError() {
    return this._loadError;
  }
  get liveMessage() {
    return this._liveMessage;
  }

  _announce(message) {
    this._liveMessage = message;
  }

  _isBusy(id) {
    return this._busyIds.includes(id);
  }
  _setBusy(id, busy) {
    if (busy) {
      if (!this._busyIds.includes(id)) {
        this._busyIds = [...this._busyIds, id];
      }
    } else {
      this._busyIds = this._busyIds.filter((x) => x !== id);
    }
  }

  // ── Confirm sheet ─────────────────────────────────────────
  get confirmOpen() {
    return this._confirm !== null;
  }
  get confirmMessage() {
    return this._confirm ? this._confirm.message : "";
  }

  _requestConfirm(message, action) {
    this._confirm = { message, action };
  }

  handleConfirmAccept() {
    const pending = this._confirm;
    this._confirm = null;
    if (pending && typeof pending.action === "function") {
      pending.action();
    }
  }

  handleConfirmCancel() {
    this._confirm = null;
  }

  handleScrimClick(event) {
    // Only a click on the scrim itself dismisses; clicks inside the sheet
    // bubble up here too.
    if (event.target === event.currentTarget) {
      this._confirm = null;
    }
  }

  handleConfirmKeydown(event) {
    if (event.key === "Escape") {
      this._confirm = null;
    }
  }

  // ── Derived display data ──────────────────────────────────
  get todayLabel() {
    const days = [
      "Nedeľa",
      "Pondelok",
      "Utorok",
      "Streda",
      "Štvrtok",
      "Piatok",
      "Sobota"
    ];
    const months = [
      "januára",
      "februára",
      "marca",
      "apríla",
      "mája",
      "júna",
      "júla",
      "augusta",
      "septembra",
      "októbra",
      "novembra",
      "decembra"
    ];
    const d = new Date();
    return `${days[d.getDay()]}, ${d.getDate()}. ${months[d.getMonth()]} ${d.getFullYear()}`;
  }

  _matchesTerritory(value) {
    const v = value || "";
    if (!TERRITORY_TABS.includes(v)) return true;
    return v === this._activeTerritory;
  }

  get territoryTabs() {
    return TERRITORY_TABS.map((name) => ({
      name,
      isActive: name === this._activeTerritory,
      cssClass:
        name === this._activeTerritory
          ? "territory-tab territory-tab--active"
          : "territory-tab"
    }));
  }

  handleTerritorySelect(event) {
    const name = event.currentTarget.dataset.territory;
    if (name === this._activeTerritory) return;
    this._activeTerritory = name;
    this._expandedSaId = null;
    this._expandedSupportId = null;
    this._expandedChangeRequestId = null;
    this._announce(`Pobočka ${name} zvolená.`);
  }

  get _todayCount() {
    return this._todayTerritories.filter((t) => this._matchesTerritory(t))
      .length;
  }

  get _filteredMeasures() {
    return this._measures.filter((m) => this._matchesTerritory(m.branch));
  }
  get _filteredAttendees() {
    return this._attendees.filter((a) =>
      this._matchesTerritory(a.territoryName)
    );
  }
  get _filteredRequests() {
    return this._requests.filter((r) =>
      this._matchesTerritory(r.territoryName)
    );
  }
  get _filteredChangeRequests() {
    return this._changeRequests.filter((c) =>
      this._matchesTerritory(c.territoryName)
    );
  }
  get _filteredLeadAppointments() {
    return this._leadAppointments.filter((la) =>
      this._matchesTerritory(la.territoryName)
    );
  }
  get _filteredSubProductAppointments() {
    return this._subProductAppointments.filter((sa) =>
      this._matchesTerritory(sa.territoryName)
    );
  }
  get _filteredSupport() {
    return this._support.filter((s) => this._matchesTerritory(s.branch));
  }

  get measuresCount() {
    return this._filteredMeasures.length;
  }
  get attendeesCount() {
    return this._filteredAttendees.length;
  }
  get hasMeasures() {
    return this.measuresCount > 0;
  }
  get hasAttendees() {
    return this.attendeesCount > 0;
  }
  get showSidebar() {
    return (
      this.hasChangeRequests ||
      this.hasMeasures ||
      this.hasAttendees ||
      this.hasRequests ||
      this.hasSupport ||
      this.hasLeadAppointments ||
      this.hasSubProducts ||
      this.hasHyroxNotes
    );
  }
  get mainGridClass() {
    return this.showSidebar
      ? "main-layout main-layout--with-sidebar"
      : "main-layout";
  }

  get measuresBadge() {
    return `${this.paidTodayCount} zaplatené`;
  }
  get paidTodayCount() {
    return this._filteredMeasures.filter((m) => !m.isNotProcessed).length;
  }
  get attendeesBadge() {
    return `${this.attendeesCount} klienti`;
  }

  get visibleMeasures() {
    const rows = this._measuresExpanded
      ? this._filteredMeasures
      : this._filteredMeasures.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((m) => ({ ...m, isBusy: this._isBusy(m.id) }));
  }
  get visibleAttendees() {
    return this._attendeesExpanded
      ? this._filteredAttendees
      : this._filteredAttendees.slice(0, INITIAL_VISIBLE_ROWS);
  }

  get showMeasuresToggle() {
    return this.measuresCount > INITIAL_VISIBLE_ROWS;
  }
  get showAttendeesToggle() {
    return this.attendeesCount > INITIAL_VISIBLE_ROWS;
  }

  get measuresToggleLabel() {
    if (this._measuresExpanded) return "Zobraziť menej";
    const hidden = this.measuresCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }
  get attendeesToggleLabel() {
    if (this._attendeesExpanded) return "Zobraziť menej";
    const hidden = this.attendeesCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }

  get cancelMessage() {
    return this._cancelMessage;
  }

  get isSuperUser() {
    return this._isSuperUser;
  }

  // SFSCH-slot-board-booking: the slot board is available to every trainer
  // (2026-09-04 enhancement; SuperUser__c / isAdmin no longer gate it).
  get showSlotBoard() {
    return true;
  }

  get requestsCount() {
    return this._filteredRequests.length;
  }
  get hasRequests() {
    return this.requestsCount > 0;
  }
  get requestsBadge() {
    return `${this.requestsCount} nové`;
  }
  get visibleRequests() {
    const rows = this._requestsExpanded
      ? this._filteredRequests
      : this._filteredRequests.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((r) => ({
      ...r,
      showTrainer: true,
      isBusy: this._isBusy(r.id),
      emailLabel: `Poslať email — ${r.name}`
    }));
  }
  get showRequestsToggle() {
    return this.requestsCount > INITIAL_VISIBLE_ROWS;
  }
  get requestsToggleLabel() {
    if (this._requestsExpanded) return "Zobraziť menej";
    const hidden = this.requestsCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }
  get contactedMessage() {
    return this._contactedMessage;
  }

  get changeRequestsCount() {
    return this._filteredChangeRequests.length;
  }
  get hasChangeRequests() {
    return this.changeRequestsCount > 0;
  }
  get changeRequestsBadge() {
    return `${this.changeRequestsCount} nové`;
  }
  get visibleChangeRequests() {
    const rows = this._changeRequestsExpanded
      ? this._filteredChangeRequests
      : this._filteredChangeRequests.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((r) => {
      const isExpanded = r.id === this._expandedChangeRequestId;
      return {
        ...r,
        isExpanded,
        rowClass: isExpanded ? "row row--button row--open" : "row row--button",
        isBusy: this._isBusy(r.id),
        showTrainer: this._isSuperUser
      };
    });
  }
  get showChangeRequestsToggle() {
    return this.changeRequestsCount > INITIAL_VISIBLE_ROWS;
  }
  get changeRequestsToggleLabel() {
    if (this._changeRequestsExpanded) return "Zobraziť menej";
    const hidden = this.changeRequestsCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }
  get changeHandledMessage() {
    return this._changeHandledMessage;
  }
  get requestsStatCount() {
    return this.requestsCount + this.changeRequestsCount;
  }

  get hyroxNotesCount() {
    return this._hyroxNotes.length;
  }
  get hasHyroxNotes() {
    // Super users only, like Podpora: these are participant messages for the
    // organisers, not something every trainer needs in their sidebar.
    return this._isSuperUser && this.hyroxNotesCount > 0;
  }
  get hyroxNotesBadge() {
    return `${this.hyroxNotesCount} nové`;
  }
  // Collapsed to INITIAL_VISIBLE_ROWS like every other sidebar section, so a
  // busy race week does not push the sections below it off the screen.
  get visibleHyroxNotes() {
    const rows = this._hyroxNotesExpanded
      ? this._hyroxNotes
      : this._hyroxNotes.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((r) => {
      const isExpanded = r.id === this._expandedHyroxNoteId;
      return {
        ...r,
        isExpanded,
        rowClass: isExpanded ? "row row--button row--open" : "row row--button",
        isBusy: this._isBusy(r.id),
        emailLabel: `Poslať email — ${r.nameLabel}`
      };
    });
  }
  get hyroxNoteMessage() {
    return this._hyroxNoteMessage;
  }
  get showHyroxNotesToggle() {
    return this.hyroxNotesCount > INITIAL_VISIBLE_ROWS;
  }
  get hyroxNotesToggleLabel() {
    if (this._hyroxNotesExpanded) return "Zobraziť menej";
    const hidden = this.hyroxNotesCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }
  toggleHyroxNotes() {
    this._hyroxNotesExpanded = !this._hyroxNotesExpanded;
  }

  handleHyroxNoteRowClick(event) {
    const id = event.currentTarget.dataset.id;
    this._expandedHyroxNoteId = this._expandedHyroxNoteId === id ? null : id;
  }

  // Hands the note off to the Flow, which sends the email. The component never
  // sends mail itself — same route as the Podpora and booking-request rows.
  handleSendHyroxNoteEmail(event) {
    event.stopPropagation();
    this._navigate("SendEmailHyroxNote", event.currentTarget.dataset.id);
  }

  // Bookkeeping, not destructive: no confirm step, matching Podpora. A misclick
  // is corrected by setting Status back to Request on the record itself.
  handleHyroxNoteDone(event) {
    event.stopPropagation();
    this._hyroxNoteDone(event.currentTarget.dataset.id);
  }

  _hyroxNoteDone(id) {
    this._setBusy(id, true);
    markContacted({ requestId: id })
      .then(() => {
        this._setBusy(id, false);
        this._hyroxNotes = this._hyroxNotes.filter((n) => n.id !== id);
        if (this._expandedHyroxNoteId === id) {
          this._expandedHyroxNoteId = null;
        }
        this._showToast(
          "_hyroxNoteMessage",
          "_hyroxNoteTimer",
          "Správa označená ako vybavená."
        );
      })
      .catch(() => {
        this._setBusy(id, false);
        this._showToast(
          "_hyroxNoteMessage",
          "_hyroxNoteTimer",
          "Chyba pri aktualizácii."
        );
      });
  }

  get supportCount() {
    return this._filteredSupport.length;
  }
  get hasSupport() {
    return this.supportCount > 0;
  }
  get supportBadge() {
    return `${this.supportCount} nové`;
  }
  get visibleSupport() {
    const rows = this._supportExpanded
      ? this._filteredSupport
      : this._filteredSupport.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((r) => {
      const isExpanded = r.id === this._expandedSupportId;
      return {
        ...r,
        isExpanded,
        rowClass: isExpanded ? "row row--button row--open" : "row row--button",
        isBusy: this._isBusy(r.id),
        emailLabel: `Poslať email — ${r.name}`
      };
    });
  }
  get showSupportToggle() {
    return this.supportCount > INITIAL_VISIBLE_ROWS;
  }
  get supportToggleLabel() {
    if (this._supportExpanded) return "Zobraziť menej";
    const hidden = this.supportCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }
  get supportMessage() {
    return this._supportMessage;
  }

  get leadAppointmentsCount() {
    return this._filteredLeadAppointments.length;
  }
  get hasLeadAppointments() {
    return this.leadAppointmentsCount > 0;
  }
  get leadAppointmentsBadge() {
    return `${this.leadAppointmentsCount} dnes`;
  }
  get visibleLeadAppointments() {
    const rows = this._leadAppointmentsExpanded
      ? this._filteredLeadAppointments
      : this._filteredLeadAppointments.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((la) => ({
      ...la,
      isBusy: this._isBusy(la.id),
      emailLabel: la.email || "bez emailu",
      copyLabel: `Kopírovať email — ${la.leadName}`
    }));
  }
  get showLeadAppointmentsToggle() {
    return this.leadAppointmentsCount > INITIAL_VISIBLE_ROWS;
  }
  get leadAppointmentsToggleLabel() {
    if (this._leadAppointmentsExpanded) return "Zobraziť menej";
    const hidden = this.leadAppointmentsCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }
  get leadStatusMessage() {
    return this._leadStatusMessage;
  }

  get subProductsCount() {
    return this._filteredSubProductAppointments.length;
  }
  get hasSubProducts() {
    return this.subProductsCount > 0;
  }
  get subProductsBadge() {
    return `${this.subProductsCount} nevybavené`;
  }
  get visibleSubProductAppointments() {
    const rows = this._subProductsExpanded
      ? this._filteredSubProductAppointments
      : this._filteredSubProductAppointments.slice(0, INITIAL_VISIBLE_ROWS);
    return rows.map((sa) => {
      const isOpen = sa.saId === this._expandedSaId;
      const singlePayer = sa.payerCandidates.length === 1;
      const products = sa.subProducts.map((l) => ({
        ...l,
        checked: this._checkedJunctionIds.includes(l.junctionId),
        lineLabel: `${l.productName} ×${l.quantity}`,
        priceFormatted: this._formatPrice(l.quantity * l.unitPrice)
      }));
      const payers = sa.payerCandidates.map((p) => {
        const selected = p.accountId === this._selectedPayerAccountId;
        return {
          ...p,
          locked: singlePayer,
          isSelected: selected,
          chipClass: selected ? "payer-chip payer-chip--selected" : "payer-chip"
        };
      });
      const anyChecked = isOpen && products.some((p) => p.checked);
      const payerChosen = isOpen && !!this._selectedPayerAccountId;
      const total = sa.subProducts.reduce(
        (sum, l) => sum + l.quantity * l.unitPrice,
        0
      );
      return {
        ...sa,
        isOpen,
        products,
        payers,
        hasPayers: sa.payerCandidates.length > 0,
        noPayers: sa.payerCandidates.length === 0,
        blackHole: this._blackHole,
        totalFormatted: this._formatPrice(total),
        productsLabel: `${sa.subProducts.length} produkt(y)`,
        payDisabled: !(anyChecked && payerChosen),
        rowClass: isOpen
          ? "subproduct-row subproduct-row--open"
          : "subproduct-row"
      };
    });
  }
  get showSubProductsToggle() {
    return this.subProductsCount > INITIAL_VISIBLE_ROWS;
  }
  get subProductsToggleLabel() {
    if (this._subProductsExpanded) return "Zobraziť menej";
    const hidden = this.subProductsCount - INITIAL_VISIBLE_ROWS;
    return `Zobraziť viac (${hidden})`;
  }

  // ── Click handlers ────────────────────────────────────────
  handleCardAction(event) {
    const action = event.currentTarget.dataset.action;
    this._navigate(action, "");
  }

  handlePayAccuniq(event) {
    const id = event.currentTarget.dataset.id;
    this._navigate("payAccuniq", id);
  }

  handleCancelAccuniqRequest(event) {
    const id = event.currentTarget.dataset.id;
    const name = event.currentTarget.dataset.name || "meranie";
    this._requestConfirm(
      `Naozaj zrušiť meranie pre ${name}? Túto akciu nie je možné vrátiť.`,
      () => this._cancelAccuniq(id)
    );
  }

  _cancelAccuniq(id) {
    this._setBusy(id, true);
    cancelMeasure({ measureId: id })
      .then(() => {
        this._setBusy(id, false);
        this._measures = this._measures.filter((m) => m.id !== id);
        this._showToast(
          "_cancelMessage",
          "_cancelTimer",
          "Meranie bolo zrušené."
        );
      })
      .catch(() => {
        this._setBusy(id, false);
        this._showToast(
          "_cancelMessage",
          "_cancelTimer",
          "Chyba pri rušení merania."
        );
      });
  }

  handleBuyTokens(event) {
    const accountId = event.currentTarget.dataset.accountid;
    this._navigate("buyTokens", accountId);
  }

  toggleMeasures() {
    this._measuresExpanded = !this._measuresExpanded;
  }
  toggleAttendees() {
    this._attendeesExpanded = !this._attendeesExpanded;
  }

  // Reversible bookkeeping, not destructive: no confirm step.
  handleMarkContactedRequest(event) {
    this._markContacted(event.currentTarget.dataset.id);
  }

  _markContacted(id) {
    this._setBusy(id, true);
    markContacted({ requestId: id })
      .then(() => {
        this._setBusy(id, false);
        this._requests = this._requests.filter((r) => r.id !== id);
        this._showToast(
          "_contactedMessage",
          "_contactedTimer",
          "Klient označený ako kontaktovaný."
        );
      })
      .catch(() => {
        this._setBusy(id, false);
        this._showToast(
          "_contactedMessage",
          "_contactedTimer",
          "Chyba pri aktualizácii."
        );
      });
  }

  toggleRequests() {
    this._requestsExpanded = !this._requestsExpanded;
  }

  toggleChangeRequests() {
    this._changeRequestsExpanded = !this._changeRequestsExpanded;
  }

  handleChangeRequestRowClick(event) {
    const id = event.currentTarget.dataset.id;
    this._expandedChangeRequestId =
      this._expandedChangeRequestId === id ? null : id;
  }

  // Reversible bookkeeping, not destructive: no confirm step.
  handleMarkChangeHandledRequest(event) {
    event.stopPropagation();
    this._markChangeHandled(event.currentTarget.dataset.id);
  }

  _markChangeHandled(id) {
    this._setBusy(id, true);
    markContacted({ requestId: id })
      .then(() => {
        this._setBusy(id, false);
        this._changeRequests = this._changeRequests.filter((c) => c.id !== id);
        if (this._expandedChangeRequestId === id) {
          this._expandedChangeRequestId = null;
        }
        this._showToast(
          "_changeHandledMessage",
          "_changeHandledTimer",
          "Žiadosť označená ako vybavená."
        );
      })
      .catch(() => {
        this._setBusy(id, false);
        this._showToast(
          "_changeHandledMessage",
          "_changeHandledTimer",
          "Chyba pri aktualizácii."
        );
      });
  }

  handleSendSupportEmail(event) {
    event.stopPropagation();
    const id = event.currentTarget.dataset.id;
    this._navigate("SendEmail", id);
  }

  handleSendBookingEmail(event) {
    event.stopPropagation();
    const id = event.currentTarget.dataset.id;
    this._navigate("SendEmailBooking", id);
  }

  // Reversible bookkeeping, not destructive: no confirm step.
  handleSupportCalledRequest(event) {
    event.stopPropagation();
    this._supportCalled(event.currentTarget.dataset.id);
  }

  _supportCalled(id) {
    this._setBusy(id, true);
    markPortalSupportProcessed({ supportId: id })
      .then(() => {
        this._setBusy(id, false);
        this._support = this._support.filter((s) => s.id !== id);
        if (this._expandedSupportId === id) {
          this._expandedSupportId = null;
        }
        this._showToast(
          "_supportMessage",
          "_supportTimer",
          "Žiadosť označená ako vybavená."
        );
      })
      .catch(() => {
        this._setBusy(id, false);
        this._showToast(
          "_supportMessage",
          "_supportTimer",
          "Chyba pri aktualizácii."
        );
      });
  }

  handleSupportRowClick(event) {
    const id = event.currentTarget.dataset.id;
    this._expandedSupportId = this._expandedSupportId === id ? null : id;
  }

  toggleSupport() {
    this._supportExpanded = !this._supportExpanded;
  }

  handleLeadCompleted(event) {
    this._setLeadStatus(event.currentTarget.dataset.id, "Completed");
  }

  handleLeadNoShowRequest(event) {
    const id = event.currentTarget.dataset.id;
    const name = event.currentTarget.dataset.name || "lead";
    this._requestConfirm(
      `Označiť ${name} ako neprítomného? Lead prejde do stavu No Show.`,
      () => this._setLeadStatus(id, "No_Show")
    );
  }

  toggleLeadAppointments() {
    this._leadAppointmentsExpanded = !this._leadAppointmentsExpanded;
  }

  handleCopyLeadEmail(event) {
    event.stopPropagation();
    const email = event.currentTarget.dataset.email;
    if (!email) return;
    if (!navigator.clipboard) {
      this._showLeadToast("Kopírovanie zlyhalo.");
      return;
    }
    navigator.clipboard
      .writeText(email)
      .then(() => this._showLeadToast("Email skopírovaný."))
      .catch(() => this._showLeadToast("Kopírovanie zlyhalo."));
  }

  _setLeadStatus(leadId, status) {
    this._setBusy(leadId, true);
    updateLeadBookingStatus({ leadId, status })
      .then(() => {
        this._setBusy(leadId, false);
        this._leadAppointments = this._leadAppointments.filter(
          (la) => la.id !== leadId
        );
        this._showLeadToast(
          status === "Completed"
            ? "Lead označený ako Completed."
            : "Lead označený ako No Show."
        );
      })
      .catch(() => {
        this._setBusy(leadId, false);
        this._showLeadToast("Chyba pri aktualizácii statusu.");
      });
  }

  _showLeadToast(message) {
    this._showToast("_leadStatusMessage", "_leadStatusTimer", message);
  }

  // Single toast helper: sets the visible message, announces it to screen
  // readers, and clears it after TOAST_MS.
  _showToast(messageProp, timerProp, message) {
    this[messageProp] = message;
    this._announce(message);
    if (this[timerProp]) clearTimeout(this[timerProp]);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this[timerProp] = setTimeout(() => {
      this[messageProp] = null;
    }, TOAST_MS);
  }

  handleSubProductRowClick(event) {
    const saId = event.currentTarget.dataset.said;
    if (this._expandedSaId === saId) {
      this._expandedSaId = null;
      return;
    }
    this._expandedSaId = saId;
    const sa = this._subProductAppointments.find((x) => x.saId === saId);
    this._checkedJunctionIds = sa
      ? sa.subProducts.map((l) => l.junctionId)
      : [];
    this._selectedPayerAccountId =
      sa && sa.payerCandidates.length === 1
        ? sa.payerCandidates[0].accountId
        : "";
    this._blackHole = false;
  }

  handleSubProductCheck(event) {
    event.stopPropagation();
    const id = event.target.dataset.junctionid;
    if (event.target.checked) {
      if (!this._checkedJunctionIds.includes(id)) {
        this._checkedJunctionIds = [...this._checkedJunctionIds, id];
      }
    } else {
      this._checkedJunctionIds = this._checkedJunctionIds.filter(
        (x) => x !== id
      );
    }
  }

  handleSubPayerSelect(event) {
    event.stopPropagation();
    this._selectedPayerAccountId = event.currentTarget.dataset.accountid;
  }

  handleBlackHoleToggle(event) {
    event.stopPropagation();
    this._blackHole = event.target.checked;
  }

  handleSubProductsPay(event) {
    event.stopPropagation();
    this._navigateSettle("paySubProducts");
  }

  handleSubProductsCredits(event) {
    event.stopPropagation();
    this._navigateSettle("creditSubProducts");
  }

  toggleSubProducts() {
    this._subProductsExpanded = !this._subProductsExpanded;
  }

  _navigateSettle(action) {
    const sa = this._subProductAppointments.find(
      (x) => x.saId === this._expandedSaId
    );
    if (!sa) return;
    const selected = sa.subProducts.filter((l) =>
      this._checkedJunctionIds.includes(l.junctionId)
    );
    if (selected.length === 0 || !this._selectedPayerAccountId) return;

    this.selectedPayerId = this._selectedPayerAccountId;
    this.selectedSubProductsJson = JSON.stringify(
      selected.map((l) => ({
        junctionId: l.junctionId,
        productId: l.productId,
        quantity: l.quantity,
        unitPrice: l.unitPrice,
        creditCost: l.creditCost
      }))
    );
    this.buyProductsJson = JSON.stringify(
      selected.map((l) => ({
        id: l.productId,
        qty: l.quantity,
        unitPrice: l.unitPrice
      }))
    );
    this.blackHole = this._blackHole;
    this._navigate(action, sa.saId);
  }

  // ── Helpers ───────────────────────────────────────────────
  _navigate(action, recordId) {
    this.selectedAction = action;
    this.selectedRecordId = recordId || "";
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  _formatPrice(n) {
    if (n === null || n === undefined) return "";
    return `${Number(n).toFixed(0)} €`;
  }

  _formatCredit(n) {
    if (n === null || n === undefined) return "";
    const v = Number(n);
    return v < 0 ? `−${Math.abs(v).toFixed(0)}` : `${v.toFixed(0)}`;
  }

  _formatTime(raw) {
    if (!raw) return "—";
    const d = new Date(raw);
    if (isNaN(d)) return "—";
    const hh = String(d.getHours()).padStart(2, "0");
    const mm = String(d.getMinutes()).padStart(2, "0");
    return `${hh}:${mm}`;
  }

  _formatDayTime(raw) {
    if (!raw) return "—";
    const d = new Date(raw);
    if (isNaN(d)) return "—";
    return `${d.getDate()}.${d.getMonth() + 1}. ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  }

  _formatDates(raw) {
    if (!raw) return "—";
    return raw
      .split(",")
      .map((s) => {
        const d = new Date(s.trim());
        if (isNaN(d)) return s.trim();
        return `${d.getUTCDate()}.${d.getUTCMonth() + 1}.`;
      })
      .join(", ");
  }
}