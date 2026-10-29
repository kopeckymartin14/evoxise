@isTest
public class SchedulerCMPControllerTest {
  @testSetup
  static void setupTestData() {
    // Create Profile
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    // Create Users
    User testUser1 = new User(
      Alias = 'usr1',
      Email = 'user1schedJKO@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User1',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'user1schedJKO@testorg.com'
    );
    User testUser2 = new User(
      Alias = 'usr2',
      Email = 'user2schedJKO@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User2',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'user2schedJKO@testorg.com'
    );
    insert new List<User>{ testUser1, testUser2 };

    // Create OperatingHours
    OperatingHours operatingHours = new OperatingHours(
      Name = 'Test Operating Hours'
    );
    insert operatingHours;

    // Create ServiceTerritory
    ServiceTerritory territory = new ServiceTerritory(
      Name = 'Test Territory',
      OperatingHoursId = operatingHours.Id,
      IsActive = true
    );
    insert territory;

    // Create TimeSlots for all days of the week
    List<TimeSlot> timeSlots = new List<TimeSlot>{
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Monday'
      ),
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Tuesday'
      ),
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Wednesday'
      ),
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Thursday'
      ),
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Friday'
      ),
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Saturday'
      ),
      new TimeSlot(
        OperatingHoursId = operatingHours.Id,
        StartTime = Time.newInstance(8, 0, 0, 0),
        EndTime = Time.newInstance(17, 0, 0, 0),
        DayOfWeek = 'Sunday'
      )
    };
    insert timeSlots;

    // Create ServiceResources
    ServiceResource resource1 = new ServiceResource(
      Name = 'Resource 1',
      RelatedRecordId = testUser1.Id,
      IsActive = true
    );
    ServiceResource resource2 = new ServiceResource(
      Name = 'Resource 2',
      RelatedRecordId = testUser2.Id,
      IsActive = true
    );
    insert new List<ServiceResource>{ resource1, resource2 };

    // Create ServiceTerritoryMembers. Membership starts yesterday so the
    // "now - 1h" Shift below is valid even when the test runs just after
    // midnight (2026-09-04 fix: FIELD_INTEGRITY_EXCEPTION at 00:40).
    ServiceTerritoryMember member1 = new ServiceTerritoryMember(
      ServiceTerritoryId = territory.Id,
      ServiceResourceId = resource1.Id,
      EffectiveStartDate = Date.today().addDays(-1)
    );
    ServiceTerritoryMember member2 = new ServiceTerritoryMember(
      ServiceTerritoryId = territory.Id,
      ServiceResourceId = resource2.Id,
      EffectiveStartDate = Date.today().addDays(-1)
    );
    insert new List<ServiceTerritoryMember>{ member1, member2 };

    // Create ResourceAbsences
    ResourceAbsence absence1 = new ResourceAbsence(
      ResourceId = resource1.Id,
      Start = DateTime.now().addDays(-1),
      End = DateTime.now().addDays(1)
    );
    insert absence1;

    // Create Shifts
    Shift shift1 = new Shift(
      ServiceResourceId = resource1.Id,
      ServiceTerritoryId = territory.Id,
      StartTime = DateTime.now().addHours(-1),
      EndTime = DateTime.now().addHours(8),
      Status = 'Confirmed'
    );
    insert shift1;

    // Create Account for ParentRecordId (and, below, for the machine's Asset)
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    // SFSCH-slot-board-booking: a third resource guaranteed to yield white
    // (free) boxes. resource1's ResourceAbsence (now-1d..now+1d) fully
    // swallows its Shift, and resource2 has no Shift at all, so neither ever
    // produces a bookable slot. A machine ServiceResource needs an AssetId
    // (RelatedRecordId is User-only — see TimeSlotHandlerTest.cls), and its
    // Shift is scheduled entirely tomorrow with no absence/appointment
    // overlapping it, inside the 08:00-17:00 operating hours.
    Asset machineAsset = new Asset(
      Name = 'Test Machine Asset',
      AccountId = testAccount.Id
    );
    insert machineAsset;

    ServiceResource machineResource = new ServiceResource(
      Name = 'Machine 1',
      ResourceType = 'S',
      IsActive = true,
      IsPerson__c = false,
      AssetId = machineAsset.Id
    );
    insert machineResource;

    ServiceTerritoryMember machineMember = new ServiceTerritoryMember(
      ServiceTerritoryId = territory.Id,
      ServiceResourceId = machineResource.Id,
      EffectiveStartDate = Date.today().addDays(-1)
    );
    insert machineMember;

    Date tomorrow = Date.today().addDays(1);
    Shift machineShift = new Shift(
      ServiceResourceId = machineResource.Id,
      ServiceTerritoryId = territory.Id,
      StartTime = Datetime.newInstance(tomorrow, Time.newInstance(8, 0, 0, 0)),
      EndTime = Datetime.newInstance(tomorrow, Time.newInstance(17, 0, 0, 0)),
      Status = 'Confirmed'
    );
    insert machineShift;

    // Create ServiceAppointments
    ServiceAppointment appointment1 = new ServiceAppointment(
      ServiceTerritoryId = territory.Id,
      SchedStartTime = DateTime.now().addHours(1),
      SchedEndTime = DateTime.now().addHours(2),
      Status = 'Paid',
      ParentRecordId = testAccount.Id
    );
    insert appointment1;

    // Create AssignedResources
    AssignedResource assignedResource1 = new AssignedResource(
      ServiceAppointmentId = appointment1.Id,
      ServiceResourceId = resource1.Id
    );
    insert assignedResource1;
  }

  @isTest
  static void testSchedulerDataWithServiceTerritoryId() {
    // Fetch the test ServiceTerritory
    ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];

    // Call the method
    Test.startTest();
    List<SchedulerWrapData.parentWrap> result = SchedulerCMPController.schedulerData(
      territory.Id,
      null
    );
    Test.stopTest();

    // Assertions
    System.assertNotEquals(null, result);
    System.assert(result.size() > 0, 'Result should not be empty');

    // Add more assertions for other days if needed
    // Example:
    for (SchedulerWrapData.parentWrap day : result) {
      System.assertNotEquals(null, day.dayName);
      System.assertNotEquals(null, day.dayDate);
      System.assertNotEquals(null, day.startTime);
      System.assertNotEquals(null, day.endTime);
      System.assert(
        day.workingHours.size() > 0,
        'Working hours should not be empty'
      );
      System.assert(day.mainData.size() > 0, 'Main data should not be empty');
    }

    Website_Settings__c setting = SchedulerCMPController.getWebsiteSettings();
    List<ServiceAppointment> appoitnments = SchedulerCMPController.getMultiTrainings();
  }

  // Project:     SchedulerDEV
  // Developer:   Claude
  // Reviewer:    Juraj Kopecky
  // Date:        2026-09-03
  // Story/Task:  SFSCH-slot-board-booking
  // Description: Cover the slot-board additions to SchedulerWrapData
  //              (Box.startIso / Box.resId / Box.isFree, parentWrap.territoryId).

  @isTest
  static void testBoxCarriesSlotMetadataForBoard() {
    ServiceTerritory territory = [
      SELECT Id, Name
      FROM ServiceTerritory
      LIMIT 1
    ];

    Test.startTest();
    List<SchedulerWrapData.parentWrap> result = SchedulerCMPController.schedulerData(
      territory.Id,
      null
    );
    Test.stopTest();

    System.assert(!result.isEmpty(), 'Expected at least one day');

    Integer boxesChecked = 0;
    Integer freeBoxes = 0;
    for (SchedulerWrapData.parentWrap day : result) {
      // parentWrap must carry the territory id so the LWC can pass it to the flow.
      System.assertEquals(
        territory.Id,
        day.territoryId,
        'parentWrap.territoryId must be the queried territory'
      );

      // dayDate is dd-MM-yyyy; startIso must start with the same day in yyyy-MM-dd.
      String d = day.dayDate; // e.g. 03-09-2026
      String expectedDatePrefix =
        d.substring(6, 10) +
        '-' +
        d.substring(3, 5) +
        '-' +
        d.substring(0, 2);

      Integer startHour = day.startTime.hour();

      for (SchedulerWrapData.mainDataWrap res : day.mainData) {
        for (
          Integer hourIdx = 0; hourIdx < res.scheduledTimes.size(); hourIdx++
        ) {
          SchedulerWrapData.mainDataChild cell = res.scheduledTimes[hourIdx];
          for (Integer q = 0; q < cell.boxes2.size(); q++) {
            SchedulerWrapData.Box box = cell.boxes2[q];

            System.assertNotEquals(
              null,
              box.startIso,
              'Every box must carry startIso'
            );
            System.assert(
              box.startIso.startsWith(expectedDatePrefix),
              'startIso ' +
                box.startIso +
                ' must fall on the box day ' +
                expectedDatePrefix
            );

            // 15-minute increments: quarter index q -> minutes q*15, hour = startHour + hourIdx.
            String expectedTime =
              String.valueOf(startHour + hourIdx).leftPad(2, '0') +
              ':' +
              String.valueOf(q * 15).leftPad(2, '0') +
              ':00';
            System.assert(
              box.startIso.contains('T' + expectedTime),
              'startIso ' +
                box.startIso +
                ' must be the ' +
                expectedTime +
                ' quarter box'
            );

            System.assertEquals(
              res.resId,
              box.resId,
              'box.resId must mirror the row resource id'
            );

            System.assertEquals(
              box.box == 'white',
              box.isFree,
              'isFree must be true only for white boxes (box=' + box.box + ')'
            );
            if (box.isFree) {
              freeBoxes++;
              System.assertEquals('white', box.box, 'isFree must imply white');
              System.assertNotEquals(
                null,
                box.startIso,
                'free slot must carry startIso'
              );
            }
            boxesChecked++;
          }
        }
      }
    }
    System.assert(boxesChecked > 0, 'Expected boxes to be produced');
    // SFSCH-slot-board-booking: machineResource's Shift runs tomorrow
    // 08:00-17:00 with no absence/appointment overlapping it, so it is
    // guaranteed to yield 'white' (bookable) boxes. This proves isFree is
    // actually wired to real free slots, not just vacuously true when no box
    // is ever free.
    System.assert(
      freeBoxes > 0,
      'Fixture must yield at least one bookable white box'
    );
  }

  // SFSCH-slot-board-booking (2026-09-04): a red machine box produced by a
  // "Machine Usage" absence must carry the linked ServiceAppointment id so the
  // board can open the modify flow; an unlinked absence stays red with no id.
  @isTest
  static void testRedMachineBoxCarriesAppointmentId() {
    ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
    ServiceResource machine = [
      SELECT Id
      FROM ServiceResource
      WHERE Name = 'Machine 1'
      LIMIT 1
    ];
    ServiceAppointment appt = [SELECT Id FROM ServiceAppointment LIMIT 1];
    Date tomorrow = Date.today().addDays(1);

    insert new List<ResourceAbsence>{
      new ResourceAbsence(
        ResourceId = machine.Id,
        Type = 'Machine Usage',
        Start = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0)),
        End = Datetime.newInstance(tomorrow, Time.newInstance(10, 30, 0, 0)),
        Service_Appointment__c = appt.Id
      ),
      new ResourceAbsence(
        ResourceId = machine.Id,
        Type = 'Machine Usage',
        Start = Datetime.newInstance(tomorrow, Time.newInstance(12, 0, 0, 0)),
        End = Datetime.newInstance(tomorrow, Time.newInstance(12, 30, 0, 0))
      )
    };

    Test.startTest();
    List<SchedulerWrapData.parentWrap> result = SchedulerCMPController.schedulerData(
      territory.Id,
      null
    );
    Test.stopTest();

    String tomorrowKey = Datetime.newInstance(
        tomorrow,
        Time.newInstance(0, 0, 0, 0)
      )
      .format('dd-MM-yyyy');
    Integer linkedRed = 0;
    Integer unlinkedRed = 0;
    for (SchedulerWrapData.parentWrap day : result) {
      if (day.dayDate != tomorrowKey) {
        continue;
      }
      for (SchedulerWrapData.mainDataWrap res : day.mainData) {
        if (res.resId != String.valueOf(machine.Id)) {
          continue;
        }
        for (SchedulerWrapData.mainDataChild cell : res.scheduledTimes) {
          for (SchedulerWrapData.Box box : cell.boxes2) {
            if (box.box != 'red') {
              System.assertEquals(
                null,
                box.appointmentId,
                'Only red boxes may carry appointmentId (' + box.startIso + ')'
              );
              continue;
            }
            System.assertEquals(false, box.isFree, 'red box is not free');
            if (box.startIso.contains('T10:')) {
              System.assertEquals(
                String.valueOf(appt.Id),
                box.appointmentId,
                'Linked Machine Usage absence must expose the appointment id'
              );
              linkedRed++;
            } else if (box.startIso.contains('T12:')) {
              System.assertEquals(
                null,
                box.appointmentId,
                'Unlinked Machine Usage absence must not expose an id'
              );
              unlinkedRed++;
            }
          }
        }
      }
    }
    System.assertEquals(2, linkedRed, 'two 15-min boxes at 10:00 and 10:15');
    System.assertEquals(2, unlinkedRed, 'two 15-min boxes at 12:00 and 12:15');
  }

  @isTest
  static void testTerritoryIdSetWhenAllTerritoriesRequested() {
    Test.startTest();
    List<SchedulerWrapData.parentWrap> result = SchedulerCMPController.schedulerData(
      null,
      null
    );
    Test.stopTest();

    System.assert(!result.isEmpty(), 'Expected days for the active territory');
    for (SchedulerWrapData.parentWrap day : result) {
      System.assertNotEquals(
        null,
        day.territoryId,
        'territoryId must be populated even in the all-territories path'
      );
      System.assertNotEquals(
        null,
        day.territoryName,
        'territoryName must still be populated'
      );
    }
  }
}