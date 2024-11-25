@isTest
public class SchedulerCMPControllerTest {
    @testSetup
    static void setupTestData() {
        // Create Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        // Create Users
        User testUser1 = new User(Alias = 'usr1', Email='user1schedJKO@testorg.com', 
                                  EmailEncodingKey='UTF-8', LastName='User1', 
                                  LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                                  ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                                  UserName='user1schedJKO@testorg.com');
        User testUser2 = new User(Alias = 'usr2', Email='user2schedJKO@testorg.com', 
                                  EmailEncodingKey='UTF-8', LastName='User2', 
                                  LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                                  ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                                  UserName='user2schedJKO@testorg.com');
        insert new List<User>{testUser1, testUser2};

        // Create OperatingHours
        OperatingHours operatingHours = new OperatingHours(Name = 'Test Operating Hours');
        insert operatingHours;

        // Create ServiceTerritory
        ServiceTerritory territory = new ServiceTerritory(Name = 'Test Territory', OperatingHoursId = operatingHours.Id, IsActive = true);
        insert territory;

        // Create TimeSlots for all days of the week
        List<TimeSlot> timeSlots = new List<TimeSlot>{
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Monday'),
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Tuesday'),
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Wednesday'),
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Thursday'),
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Friday'),
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Saturday'),
            new TimeSlot(OperatingHoursId = operatingHours.Id, StartTime = Time.newInstance(8, 0, 0, 0), EndTime = Time.newInstance(17, 0, 0, 0), DayOfWeek = 'Sunday')
        };
        insert timeSlots;

        // Create ServiceResources
        ServiceResource resource1 = new ServiceResource(Name = 'Resource 1', RelatedRecordId = testUser1.Id, IsActive = true);
        ServiceResource resource2 = new ServiceResource(Name = 'Resource 2', RelatedRecordId = testUser2.Id, IsActive = true);
        insert new List<ServiceResource>{resource1, resource2};

        // Create ServiceTerritoryMembers
        ServiceTerritoryMember member1 = new ServiceTerritoryMember(ServiceTerritoryId = territory.Id, ServiceResourceId = resource1.Id, EffectiveStartDate = Date.today());
        ServiceTerritoryMember member2 = new ServiceTerritoryMember(ServiceTerritoryId = territory.Id, ServiceResourceId = resource2.Id, EffectiveStartDate = Date.today());
        insert new List<ServiceTerritoryMember>{member1, member2};

        // Create ResourceAbsences
        ResourceAbsence absence1 = new ResourceAbsence(ResourceId = resource1.Id, Start = DateTime.now().addDays(-1), End = DateTime.now().addDays(1));
        insert absence1;

        // Create Shifts
        Shift shift1 = new Shift(ServiceResourceId = resource1.Id, ServiceTerritoryId = territory.Id, StartTime = DateTime.now().addHours(-1), EndTime = DateTime.now().addHours(8), Status = 'Confirmed');
        insert shift1;

        // Create Account for ParentRecordId
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create ServiceAppointments
        ServiceAppointment appointment1 = new ServiceAppointment(ServiceTerritoryId = territory.Id, SchedStartTime = DateTime.now().addHours(1), SchedEndTime = DateTime.now().addHours(2), Status = 'Paid', ParentRecordId = testAccount.Id);
        insert appointment1;

        // Create AssignedResources
        AssignedResource assignedResource1 = new AssignedResource(ServiceAppointmentId = appointment1.Id, ServiceResourceId = resource1.Id);
        insert assignedResource1;
    }

    @isTest
    static void testSchedulerDataWithServiceTerritoryId() {
        // Fetch the test ServiceTerritory
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];

        // Call the method
        Test.startTest();
        List<SchedulerWrapData.parentWrap> result = SchedulerCMPController.schedulerData(territory.Id, null);
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
            System.assert(day.workingHours.size() > 0, 'Working hours should not be empty');
            System.assert(day.mainData.size() > 0, 'Main data should not be empty');
        }
    }

   
}