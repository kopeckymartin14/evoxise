public without sharing class LeadConversionController {
  // Server page size for the lead list (load-more pagination).
  private static final Integer PAGE_SIZE = 15;

  public class LeadDTO implements Comparable {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String firstName;
    @AuraEnabled
    public String lastName;
    @AuraEnabled
    public String fullName;
    @AuraEnabled
    public String email;
    @AuraEnabled
    public String mobilePhone;
    @AuraEnabled
    public String referralId;
    @AuraEnabled
    public String referralAccountId;
    @AuraEnabled
    public Datetime createdDate;
    @AuraEnabled
    public String note;
    @AuraEnabled
    public String bookingStatus;
    @AuraEnabled
    public String company;
    // Picked Paid appointment: WITH = next upcoming, POST = most recent past;
    // also set on processed rows from the lead's old SA. Start time + trainer.
    @AuraEnabled
    public Datetime trainingDate;
    @AuraEnabled
    public String trainerName;
    // Vestigial — always false since the Spartan tab was removed; kept for
    // DTO/API stability.
    @AuraEnabled
    public Boolean hasAppointment;
    // 'open' = standard open lead; 'processed' = Processed lead migrated to an
    // Account (same Email__c) that never had a ServiceAppointment.
    @AuraEnabled
    public String kind;

    // Sort newest-first by Lead CreatedDate with an Id DESC tiebreak (matches
    // the SOQL ordering so the load-more cursor is deterministic); nulls last.
    public Integer compareTo(Object other) {
      LeadDTO o = (LeadDTO) other;
      if (this.createdDate == o.createdDate) {
        if (this.id == o.id) {
          return 0;
        }
        if (this.id == null) {
          return 1;
        }
        if (o.id == null) {
          return -1;
        }
        // Compare as Id (case-sensitive), NOT the String > operator: Apex
        // String comparison is case-INSENSITIVE and disagrees with SOQL's
        // case-sensitive ORDER BY Id / Id < :cursor, which would let a row
        // land on two pages (or be skipped) across the load-more boundary.
        Id thisId = (Id) this.id;
        Id otherId = (Id) o.id;
        return thisId > otherId ? -1 : 1;
      }
      if (this.createdDate == null) {
        return 1;
      }
      if (o.createdDate == null) {
        return -1;
      }
      return this.createdDate > o.createdDate ? -1 : 1;
    }
  }

  // One page of leads for the finder; hasMore drives the load-more button.
  public class LeadPage {
    @AuraEnabled
    public List<LeadDTO> leads = new List<LeadDTO>();
    @AuraEnabled
    public Boolean hasMore = false;
  }

  // Internal: processed-sublist page + whether its raw query filled a page.
  private class ProcessedResult {
    List<LeadDTO> dtos = new List<LeadDTO>();
    Boolean rawFull = false;
  }

  @AuraEnabled(cacheable=false)
  public static LeadPage getLeads(
    String searchTerm,
    String source,
    String territory,
    Datetime beforeCreated,
    Id beforeId
  ) {
    LeadPage result = new LeadPage();
    List<LeadDTO> out = new List<LeadDTO>();

    // Resolve source token -> ServiceAppointment filter mode. Territory
    // (Home_Branch__c) is the primary scoping filter; 'NoBranch' = null branch.
    String saMode = 'NONE'; // NONE | WITH | WITHOUT | POST
    if (source == 'FreeTraining_NoAppt') {
      saMode = 'WITHOUT';
    } else if (source == 'FreeTraining_PostTraining') {
      saMode = 'POST';
    } else if (source == 'FreeTraining_WithAppt') {
      saMode = 'WITH';
    }
    Boolean noBranch = (territory == 'NoBranch');
    String branch = territory;

    Boolean hasTerm = String.isNotBlank(searchTerm);
    String pattern = hasTerm
      ? '%' + String.escapeSingleQuotes(searchTerm) + '%'
      : null;
    Integer rowLimit = PAGE_SIZE;
    // Cursor = (CreatedDate, Id) of the last row already shown; null = page 1.
    Boolean hasCursor = beforeCreated != null && beforeId != null;

    // Collect Lead ids that have a Paid ServiceAppointment. Done as a separate
    // query (not a polymorphic semi-join) so the IN/NOT IN bind is deterministic
    // across org and test contexts.
    Set<Id> paidLeadIds = new Set<Id>();
    // Picked Paid SA per lead — POST: most recent past training (max
    // SchedStartTime); WITH: next upcoming training (min SchedStartTime).
    // Source of the trainer and training-date info shown on WITH/POST rows.
    Map<Id, ServiceAppointment> pickSaByLead = new Map<Id, ServiceAppointment>();
    if (saMode == 'WITH' || saMode == 'WITHOUT' || saMode == 'POST') {
      String leadKeyPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
      Datetime nowDt = Datetime.now();
      // POST keeps appointments already started; WITH keeps only upcoming ones
      // (a lead whose training already happened belongs on the POST tab);
      // WITHOUT keeps any Paid appointment (it excludes via NOT IN).
      List<ServiceAppointment> sas;
      if (saMode == 'POST') {
        sas = [
          SELECT Id, ParentRecordId, SchedStartTime
          FROM ServiceAppointment
          WHERE
            Status = 'Paid'
            AND ParentRecordId != NULL
            AND SchedStartTime != NULL
            AND SchedStartTime < :nowDt
          LIMIT 50000
        ];
      } else if (saMode == 'WITH') {
        sas = [
          SELECT Id, ParentRecordId, SchedStartTime
          FROM ServiceAppointment
          WHERE
            Status = 'Paid'
            AND ParentRecordId != NULL
            AND SchedStartTime != NULL
            AND SchedStartTime > :nowDt
          LIMIT 50000
        ];
      } else {
        sas = [
          SELECT Id, ParentRecordId, SchedStartTime
          FROM ServiceAppointment
          WHERE Status = 'Paid' AND ParentRecordId != NULL
          LIMIT 50000
        ];
      }
      Boolean pickEarliest = (saMode == 'WITH');
      for (ServiceAppointment sa : sas) {
        String prid = String.valueOf(sa.ParentRecordId);
        if (prid != null && prid.startsWith(leadKeyPrefix)) {
          paidLeadIds.add(sa.ParentRecordId);
          ServiceAppointment prev = pickSaByLead.get(sa.ParentRecordId);
          Boolean replacePick;
          if (prev == null) {
            replacePick = true;
          } else if (sa.SchedStartTime == null) {
            replacePick = false;
          } else if (prev.SchedStartTime == null) {
            replacePick = true;
          } else {
            replacePick = pickEarliest
              ? sa.SchedStartTime < prev.SchedStartTime
              : sa.SchedStartTime > prev.SchedStartTime;
          }
          if (replacePick) {
            pickSaByLead.put(sa.ParentRecordId, sa);
          }
        }
      }
    }

    String soql =
      'SELECT Id, FirstName, LastName, Name, Email, MobilePhone, Company, ' +
      'Referral__c, Referral_Account__c, CreatedDate, Description, Booking_Status__c ' +
      'FROM Lead ' +
      'WHERE IsConverted = FALSE ' +
      // Bergheimer site leads share the Lead object but are not Evoxise leads.
      'AND RecordType.DeveloperName != \'Bergheimer\' ' +
      'AND Status NOT IN (\'Processed\', \'Unqualified\') ' +
      // Snoozed/discarded leads are hidden. The scheduled flow
      // SFSCH_Churn_Unsnooze_Lead un-checks this box once
      // Churn_Snooze_Until__c passes, so no date test is needed here.
      'AND Churn_Do_Not_Show__c = FALSE ' +
      (noBranch ? 'AND Home_Branch__c = NULL' : 'AND Home_Branch__c = :branch');

    if (saMode == 'WITH' || saMode == 'POST') {
      soql += ' AND Id IN :paidLeadIds';
    } else if (saMode == 'WITHOUT') {
      soql += ' AND Id NOT IN :paidLeadIds';
    }

    if (hasTerm) {
      soql += ' AND Name LIKE :pattern';
    }
    if (hasCursor) {
      soql +=
        ' AND (CreatedDate < :beforeCreated' +
        ' OR (CreatedDate = :beforeCreated AND Id < :beforeId))';
    }

    soql += ' ORDER BY CreatedDate DESC, Id DESC LIMIT :rowLimit';

    List<Lead> openLeads = Database.query(soql);

    // Trainer names for the page's picked SAs (WITH/POST only) — one query for
    // <= PAGE_SIZE ids.
    Map<Id, String> trainerBySa = new Map<Id, String>();
    if (saMode == 'WITH' || saMode == 'POST') {
      Set<Id> pageSaIds = new Set<Id>();
      for (Lead l : openLeads) {
        ServiceAppointment sa = pickSaByLead.get(l.Id);
        if (sa != null) {
          pageSaIds.add(sa.Id);
        }
      }
      trainerBySa = trainerNamesForSas(pageSaIds);
    }

    for (Lead l : openLeads) {
      LeadDTO d = toDto(l, 'open');
      if (saMode == 'WITH' || saMode == 'POST') {
        ServiceAppointment sa = pickSaByLead.get(l.Id);
        if (sa != null) {
          d.trainingDate = sa.SchedStartTime;
          d.trainerName = trainerBySa.get(sa.Id);
        }
      }
      out.add(d);
    }
    Boolean hasMore = openLeads.size() == rowLimit;

    // POST also surfaces Processed leads that were migrated to an Account
    // (matched by Email__c) which never had a ServiceAppointment nor attended
    // one. These slipped through without a training, so they still need
    // attention.
    if (saMode == 'POST') {
      ProcessedResult pr = processedMigratedNoAppt(
        noBranch,
        branch,
        hasTerm,
        pattern,
        rowLimit,
        hasCursor,
        beforeCreated,
        beforeId
      );
      out.addAll(pr.dtos);
      // Merge of two sublists -> re-sort globally, trim to one page.
      out.sort();
      if (out.size() > rowLimit) {
        hasMore = true;
        while (out.size() > rowLimit) {
          out.remove(out.size() - 1);
        }
      }
      hasMore = hasMore || pr.rawFull;
    }

    result.leads = out;
    result.hasMore = hasMore;
    return result;
  }

  // Leads in Processed status whose migrated Account (Account.Email__c =
  // Lead.Email) has no ServiceAppointment (SA.AccountId = Account.Id) and is
  // not an attendee of one (custom junction or standard attendee object).
  // Visible rows are then hydrated with the trainer/date from the lead's old
  // pre-migration Lead-parented Paid SA.
  private static ProcessedResult processedMigratedNoAppt(
    Boolean noBranch,
    String branch,
    Boolean hasTerm,
    String pattern,
    Integer rowLimit,
    Boolean hasCursor,
    Datetime beforeCreated,
    Id beforeId
  ) {
    ProcessedResult res = new ProcessedResult();

    String leadSoql =
      'SELECT Id, FirstName, LastName, Name, Email, MobilePhone, Company, ' +
      'Referral__c, Referral_Account__c, CreatedDate, Description, Booking_Status__c ' +
      'FROM Lead ' +
      'WHERE IsConverted = FALSE ' +
      'AND RecordType.DeveloperName != \'Bergheimer\' ' +
      'AND Status = \'Processed\' ' +
      // Same Lead-level hide as the main query above. Note this is stricter
      // than the Account-side churnHidden rule below, which hides only
      // permanent discards (no snooze date) — that asymmetry is intentional.
      'AND Churn_Do_Not_Show__c = FALSE ' +
      (noBranch
        ? 'AND Home_Branch__c = NULL '
        : 'AND Home_Branch__c = :branch ') +
      'AND Email != NULL';
    if (hasTerm) {
      leadSoql += ' AND Name LIKE :pattern';
    }
    if (hasCursor) {
      leadSoql +=
        ' AND (CreatedDate < :beforeCreated' +
        ' OR (CreatedDate = :beforeCreated AND Id < :beforeId))';
    }
    leadSoql += ' ORDER BY CreatedDate DESC, Id DESC LIMIT :rowLimit';

    List<Lead> processedLeads = Database.query(leadSoql);
    res.rawFull = processedLeads.size() == rowLimit;
    if (processedLeads.isEmpty()) {
      return res;
    }

    // Collect emails to resolve matching Accounts in one query.
    Set<String> emails = new Set<String>();
    for (Lead l : processedLeads) {
      if (String.isNotBlank(l.Email)) {
        emails.add(l.Email.toLowerCase());
      }
    }

    // email(lowercased) -> Account ids sharing that Email__c.
    Map<String, Set<Id>> acctIdsByEmail = new Map<String, Set<Id>>();
    Set<Id> allAcctIds = new Set<Id>();
    Set<Id> churnHidden = new Set<Id>();
    for (Account a : [
      SELECT Id, Email__c, Churn_Do_Not_Show__c, Churn_Snooze_Until__c
      FROM Account
      WHERE Email__c != NULL AND Email__c IN :emails
      LIMIT 50000
    ]) {
      String key = a.Email__c.toLowerCase();
      if (!acctIdsByEmail.containsKey(key)) {
        acctIdsByEmail.put(key, new Set<Id>());
      }
      acctIdsByEmail.get(key).add(a.Id);
      allAcctIds.add(a.Id);
      if (a.Churn_Do_Not_Show__c == true && a.Churn_Snooze_Until__c == null) {
        churnHidden.add(a.Id);
      }
    }
    if (allAcctIds.isEmpty()) {
      return res;
    }

    // Accounts that DO have at least one real ServiceAppointment (via AccountId).
    // Canceled appointments don't count — training never happened, so the lead
    // still needs attention.
    Set<Id> acctWithAppt = new Set<Id>();
    for (AggregateResult ar : [
      SELECT AccountId acctId
      FROM ServiceAppointment
      WHERE AccountId IN :allAcctIds AND Status != 'Canceled'
      GROUP BY AccountId
    ]) {
      acctWithAppt.add((Id) ar.get('acctId'));
    }

    // Accounts attending group trainings via the custom junction. Attendee
    // rows on canceled appointments don't count — training never happened.
    Set<Id> acctAttendee = new Set<Id>();
    for (Service_Appointment_Attendee__c att : [
      SELECT Account__c
      FROM Service_Appointment_Attendee__c
      WHERE
        Account__c IN :allAcctIds
        AND Service_Appointment__r.Status != 'Canceled'
      LIMIT 50000
    ]) {
      acctAttendee.add(att.Account__c);
    }

    // Standard attendee object links via Contact — map Contacts back to their
    // Accounts, then collect attendee rows on non-canceled appointments.
    Map<Id, Id> acctByContact = new Map<Id, Id>();
    for (Contact c : [
      SELECT Id, AccountId
      FROM Contact
      WHERE AccountId IN :allAcctIds
      LIMIT 50000
    ]) {
      acctByContact.put(c.Id, c.AccountId);
    }
    if (!acctByContact.isEmpty()) {
      for (ServiceAppointmentAttendee att : [
        SELECT AttendeeId
        FROM ServiceAppointmentAttendee
        WHERE
          AttendeeId IN :acctByContact.keySet()
          AND ServiceAppointment.Status != 'Canceled'
        LIMIT 50000
      ]) {
        Id acctId = acctByContact.get(att.AttendeeId);
        if (acctId != null) {
          acctAttendee.add(acctId);
        }
      }
    }

    for (Lead l : processedLeads) {
      Set<Id> acctIds = acctIdsByEmail.get(l.Email.toLowerCase());
      if (acctIds == null || acctIds.isEmpty()) {
        continue; // no matching migrated Account
      }
      // Drop when any matched Account has an appointment, attends one as an
      // attendee, or is churn-hidden (Churn_Do_Not_Show__c set, no snooze).
      Boolean anyBlocked = false;
      for (Id aId : acctIds) {
        if (
          acctWithAppt.contains(aId) ||
          acctAttendee.contains(aId) ||
          churnHidden.contains(aId)
        ) {
          anyBlocked = true;
          break;
        }
      }
      if (!anyBlocked) {
        res.dtos.add(toDto(l, 'processed'));
      }
    }

    // Trainer + date from each visible lead's OLD Lead-parented Paid SA
    // (booked before the lead was migrated). The matched Account has no SA —
    // that's why the row shows at all — but the pre-conversion training info
    // still helps the caller pick the right trainer.
    if (!res.dtos.isEmpty()) {
      Set<Id> visibleLeadIds = new Set<Id>();
      for (LeadDTO d : res.dtos) {
        visibleLeadIds.add((Id) d.id);
      }
      Map<Id, ServiceAppointment> oldSaByLead = new Map<Id, ServiceAppointment>();
      for (ServiceAppointment sa : [
        SELECT Id, ParentRecordId, SchedStartTime
        FROM ServiceAppointment
        WHERE ParentRecordId IN :visibleLeadIds AND Status = 'Paid'
        LIMIT 50000
      ]) {
        ServiceAppointment prev = oldSaByLead.get(sa.ParentRecordId);
        if (
          prev == null ||
          (sa.SchedStartTime != null &&
          (prev.SchedStartTime == null ||
          sa.SchedStartTime > prev.SchedStartTime))
        ) {
          oldSaByLead.put(sa.ParentRecordId, sa);
        }
      }
      if (!oldSaByLead.isEmpty()) {
        Set<Id> oldSaIds = new Set<Id>();
        for (ServiceAppointment sa : oldSaByLead.values()) {
          oldSaIds.add(sa.Id);
        }
        Map<Id, String> oldTrainerBySa = trainerNamesForSas(oldSaIds);
        for (LeadDTO d : res.dtos) {
          ServiceAppointment sa = oldSaByLead.get((Id) d.id);
          if (sa != null) {
            d.trainingDate = sa.SchedStartTime;
            d.trainerName = oldTrainerBySa.get(sa.Id);
          }
        }
      }
    }
    return res;
  }

  // Trainer display names for the given ServiceAppointments, resolved via
  // AssignedResource person ServiceResources. First person resource per SA
  // wins (stable across runs); group sessions with multiple trainers show the
  // earliest-assigned one.
  private static Map<Id, String> trainerNamesForSas(Set<Id> saIds) {
    Map<Id, String> bySa = new Map<Id, String>();
    if (saIds == null || saIds.isEmpty()) {
      return bySa;
    }
    for (AssignedResource ar : [
      SELECT ServiceAppointmentId, ServiceResource.Name
      FROM AssignedResource
      WHERE
        ServiceAppointmentId IN :saIds
        AND ServiceResource.IsPerson__c = TRUE
      ORDER BY CreatedDate, Id
    ]) {
      if (!bySa.containsKey(ar.ServiceAppointmentId)) {
        bySa.put(ar.ServiceAppointmentId, ar.ServiceResource.Name);
      }
    }
    return bySa;
  }

  private static LeadDTO toDto(Lead l, String kind) {
    LeadDTO d = new LeadDTO();
    d.id = l.Id;
    d.firstName = l.FirstName;
    d.lastName = l.LastName;
    d.fullName = l.Name;
    d.email = l.Email;
    d.mobilePhone = l.MobilePhone;
    d.referralId = l.Referral__c;
    d.referralAccountId = l.Referral_Account__c;
    d.createdDate = l.CreatedDate;
    d.note = l.Description;
    d.bookingStatus = l.Booking_Status__c;
    d.company = l.Company;
    d.hasAppointment = false;
    d.kind = kind;
    return d;
  }

  @AuraEnabled
  public static void saveLeadNote(Id leadId, String note) {
    if (leadId == null) {
      throw new AuraHandledException('Chýba Id leadu.');
    }
    update new Lead(Id = leadId, Description = note);
  }

  /**
   * Snoozes a lead so it drops out of the finder list until the given date.
   * Writes the shared churn fields; the scheduled flow SFSCH_Churn_Unsnooze_Lead
   * clears them once the date passes, which makes the lead visible again.
   */
  @AuraEnabled
  public static void snoozeLead(Id leadId, Date snoozeUntil, String reason) {
    if (leadId == null) {
      throw new AuraHandledException('Chýba Id leadu.');
    }
    // Apex Id accepts any sObject's Id, so a wrong-type Id can reach here from
    // a manipulated client call. Reject it up front: the Lead constructor below
    // would raise a TypeException, which is NOT a DmlException and would escape
    // the catch to the client as a raw English platform error.
    if (leadId.getSObjectType() != Lead.SObjectType) {
      throw new AuraHandledException('Záznam nie je lead.');
    }
    if (snoozeUntil == null) {
      throw new AuraHandledException('Dátum odloženia je povinný.');
    }
    if (snoozeUntil <= Date.today()) {
      throw new AuraHandledException('Dátum musí byť v budúcnosti.');
    }
    if (String.isBlank(reason)) {
      throw new AuraHandledException('Dôvod je povinný.');
    }
    // Churn_Reason__c is Text(255). Client-side maxlength is bypassable, and an
    // over-length value would surface as a raw English DB error echoing the
    // user's own input. Reject rather than truncate — silently discarding the
    // caller's text is worse than asking them to shorten it.
    String cleanReason = reason.trim();
    if (cleanReason.length() > 255) {
      throw new AuraHandledException('Dôvod je príliš dlhý (max. 255 znakov).');
    }
    try {
      update new Lead(
        Id = leadId,
        Churn_Do_Not_Show__c = true,
        Churn_Snooze_Until__c = snoozeUntil,
        Churn_Reason__c = cleanReason
      );
    } catch (DmlException e) {
      throw new AuraHandledException('Uloženie zlyhalo: ' + e.getDmlMessage(0));
    }
  }
}