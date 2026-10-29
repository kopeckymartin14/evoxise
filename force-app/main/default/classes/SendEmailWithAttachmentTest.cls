// Project:     SchedulerDEV — Group Training Board
// Developer:   Juraj Kopecky
// Reviewer:    -
// Date:        2026-10-16
// Story/Task:  SFSCH-group-training-board (registration follow-up, Task 6b)
// Description: Tests for the bulk-safe SendEmailWithAttachment, incl. two-request order and per-index errors.
// Date:        2026-10-29
// Story/Task:  evoxise-booking-ics
// Description: Calendar invite and logging on a record.
/**
 * SendEmailWithAttachment Test class
 */
@isTest
private class SendEmailWithAttachmentTest {
  /**
   * Normal
   */
  @isTest
  private static void test_normal01() {
    SendEmailWithAttachment.Request req = new SendEmailWithAttachment.Request();
    req.toAddresses = new List<String>{ 'test01@testsfdc.com' };
    req.ccAddresses = new List<String>{ 'test02@testsfdc.com' };
    req.subject = 'Invoice';
    req.plainTextBody = 'Please find the attached invoice.';
    req.bccSender = true;
    req.useSignature = true;
    req.saveAsActivity = true;

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(true, results[0].isSuccess);
  }

  /**
   * Normal
   * Using Email template
   */
  @isTest
  private static void test_normal02() {
    SendEmailWithAttachment.Request req = new SendEmailWithAttachment.Request();
    req.toAddresses = new List<String>{ 'test01@testsfdc.com' };
    req.ccAddresses = new List<String>{ 'test02@testsfdc.com' };
    req.templateId = createEmailTemplate().Id;
    req.targetObjectId = UserInfo.getUserId();
    req.saveAsActivity = false;
    req.treatTargetObjectAsRecipient = true;

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(true, results[0].isSuccess);
  }

  /**
   * Normal
   * Using OrgWideEmailAddress
   */
  @isTest
  private static void test_normal03() {
    SendEmailWithAttachment.Request req = new SendEmailWithAttachment.Request();
    req.toAddresses = new List<String>{ 'test01@testsfdc.com' };
    req.subject = 'Invoice';
    req.plainTextBody = 'Please find the attached invoice.';
    //get orgWideEmailAddress
    Boolean isSuccess;
    List<OrgWideEmailAddress> orgList = [
      SELECT Id
      FROM OrgWideEmailAddress
      LIMIT 1
    ];
    if (orgList.size() == 1) {
      req.orgWideEmailAddressId = orgList[0].Id;
      isSuccess = true;
    } else {
      req.orgWideEmailAddressId = '0D2000000000000000';
      isSuccess = false;
    }

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(isSuccess, results[0].isSuccess);
  }

  /**
   * Error
   * Email address formatting error
   */
  @isTest
  private static void test_error01() {
    SendEmailWithAttachment.Request req = new SendEmailWithAttachment.Request();
    req.toAddresses = new List<String>{ 'test01testsfdccom' };
    req.subject = 'Invoice';
    req.plainTextBody = 'Please find the attached invoice.';

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ req }
    );
    Test.stopTest();

    System.assertEquals(false, results[0].isSuccess);
  }

  /**
   * Bulk (SFSCH group-training-registration Task 6b, 2026-10-16)
   * Flow bulkifies the action across interviews: N requests must return
   * N results in request order, sent with a single Messaging.sendEmail call.
   */
  @isTest
  private static void test_bulk01_twoRequestsTwoResults() {
    SendEmailWithAttachment.Request plainReq = new SendEmailWithAttachment.Request();
    plainReq.toAddresses = new List<String>{ 'bulk-a@testsfdc.com' };
    plainReq.subject = 'Registration';
    plainReq.plainTextBody = 'You are registered.';
    // no activity: EmailMessage insert after the EmailTemplate insert is mixed DML (test-only)
    plainReq.saveAsActivity = false;

    SendEmailWithAttachment.Request templateReq = new SendEmailWithAttachment.Request();
    templateReq.toAddresses = new List<String>{ 'bulk-b@testsfdc.com' };
    templateReq.templateId = createEmailTemplate().Id;
    templateReq.targetObjectId = UserInfo.getUserId();
    templateReq.saveAsActivity = false;
    templateReq.treatTargetObjectAsRecipient = true;

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ plainReq, templateReq }
    );
    Integer emailInvocations = Limits.getEmailInvocations();
    Test.stopTest();

    Assert.areEqual(2, results.size(), 'One result per request');
    Assert.isTrue(
      results[0].isSuccess,
      'Plain request should succeed: ' + results[0].errorMessage
    );
    Assert.isTrue(
      results[1].isSuccess,
      'Template request should succeed: ' + results[1].errorMessage
    );
    Assert.areEqual(
      1,
      emailInvocations,
      'All requests should be sent with one sendEmail call'
    );
  }

  /**
   * Bulk: a failing request maps to its own result and does not block the
   * others (allOrNone=false), results keep request order.
   */
  @isTest
  private static void test_bulk02_failureMapsToItsOwnIndex() {
    SendEmailWithAttachment.Request badReq = new SendEmailWithAttachment.Request();
    badReq.toAddresses = new List<String>{ 'bulk-badtestsfdccom' };
    badReq.subject = 'Bad';
    badReq.plainTextBody = 'Invalid address.';

    SendEmailWithAttachment.Request goodReq = new SendEmailWithAttachment.Request();
    goodReq.toAddresses = new List<String>{ 'bulk-good@testsfdc.com' };
    goodReq.subject = 'Good';
    goodReq.plainTextBody = 'Valid address.';

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ badReq, goodReq }
    );
    Test.stopTest();

    Assert.areEqual(2, results.size(), 'One result per request');
    Assert.isFalse(results[0].isSuccess, 'Invalid address should fail');
    Assert.isFalse(
      String.isBlank(results[0].errorMessage),
      'Failed result should carry the error message'
    );
    Assert.isTrue(results[1].isSuccess, 'Valid request should still succeed');
    Assert.isNull(
      results[1].errorMessage,
      'Successful result should have no error message'
    );
  }

  private static ServiceAppointment bookedAppointment() {
    OperatingHours hours = new OperatingHours(Name = 'ICS Hours', TimeZone = 'Europe/Bratislava');
    insert hours;
    ServiceTerritory studio = new ServiceTerritory(Name = 'Pezinok', IsActive = true, OperatingHoursId = hours.Id);
    insert studio;
    Account client = new Account(Name = 'ICS Klient');
    insert client;
    Datetime start = Datetime.now().addDays(2);
    ServiceAppointment sa = new ServiceAppointment(
      ParentRecordId = client.Id,
      ServiceTerritoryId = studio.Id,
      Subject = 'ARX tréning',
      SchedStartTime = start,
      SchedEndTime = start.addMinutes(30),
      EarliestStartTime = start,
      DueDate = start.addMinutes(30)
    );
    insert sa;
    return [SELECT Id, AccountId FROM ServiceAppointment WHERE Id = :sa.Id];
  }

  private static SendEmailWithAttachment.Request bookingMail(ServiceAppointment sa, String method) {
    SendEmailWithAttachment.Request req = new SendEmailWithAttachment.Request();
    req.toAddresses = new List<String>{ 'klient@example.com' };
    req.subject = 'Rezervácia potvrdená';
    req.htmlBody = '<p>Termín</p><p>Team Evoxise</p>';
    req.calendarAppointmentId = sa.Id;
    req.calendarMethod = method;
    req.logRelatedToId = sa.AccountId;
    return req;
  }

  @isTest
  private static void sendEmail_requestInvite_logsOnAccount() {
    ServiceAppointment sa = bookedAppointment();

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ bookingMail(sa, 'Request') }
    );
    Integer invocations = Limits.getEmailInvocations();
    Test.stopTest();

    Assert.isTrue(results[0].isSuccess, 'Sent: ' + results[0].errorMessage);
    Assert.areEqual(1, invocations, 'One sendEmail call');
    EmailMessage logged = [SELECT HtmlBody, Subject, ToAddress FROM EmailMessage WHERE RelatedToId = :sa.AccountId];
    Assert.areEqual('Rezervácia potvrdená', logged.Subject, 'Logged subject');
    Assert.areEqual('klient@example.com', logged.ToAddress, 'Logged recipient');
    Assert.areEqual('<p>Termín</p><p>Team Evoxise</p>', logged.HtmlBody, 'Body as given, no calendar links');
  }

  @isTest
  private static void sendEmail_cancelInvite_logsOnAccount() {
    ServiceAppointment sa = bookedAppointment();

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ bookingMail(sa, 'Cancel') }
    );
    Test.stopTest();

    Assert.isTrue(results[0].isSuccess, 'Sent: ' + results[0].errorMessage);
    EmailMessage logged = [SELECT HtmlBody FROM EmailMessage WHERE RelatedToId = :sa.AccountId];
    Assert.areEqual('<p>Termín</p><p>Team Evoxise</p>', logged.HtmlBody, 'Body as given');
  }

  @isTest
  private static void sendEmail_noInvite_withoutLogTarget_logsNothing() {
    ServiceAppointment sa = bookedAppointment();
    SendEmailWithAttachment.Request req = bookingMail(sa, null);
    req.logRelatedToId = null;

    Test.startTest();
    List<SendEmailWithAttachment.Result> results = SendEmailWithAttachment.sendEmail(
      new List<SendEmailWithAttachment.Request>{ req }
    );
    Test.stopTest();

    Assert.isTrue(results[0].isSuccess, 'Sent: ' + results[0].errorMessage);
    Assert.areEqual(0, [SELECT COUNT() FROM EmailMessage WHERE RelatedToId = :sa.AccountId], 'Nothing logged');
  }

  /**
   * Create EmailTemplate
   */
  private static EmailTemplate createEmailTemplate() {
    EmailTemplate e = new EmailTemplate(
      Name = 'test',
      DeveloperName = 'test',
      FolderId = UserInfo.getUserId(),
      TemplateType = 'Text',
      Subject = 'Invoice',
      Body = 'Please find the attached invoice.',
      IsActive = true
    );

    insert e;
    return e;
  }
}