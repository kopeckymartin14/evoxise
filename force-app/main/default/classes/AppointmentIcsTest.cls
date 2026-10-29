// Project:     SchedulerDEV (Evoxise)
// Developer:   Juraj Kopecky
// Reviewer:    -
// Date:        2026-10-29
// Story/Task:  evoxise-booking-ics
// Description: Tests for AppointmentIcs (invite content, cancel, location, folding).
@IsTest
private class AppointmentIcsTest {
  private static final Datetime START_UTC = Datetime.newInstanceGmt(2026, 11, 3, 16, 30, 0);
  private static final String ORGANIZER = 'evoxise@example.com';
  private static final String CLIENT = 'klient@example.com';

  @TestSetup
  static void setup() {
    OperatingHours hours = new OperatingHours(Name = 'ICS Hours', TimeZone = 'Europe/Bratislava');
    insert hours;
    ServiceTerritory studio = new ServiceTerritory(
      Name = 'Bratislava',
      IsActive = true,
      OperatingHoursId = hours.Id,
      Street = 'Stromová 54/A',
      PostalCode = '831 01',
      City = 'Bratislava'
    );
    insert studio;
    Account client = new Account(Name = 'ICS Klient');
    insert client;
    insert new ServiceAppointment(
      ParentRecordId = client.Id,
      ServiceTerritoryId = studio.Id,
      Subject = 'ARX tréning',
      SchedStartTime = START_UTC,
      SchedEndTime = START_UTC.addMinutes(30),
      EarliestStartTime = START_UTC,
      DueDate = START_UTC.addMinutes(30)
    );
  }

  private static ServiceAppointment appointment() {
    Id saId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
    return AppointmentIcs.appointments(new Set<Id>{ saId }).get(saId);
  }

  // Unfold RFC 5545 continuation lines so assertions see whole properties
  private static String unfolded(String ics) {
    return ics.replace('\r\n ', '');
  }

  @IsTest
  static void build_request_containsEvent() {
    ServiceAppointment sa = appointment();

    Test.startTest();
    String ics = AppointmentIcs.build(sa, 'Request', ORGANIZER, new List<String>{ CLIENT });
    Test.stopTest();

    String text = unfolded(ics);
    Assert.isTrue(text.startsWith('BEGIN:VCALENDAR\r\n'), 'Calendar header with CRLF');
    Assert.isTrue(text.contains('\r\nMETHOD:REQUEST\r\n'), 'Request method');
    Assert.isTrue(text.contains('\r\nUID:' + sa.Id + '@evoxise.sk\r\n'), 'UID is the appointment');
    Assert.isTrue(text.contains('\r\nDTSTART:20261103T163000Z\r\n'), 'Start in UTC');
    Assert.isTrue(text.contains('\r\nDTEND:20261103T170000Z\r\n'), 'End in UTC');
    Assert.isTrue(text.contains('\r\nSUMMARY:Evoxise – ARX tréning\r\n'), 'Title');
    Assert.isTrue(text.contains('\r\nLOCATION:Evoxise Bratislava\\, Stromová 54/A\\, 831 01 Bratislava\r\n'), 'Studio address, commas escaped');
    Assert.isTrue(text.contains('\r\nSTATUS:CONFIRMED\r\n'), 'Confirmed');
    Assert.isTrue(text.contains('\r\nORGANIZER;CN=Evoxise:mailto:' + ORGANIZER + '\r\n'), 'Organizer');
    Assert.isTrue(text.contains('PARTSTAT=ACCEPTED;RSVP=FALSE:mailto:' + CLIENT), 'Client accepted, no RSVP');
    Assert.isTrue(text.contains('\r\nBEGIN:VALARM\r\n'), 'Reminder on a request');
    Assert.isTrue(text.endsWith('END:VCALENDAR\r\n'), 'Calendar footer');
  }

  @IsTest
  static void build_cancel_cancelsSameEventWithHigherSequence() {
    ServiceAppointment sa = appointment();

    Test.startTest();
    String request = unfolded(AppointmentIcs.build(sa, 'Request', ORGANIZER, new List<String>{ CLIENT }));
    String cancel = unfolded(AppointmentIcs.build(sa, 'cancel', ORGANIZER, new List<String>{ CLIENT }));
    Test.stopTest();

    Assert.isTrue(cancel.contains('\r\nMETHOD:CANCEL\r\n'), 'Cancel method');
    Assert.isTrue(cancel.contains('\r\nSTATUS:CANCELLED\r\n'), 'Cancelled');
    Assert.isTrue(cancel.contains('\r\nUID:' + sa.Id + '@evoxise.sk\r\n'), 'Same UID as the request');
    Assert.isFalse(cancel.contains('VALARM'), 'No reminder on a cancellation');
    Assert.isTrue(sequenceOf(cancel) > sequenceOf(request), 'Cancel outranks the request');
  }

  private static Long sequenceOf(String ics) {
    return Long.valueOf(ics.substringAfter('\r\nSEQUENCE:').substringBefore('\r\n'));
  }

  @IsTest
  static void location_prefersAppointmentAddress() {
    ServiceAppointment sa = appointment();
    sa.Street = 'Hradná 1';
    sa.PostalCode = '945 01';
    sa.City = 'Komárno';

    Assert.areEqual('Hradná 1, 945 01 Komárno', AppointmentIcs.location(sa), 'Event address first');
  }

  @IsTest
  static void location_studioNameWithoutAddress() {
    ServiceAppointment sa = appointment();
    sa.ServiceTerritory.Street = null;
    sa.ServiceTerritory.PostalCode = null;
    sa.ServiceTerritory.City = null;

    Assert.areEqual('Evoxise Bratislava', AppointmentIcs.location(sa), 'Studio name only');
  }

  @IsTest
  static void fold_longLine_keepsLinesShortAndContent() {
    String line = 'DESCRIPTION:' + 'Žltý kôň úpel ďábelské ódy 😀 '.repeat(6);

    String folded = AppointmentIcs.fold(line);

    for (String part : folded.split('\r\n')) {
      Assert.isTrue(Blob.valueOf(part).size() <= 75, 'Folded line too long: ' + part);
    }
    Assert.areEqual(line, folded.replace('\r\n ', ''), 'Unfolding restores the line');
  }

  @IsTest
  static void escape_specialCharacters() {
    Assert.areEqual('a\\, b\\; c\\\\ d\\ne', AppointmentIcs.escape('a, b; c\\ d\ne'), 'RFC 5545 escaping');
  }

  @IsTest
  static void isMethod_onlyRequestOrCancel() {
    Assert.isTrue(AppointmentIcs.isMethod('REQUEST'), 'Request');
    Assert.isTrue(AppointmentIcs.isMethod('Cancel'), 'Cancel');
    Assert.isFalse(AppointmentIcs.isMethod(''), 'Blank');
    Assert.isFalse(AppointmentIcs.isMethod('Publish'), 'Other');
  }

  @IsTest
  static void appointments_emptyInput() {
    Assert.isTrue(AppointmentIcs.appointments(new Set<Id>()).isEmpty(), 'Nothing to query');
  }
}