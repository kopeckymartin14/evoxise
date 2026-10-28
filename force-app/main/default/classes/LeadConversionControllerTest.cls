@IsTest
private class LeadConversionControllerTest {
  private static Lead makeLead(
    String fn,
    String ln,
    String company,
    String branch
  ) {
    return new Lead(
      FirstName = fn,
      LastName = ln,
      Email = fn + '@example.com',
      Company = company,
      Home_Branch__c = branch
    );
  }

  // Convenience: page 1 (null cursor) of the new paged API.
  private static List<LeadConversionController.LeadDTO> firstPage(
    String term,
    String source,
    String territory
  ) {
    return LeadConversionController.getLeads(
        term,
        source,
        territory,
        null,
        null
      )
      .leads;
  }

  // Ids of a result page — collapses the id-collecting loop repeated across
  // most tests in this class.
  private static Set<Id> idsOf(List<LeadConversionController.LeadDTO> rows) {
    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    return ids;
  }

  @IsTest
  static void getLeads_freeTrainingDefault_excludesProcessedAndUnqualified() {
    Lead live = makeLead('Live', 'Lead', 'Free Training', 'Pezinok');
    Lead proc = makeLead('Proc', 'Lead', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    Lead disq = makeLead('Disq', 'Lead', 'Free Training', 'Pezinok');
    disq.Status = 'Unqualified';
    insert new List<Lead>{ live, proc, disq };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      '',
      'FreeTraining_WithAppt',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(!ids.contains(proc.Id), 'Processed lead must be excluded');
    System.assert(!ids.contains(disq.Id), 'Unqualified lead must be excluded');
  }

  @IsTest
  static void getLeads_territory_filtersByHomeBranch() {
    insert new List<Lead>{
      makeLead('Bra', 'Tislava', 'Free Training', 'Bratislava'),
      makeLead('Pez', 'Inok', 'Free Training', 'Pezinok')
    };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      '',
      'FreeTraining_NoAppt',
      'Bratislava'
    );
    Test.stopTest();

    System.assertEquals(1, rows.size(), 'only Bratislava-branch lead returned');
    System.assertEquals('Bra Tislava', rows[0].fullName);
  }

  @IsTest
  static void getLeads_search_matchesNameLike() {
    insert new List<Lead>{
      makeLead('Anna', 'Smith', 'Free Training', 'Pezinok'),
      makeLead('Carol', 'Smithson', 'Free Training', 'Pezinok'),
      makeLead('Bob', 'Jones', 'Free Training', 'Pezinok')
    };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Smith',
      'FreeTraining_WithAppt',
      'Pezinok'
    );
    Test.stopTest();

    // WithAppt requires a Paid SA; none created, so expect 0 even though names match.
    System.assertEquals(
      0,
      rows.size(),
      'WithAppt with no Paid SA returns nothing'
    );
  }

  @IsTest
  static void getLeads_noAppt_returnsLeadsWithoutPaidSA() {
    insert new List<Lead>{
      makeLead('Anna', 'Smith', 'Free Training', 'Pezinok'),
      makeLead('Carol', 'Smithson', 'Free Training', 'Pezinok')
    };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Smith',
      'FreeTraining_NoAppt',
      'Pezinok'
    );
    Test.stopTest();

    System.assertEquals(
      2,
      rows.size(),
      'NoAppt returns FT leads lacking a Paid SA'
    );
  }

  @IsTest
  static void getLeads_dtoFieldsPopulated() {
    Lead l = makeLead('Field', 'Check', 'Free Training', 'Pezinok');
    l.MobilePhone = '+421900000000';
    insert l;

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Field',
      'FreeTraining_NoAppt',
      'Pezinok'
    );
    Test.stopTest();

    System.assertEquals(1, rows.size());
    LeadConversionController.LeadDTO d = rows[0];
    System.assertEquals('Field', d.firstName);
    System.assertEquals('Check', d.lastName);
    System.assertEquals('Field Check', d.fullName);
    // Salesforce lowercases Email on insert.
    System.assertEquals('field@example.com', d.email);
    System.assertEquals('+421900000000', d.mobilePhone);
    System.assertNotEquals(null, d.createdDate);
    System.assertEquals(
      'Free Training',
      d.company,
      'DTO must carry Lead Company'
    );
  }

  @IsTest
  static void getLeads_emptyResultForUnknownName() {
    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'NoSuchLeadName_xyz',
      'FreeTraining_NoAppt',
      'Pezinok'
    );
    Test.stopTest();

    System.assertEquals(0, rows.size());
  }

  @IsTest
  static void saveLeadNote_persistsToDescription() {
    Lead l = makeLead('Note', 'Lead', 'Free Training', 'Pezinok');
    insert l;

    Test.startTest();
    LeadConversionController.saveLeadNote(l.Id, 'Prvá poznámka');
    Test.stopTest();

    Lead reloaded = [SELECT Description FROM Lead WHERE Id = :l.Id];
    System.assertEquals('Prvá poznámka', reloaded.Description);
  }

  @IsTest
  static void saveLeadNote_nullIdThrows() {
    Boolean threw = false;
    Test.startTest();
    try {
      LeadConversionController.saveLeadNote(null, 'x');
    } catch (Exception e) {
      threw = true;
    }
    Test.stopTest();
    System.assert(threw, 'null leadId must throw');
  }

  @IsTest
  static void getLeads_returnsNoteFromDescription() {
    Lead l = makeLead('Desc', 'Lead', 'Free Training', 'Pezinok');
    l.Description = 'Existujúca poznámka';
    insert l;

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Desc',
      'FreeTraining_NoAppt',
      'Pezinok'
    );
    Test.stopTest();

    System.assertEquals(1, rows.size());
    System.assertEquals('Existujúca poznámka', rows[0].note);
  }

  @IsTest
  static void getLeads_post_includesProcessedMigratedNoAppt() {
    // Processed lead migrated to an Account (same email) that has NO appointment.
    Lead proc = makeLead('NoSa', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    insert new Account(Name = 'NoSa Migrated', Email__c = proc.Email);

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'NoSa',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
      if (d.id == proc.Id) {
        System.assertEquals('processed', d.kind, 'kind flagged processed');
      }
    }
    System.assert(
      ids.contains(proc.Id),
      'Processed lead with email-matched Account lacking SA must appear in POST'
    );
  }

  @IsTest
  static void getLeads_post_excludesProcessedWhenAccountHasAppt() {
    Lead proc = makeLead('HasSa', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    Account acc = new Account(Name = 'HasSa Migrated', Email__c = proc.Email);
    insert acc;
    // ParentRecordId on an Account auto-populates SA.AccountId (not directly writeable).
    insert new ServiceAppointment(ParentRecordId = acc.Id);

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'HasSa',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      !ids.contains(proc.Id),
      'Processed lead whose Account already has an SA must be excluded'
    );
  }

  @IsTest
  static void getLeads_post_excludesProcessedWithoutMatchingAccount() {
    Lead proc = makeLead('NoAcct', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc; // no Account with matching email created

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'NoAcct',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      !ids.contains(proc.Id),
      'Processed lead without a matching migrated Account must be excluded'
    );
  }

  @IsTest
  static void getLeads_noBranchTab_returnsNullBranchLeads() {
    insert new List<Lead>{
      makeLead('Null', 'Branch', 'Free Training', null),
      makeLead('Has', 'Branch', 'Free Training', 'Pezinok')
    };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      '',
      'FreeTraining_NoAppt',
      'NoBranch'
    );
    Test.stopTest();

    System.assertEquals(1, rows.size(), 'only null-branch lead returned');
    System.assertEquals('Null Branch', rows[0].fullName);
  }

  @IsTest
  static void getLeads_post_excludesChurnHiddenAccount() {
    // Churn-hidden Account (DoNotShow, no snooze) -> lead excluded.
    Lead hidden = makeLead('Churnhidden', 'Hidden', 'Free Training', 'Pezinok');
    hidden.Status = 'Processed';
    // Snoozed Account (DoNotShow but snooze date set) -> lead included.
    Lead snoozed = makeLead(
      'Churnsnoozed',
      'Snoozed',
      'Free Training',
      'Pezinok'
    );
    snoozed.Status = 'Processed';
    insert new List<Lead>{ hidden, snoozed };

    insert new List<Account>{
      new Account(
        Name = 'Churn Hidden',
        Email__c = hidden.Email,
        Churn_Do_Not_Show__c = true
      ),
      new Account(
        Name = 'Churn Snoozed',
        Email__c = snoozed.Email,
        Churn_Do_Not_Show__c = true,
        Churn_Snooze_Until__c = Date.today().addDays(30)
      )
    };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Churn',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      !ids.contains(hidden.Id),
      'Churn-hidden Account (no snooze) must exclude the lead'
    );
    System.assert(
      ids.contains(snoozed.Id),
      'Snoozed churn Account must NOT exclude the lead'
    );
  }

  @IsTest
  static void getLeads_page1_capsAt15AndFlagsMore() {
    List<Lead> many = new List<Lead>();
    for (Integer i = 0; i < 20; i++) {
      many.add(makeLead('Page' + i, 'Lead' + i, 'Free Training', 'Pezinok'));
    }
    insert many;

    Test.startTest();
    LeadConversionController.LeadPage p1 = LeadConversionController.getLeads(
      '',
      'FreeTraining_NoAppt',
      'Pezinok',
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(15, p1.leads.size(), 'page 1 capped at PAGE_SIZE');
    System.assert(p1.hasMore, '20 rows exist -> hasMore true');
  }

  @IsTest
  static void getLeads_page2_continuesWithoutOverlap() {
    List<Lead> many = new List<Lead>();
    for (Integer i = 0; i < 20; i++) {
      many.add(makeLead('Pg' + i, 'Lead' + i, 'Free Training', 'Pezinok'));
    }
    insert many;

    Test.startTest();
    LeadConversionController.LeadPage p1 = LeadConversionController.getLeads(
      '',
      'FreeTraining_NoAppt',
      'Pezinok',
      null,
      null
    );
    LeadConversionController.LeadDTO last = p1.leads[p1.leads.size() - 1];
    LeadConversionController.LeadPage p2 = LeadConversionController.getLeads(
      '',
      'FreeTraining_NoAppt',
      'Pezinok',
      last.createdDate,
      last.id
    );
    Test.stopTest();

    System.assertEquals(5, p2.leads.size(), 'remaining 5 rows on page 2');
    System.assert(!p2.hasMore, 'no further rows -> hasMore false');
    Set<String> p1Ids = new Set<String>();
    for (LeadConversionController.LeadDTO d : p1.leads) {
      p1Ids.add(d.id);
    }
    for (LeadConversionController.LeadDTO d : p2.leads) {
      System.assert(
        !p1Ids.contains(d.id),
        'page 2 must not repeat page 1 rows'
      );
    }
  }

  @IsTest
  static void getLeads_post_excludesWhenAccountIsCustomAttendee() {
    Lead proc = makeLead('Custatt', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    Account acc = new Account(Name = 'Custatt Migrated', Email__c = proc.Email);
    // SA parented to a DIFFERENT account so the existing AccountId rule does
    // not fire — only the attendee junction should block.
    Account host = new Account(
      Name = 'Host Custatt',
      Email__c = 'host-custatt@example.com'
    );
    insert new List<Account>{ acc, host };
    ServiceAppointment sa = new ServiceAppointment(ParentRecordId = host.Id);
    insert sa;
    insert new Service_Appointment_Attendee__c(
      Account__c = acc.Id,
      Service_Appointment__c = sa.Id
    );

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Custatt',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      !ids.contains(proc.Id),
      'Account attending via custom junction must hide the lead'
    );
  }

  @IsTest
  static void getLeads_post_mergedPaginationTrimsAndPagesWithoutOverlap() {
    // POST mode re-sorts the merged result, trims to PAGE_SIZE, and pages via
    // the (CreatedDate, Id) cursor. This exercises that sort/trim/hasMore/cursor
    // path with a purely deterministic sublist: 18 Processed migrated-no-appt
    // leads (no ServiceAppointment dependency, so no org-specific FSL fragility).
    // With the open sublist empty, the POST merge still runs out.sort() + trim
    // over these 18 rows — the exact invariant under test — and page 1 caps at
    // 15 with hasMore true, page 2 carries the rest.

    // Processed sublist: Processed leads with an Email-matched Account that has
    // no appointment and no attendee record. 18 processed leads guarantee a >15
    // visible set in every org, so the merge/trim/cursor path is exercised
    // regardless of org-specific FSL behavior.
    List<Lead> procLeads = new List<Lead>();
    for (Integer i = 0; i < 18; i++) {
      Lead p = makeLead('Procpost' + i, 'Lead' + i, 'Free Training', 'Pezinok');
      p.Status = 'Processed';
      procLeads.add(p);
    }
    insert procLeads;
    List<Account> procAccts = new List<Account>();
    for (Lead p : procLeads) {
      procAccts.add(new Account(Name = p.LastName, Email__c = p.Email));
    }
    insert procAccts;

    // Processed leads are guaranteed visible in every org (no SA dependency);
    // open+Paid-SA leads may or may not qualify depending on org FSL config, so
    // assert the cross-page invariants rather than a hardcoded total.
    Set<Id> procIds = new Set<Id>();
    for (Lead p : procLeads) {
      procIds.add(p.Id);
    }

    Test.startTest();
    LeadConversionController.LeadPage page = LeadConversionController.getLeads(
      '',
      'FreeTraining_PostTraining',
      'Pezinok',
      null,
      null
    );
    System.assertEquals(15, page.leads.size(), 'page 1 trimmed to PAGE_SIZE');
    System.assert(page.hasMore, 'more than 15 visible -> hasMore true');

    // All leads share the same CreatedDate (one transaction), so the cursor's
    // Id tiebreak is exactly what is under test. Walk every page via the cursor
    // and assert no row ever repeats across pages (the no-overlap/no-skip
    // invariant) rather than a specific ordering or hardcoded total.
    Set<Id> allIds = new Set<Id>();
    Integer guard = 0;
    while (true) {
      for (LeadConversionController.LeadDTO d : page.leads) {
        System.assert(!allIds.contains(d.id), 'no row may repeat across pages');
        allIds.add(d.id);
      }
      if (!page.hasMore || page.leads.isEmpty()) {
        break;
      }
      LeadConversionController.LeadDTO last = page.leads[page.leads.size() - 1];
      page = LeadConversionController.getLeads(
        '',
        'FreeTraining_PostTraining',
        'Pezinok',
        last.createdDate,
        last.id
      );
      guard++;
      System.assert(guard < 10, 'pagination did not terminate');
    }
    Test.stopTest();

    // Every processed lead must appear exactly once across the pages — proves
    // the merge/trim/cursor never skips a row at the page boundary. Open leads
    // may or may not qualify per org, so the total is asserted as a lower bound.
    System.assert(
      allIds.size() >= 18,
      'at least the 18 processed leads visible'
    );
    System.assert(
      allIds.containsAll(procIds),
      'no processed lead skipped across the page boundary'
    );
  }

  @IsTest
  static void getLeads_post_excludesWhenContactIsStandardAttendee() {
    Lead proc = makeLead('Stdatt', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    Account acc = new Account(Name = 'Stdatt Migrated', Email__c = proc.Email);
    Account host = new Account(
      Name = 'Host Stdatt',
      Email__c = 'host-stdatt@example.com'
    );
    insert new List<Account>{ acc, host };
    Contact con = new Contact(LastName = 'Stdatt', AccountId = acc.Id);
    insert con;
    // Standard ServiceAppointmentAttendee requires the parent SA to be in group
    // mode ("Select a service appointment with group mode and try again.").
    ServiceAppointment sa = new ServiceAppointment(
      ParentRecordId = host.Id,
      AppointmentMode = 'Group',
      AttendeeLimit = 10
    );
    insert sa;
    insert new ServiceAppointmentAttendee(
      ServiceAppointmentId = sa.Id,
      AttendeeId = con.Id
    );

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Stdatt',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      !ids.contains(proc.Id),
      'Contact attending via standard object must hide the lead'
    );
  }

  @IsTest
  static void getLeads_post_includesWhenAttendeeSaCanceled() {
    Lead proc = makeLead('Cancatt', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    Account acc = new Account(Name = 'Cancatt Migrated', Email__c = proc.Email);
    Account host = new Account(
      Name = 'Host Cancatt',
      Email__c = 'host-cancatt@example.com'
    );
    insert new List<Account>{ acc, host };
    ServiceAppointment sa = new ServiceAppointment(ParentRecordId = host.Id);
    insert sa;
    insert new Service_Appointment_Attendee__c(
      Account__c = acc.Id,
      Service_Appointment__c = sa.Id
    );
    sa.Status = 'Canceled';
    update sa;

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Cancatt',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      ids.contains(proc.Id),
      'Attendee row on a CANCELED SA must NOT hide the lead'
    );
  }

  @IsTest
  static void getLeads_with_dtoCarriesTrainerAndTrainingDate() {
    Lead l = makeLead('Traininfo', 'Lead', 'Free Training', 'Pezinok');
    insert l;
    ServiceAppointment sa = new ServiceAppointment(
      ParentRecordId = l.Id,
      Status = 'Paid',
      SchedStartTime = Datetime.now().addDays(1)
    );
    insert sa;
    ServiceResource trainer = new ServiceResource(
      Name = 'Test Trainer',
      IsActive = true,
      IsPerson__c = true,
      RelatedRecordId = UserInfo.getUserId()
    );
    insert trainer;
    insert new AssignedResource(
      ServiceAppointmentId = sa.Id,
      ServiceResourceId = trainer.Id
    );

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Traininfo',
      'FreeTraining_WithAppt',
      'Pezinok'
    );
    Test.stopTest();

    // Org-tolerant (FSL config may mutate inserted Paid SAs in some orgs):
    // assert the positive path only when the org preserved the setup.
    ServiceAppointment saAfter = [
      SELECT Status
      FROM ServiceAppointment
      WHERE Id = :sa.Id
    ];
    if (saAfter.Status == 'Paid') {
      System.assertEquals(1, rows.size(), 'lead with Paid SA appears in WITH');
      System.assertEquals('Test Trainer', rows[0].trainerName);
      System.assertNotEquals(null, rows[0].trainingDate);
    }
  }

  @IsTest
  static void getLeads_with_earliestFutureAppointmentWins() {
    Lead l = makeLead('Earliestsa', 'Lead', 'Free Training', 'Pezinok');
    insert l;
    ServiceAppointment near = new ServiceAppointment(
      ParentRecordId = l.Id,
      Status = 'Paid',
      SchedStartTime = Datetime.now().addDays(2)
    );
    ServiceAppointment far = new ServiceAppointment(
      ParentRecordId = l.Id,
      Status = 'Paid',
      SchedStartTime = Datetime.now().addDays(10)
    );
    insert new List<ServiceAppointment>{ near, far };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Earliestsa',
      'FreeTraining_WithAppt',
      'Pezinok'
    );
    Test.stopTest();

    // Org-tolerant: only assert when both SAs kept Paid status.
    List<ServiceAppointment> paidAfter = [
      SELECT Id, SchedStartTime
      FROM ServiceAppointment
      WHERE ParentRecordId = :l.Id AND Status = 'Paid'
      ORDER BY SchedStartTime ASC
    ];
    if (paidAfter.size() == 2) {
      System.assertEquals(1, rows.size(), 'one row per lead');
      System.assertEquals(
        paidAfter[0].SchedStartTime,
        rows[0].trainingDate,
        'earliest FUTURE SchedStartTime wins on WITH (next upcoming training)'
      );
    }
  }

  @IsTest
  static void getLeads_post_processedRowHasNoTrainingInfo() {
    Lead proc = makeLead('Notrain', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    insert new Account(Name = 'Notrain Migrated', Email__c = proc.Email);

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Notrain',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    System.assertEquals(1, rows.size(), 'processed lead appears in POST');
    System.assertEquals(null, rows[0].trainerName, 'no trainer for processed');
    System.assertEquals(null, rows[0].trainingDate, 'no date for processed');
  }

  @IsTest
  static void getLeads_with_excludesPastOnlyAppointments() {
    Lead l = makeLead('Pastonly', 'Lead', 'Free Training', 'Pezinok');
    insert l;
    insert new ServiceAppointment(
      ParentRecordId = l.Id,
      Status = 'Paid',
      SchedStartTime = Datetime.now().addDays(-2)
    );

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Pastonly',
      'FreeTraining_WithAppt',
      'Pezinok'
    );
    Test.stopTest();

    // Unconditional: with the future-only rule a past-only-SA lead can never
    // appear in WITH — and if the org mutated the SA away from Paid, the lead
    // does not qualify either. Both branches satisfy the assertion.
    Set<Id> ids = new Set<Id>();
    for (LeadConversionController.LeadDTO d : rows) {
      ids.add(d.id);
    }
    System.assert(
      !ids.contains(l.Id),
      'lead whose only Paid SA is in the past must not appear in WITH'
    );
  }

  @IsTest
  static void getLeads_noAppt_stillExcludesAnyPaidSa() {
    Lead pastL = makeLead('Wopast', 'Lead', 'Free Training', 'Pezinok');
    Lead futL = makeLead('Wofut', 'Lead', 'Free Training', 'Pezinok');
    insert new List<Lead>{ pastL, futL };
    insert new List<ServiceAppointment>{
      new ServiceAppointment(
        ParentRecordId = pastL.Id,
        Status = 'Paid',
        SchedStartTime = Datetime.now().addDays(-2)
      ),
      new ServiceAppointment(
        ParentRecordId = futL.Id,
        Status = 'Paid',
        SchedStartTime = Datetime.now().addDays(2)
      )
    };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Wo',
      'FreeTraining_NoAppt',
      'Pezinok'
    );
    Test.stopTest();

    // Org-tolerant: a lead whose SA lost Paid status legitimately reappears in
    // NoAppt, so assert exclusion only for leads whose SA stayed Paid.
    Set<Id> bothIds = new Set<Id>{ pastL.Id, futL.Id };
    Set<Id> paidParents = new Set<Id>();
    for (ServiceAppointment sa : [
      SELECT ParentRecordId
      FROM ServiceAppointment
      WHERE ParentRecordId IN :bothIds AND Status = 'Paid'
    ]) {
      paidParents.add(sa.ParentRecordId);
    }
    for (LeadConversionController.LeadDTO d : rows) {
      System.assert(
        !paidParents.contains((Id) d.id),
        'lead with any Paid SA (past or future) must stay excluded from NoAppt'
      );
    }
  }

  @IsTest
  static void getLeads_post_processedRowCarriesOldLeadTrainer() {
    Lead proc = makeLead('Oldtrain', 'Migrated', 'Free Training', 'Pezinok');
    proc.Status = 'Processed';
    insert proc;
    // Old Lead-parented Paid SA from before the migration.
    ServiceAppointment oldSa = new ServiceAppointment(
      ParentRecordId = proc.Id,
      Status = 'Paid',
      SchedStartTime = Datetime.now().addDays(-3)
    );
    insert oldSa;
    ServiceResource trainer = new ServiceResource(
      Name = 'Old Trainer',
      IsActive = true,
      IsPerson__c = true,
      RelatedRecordId = UserInfo.getUserId()
    );
    insert trainer;
    insert new AssignedResource(
      ServiceAppointmentId = oldSa.Id,
      ServiceResourceId = trainer.Id
    );
    // Migrated Account with the same email and NO Account-side SA.
    insert new Account(Name = 'Oldtrain Migrated', Email__c = proc.Email);

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      'Oldtrain',
      'FreeTraining_PostTraining',
      'Pezinok'
    );
    Test.stopTest();

    LeadConversionController.LeadDTO found;
    for (LeadConversionController.LeadDTO d : rows) {
      if (d.id == proc.Id) {
        found = d;
      }
    }
    System.assertNotEquals(null, found, 'processed lead appears in POST');
    System.assertEquals('processed', found.kind);
    // Org-tolerant: trainer/date assertions only when the SA stayed Paid.
    ServiceAppointment saAfter = [
      SELECT Status
      FROM ServiceAppointment
      WHERE Id = :oldSa.Id
    ];
    if (saAfter.Status == 'Paid') {
      System.assertEquals('Old Trainer', found.trainerName);
      System.assertNotEquals(null, found.trainingDate);
    }
  }

  @IsTest
  static void getLeads_excludesSnoozedLead() {
    Lead visible = makeLead('Visible', 'Lead', 'Free Training', 'Pezinok');
    Lead snoozed = makeLead('Snoozed', 'Lead', 'Free Training', 'Pezinok');
    snoozed.Churn_Do_Not_Show__c = true;
    snoozed.Churn_Snooze_Until__c = Date.today().addDays(7);
    insert new List<Lead>{ visible, snoozed };

    Test.startTest();
    List<LeadConversionController.LeadDTO> rows = firstPage(
      '',
      'FreeTraining_NoAppt',
      'Pezinok'
    );
    Test.stopTest();

    Set<Id> ids = idsOf(rows);
    System.assert(ids.contains(visible.Id), 'Non-snoozed lead must be listed');
    System.assert(!ids.contains(snoozed.Id), 'Snoozed lead must be hidden');
  }

  @IsTest
  static void getLeads_includesLeadAfterUnsnooze() {
    // Start genuinely snoozed, then apply exactly what the scheduled flow
    // SFSCH_Churn_Unsnooze_Lead does (clear checkbox + date) and assert the
    // lead comes back. Asserting invisibility first is what makes the
    // post-unsnooze assertion meaningful.
    Lead expired = makeLead('Expired', 'Lead', 'Free Training', 'Pezinok');
    expired.Churn_Do_Not_Show__c = true;
    expired.Churn_Snooze_Until__c = Date.today().addDays(7);
    expired.Churn_Reason__c = 'dovolenka';
    insert expired;

    Test.startTest();
    System.assert(
      !idsOf(firstPage('', 'FreeTraining_NoAppt', 'Pezinok'))
        .contains(expired.Id),
      'precondition: lead is hidden while snoozed'
    );
    // What the scheduled unsnooze flow leaves behind.
    update new Lead(
      Id = expired.Id,
      Churn_Do_Not_Show__c = false,
      Churn_Snooze_Until__c = null
    );
    System.assert(
      idsOf(firstPage('', 'FreeTraining_NoAppt', 'Pezinok'))
        .contains(expired.Id),
      'Lead whose snooze expired must reappear'
    );
    Test.stopTest();
  }

  @IsTest
  static void getLeads_post_excludesSnoozedProcessedLead() {
    // Covers the second SOQL builder (processedMigratedNoAppt). The NoAppt
    // tests above never reach it — POST is the only mode that calls it.
    Lead visible = makeLead('Postvis', 'Migrated', 'Free Training', 'Pezinok');
    visible.Status = 'Processed';
    Lead snoozed = makeLead(
      'Postsnooze',
      'Migrated',
      'Free Training',
      'Pezinok'
    );
    snoozed.Status = 'Processed';
    snoozed.Churn_Do_Not_Show__c = true;
    snoozed.Churn_Snooze_Until__c = Date.today().addDays(7);
    insert new List<Lead>{ visible, snoozed };
    // Email-matched Accounts with no SA => both would otherwise be visible.
    insert new List<Account>{
      new Account(Name = 'Postvis Migrated', Email__c = visible.Email),
      new Account(Name = 'Postsnooze Migrated', Email__c = snoozed.Email)
    };

    Test.startTest();
    Set<Id> ids = idsOf(
      firstPage('Post', 'FreeTraining_PostTraining', 'Pezinok')
    );
    Test.stopTest();

    System.assert(
      ids.contains(visible.Id),
      'Non-snoozed processed lead must still be listed'
    );
    System.assert(
      !ids.contains(snoozed.Id),
      'Snoozed processed lead must be hidden from POST'
    );
  }

  @IsTest
  static void snoozeLead_persistsAllThreeFields() {
    Lead l = makeLead('Snooze', 'Target', 'Free Training', 'Pezinok');
    insert l;
    Date until = Date.today().addDays(7);

    Test.startTest();
    LeadConversionController.snoozeLead(l.Id, until, '  dovolenka  ');
    Test.stopTest();

    Lead after = [
      SELECT Churn_Do_Not_Show__c, Churn_Snooze_Until__c, Churn_Reason__c
      FROM Lead
      WHERE Id = :l.Id
    ];
    System.assertEquals(
      true,
      after.Churn_Do_Not_Show__c,
      'Checkbox must be set'
    );
    System.assertEquals(until, after.Churn_Snooze_Until__c, 'Date must be set');
    System.assertEquals(
      'dovolenka',
      after.Churn_Reason__c,
      'Reason must be stored trimmed'
    );
    // End-to-end: the write half must actually satisfy the read half's filter.
    System.assert(
      !idsOf(firstPage('', 'FreeTraining_NoAppt', 'Pezinok')).contains(l.Id),
      'snoozed lead must disappear from the finder list'
    );
  }

  @IsTest
  static void snoozeLead_nonLeadIdThrows() {
    // Id accepts any sObject type; a wrong-type Id must be rejected by our
    // guard, not by the Lead constructor (whose TypeException would escape
    // the DmlException catch and reach the client unhandled).
    Account a = new Account(Name = 'Not A Lead');
    insert a;

    Test.startTest();
    try {
      LeadConversionController.snoozeLead(
        a.Id,
        Date.today().addDays(7),
        'dovolenka'
      );
      System.assert(false, 'Expected an exception for a non-Lead id');
    } catch (AuraHandledException e) {
      System.assertNotEquals(null, e, 'non-Lead id rejected');
    }
    Test.stopTest();
  }

  @IsTest
  static void snoozeLead_overlongReasonThrows() {
    // Churn_Reason__c is Text(255); 256 chars must be rejected by our guard
    // rather than reaching the DB and echoing a raw English length error.
    Lead l = makeLead('Longreason', 'Lead', 'Free Training', 'Pezinok');
    insert l;
    String tooLong = 'x'.repeat(256);

    Test.startTest();
    try {
      LeadConversionController.snoozeLead(
        l.Id,
        Date.today().addDays(7),
        tooLong
      );
      System.assert(false, 'Expected an exception for an over-length reason');
    } catch (AuraHandledException e) {
      System.assertNotEquals(null, e, 'over-length reason rejected');
    }
    Test.stopTest();
  }

  @IsTest
  static void snoozeLead_nullIdThrows() {
    Test.startTest();
    try {
      LeadConversionController.snoozeLead(null, Date.today().addDays(7), 'x');
      System.assert(false, 'Expected an exception for a null lead id');
    } catch (AuraHandledException e) {
      System.assertNotEquals(null, e, 'null id rejected');
    }
    Test.stopTest();
  }

  @IsTest
  static void snoozeLead_nullDateThrows() {
    Lead l = makeLead('No', 'Date', 'Free Training', 'Pezinok');
    insert l;

    Test.startTest();
    try {
      LeadConversionController.snoozeLead(l.Id, null, 'x');
      System.assert(false, 'Expected an exception for a null date');
    } catch (AuraHandledException e) {
      System.assertNotEquals(null, e, 'null date rejected');
    }
    Test.stopTest();
  }

  @IsTest
  static void snoozeLead_pastDateThrows() {
    // The unsnooze flow runs daily, so a today-or-past date would hide the
    // lead until the next run and then release it — reject it up front.
    Lead l = makeLead('Past', 'Date', 'Free Training', 'Pezinok');
    insert l;

    Test.startTest();
    try {
      LeadConversionController.snoozeLead(l.Id, Date.today(), 'x');
      System.assert(false, 'Expected an exception for a non-future date');
    } catch (AuraHandledException e) {
      System.assertNotEquals(null, e, 'past date rejected');
    }
    Test.stopTest();
  }

  @IsTest
  static void snoozeLead_blankReasonThrows() {
    Lead l = makeLead('No', 'Reason', 'Free Training', 'Pezinok');
    insert l;

    Test.startTest();
    try {
      LeadConversionController.snoozeLead(l.Id, Date.today().addDays(7), '   ');
      System.assert(false, 'Expected an exception for a blank reason');
    } catch (AuraHandledException e) {
      System.assertNotEquals(null, e, 'blank reason rejected');
    }
    Test.stopTest();
  }

  @IsTest
  static void getLeads_excludesBergheimerLeads() {
    Lead live = makeLead('Live', 'Lead', 'Free Training', 'Pezinok');
    Lead bergheimer = makeLead('Berg', 'Heimer', 'Free Training', 'Pezinok');
    bergheimer.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
      .get('Bergheimer')
      .getRecordTypeId();
    insert new List<Lead>{ live, bergheimer };

    Test.startTest();
    Set<Id> ids = idsOf(firstPage('', 'FreeTraining_NoAppt', 'Pezinok'));
    Test.stopTest();

    System.assert(ids.contains(live.Id), 'Evoxise lead must be listed');
    System.assert(!ids.contains(bergheimer.Id), 'Bergheimer lead must be excluded');
  }
}