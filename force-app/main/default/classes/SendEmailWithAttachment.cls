// Project:     SchedulerDEV — Group Training Board
// Developer:   Juraj Kopecky
// Reviewer:    -
// Date:        2026-10-16
// Story/Task:  SFSCH-group-training-board (registration follow-up, Task 6b)
// Description: Bulk-safe invocable: one mail and one Result per request, one sendEmail call.
// Date:        2026-10-29
// Story/Task:  evoxise-booking-ics
// Description: Optional calendar invite (.ics, AppointmentIcs) for a ServiceAppointment, the
//              <!--CalendarLinks--> placeholder in htmlBody, and logging the sent mail on a record
//              (what emailSimple's logEmailOnSend did for the booking e-mails).
// Date:        2026-10-29
// Story/Task:  evoxise-booking-ics
// Description: "Pridať do kalendára" links removed: a link adds a copy of the event that the
//              update / cancel invite never reaches. The invite alone keeps the calendar in sync.
/**
 * Send Email with attachments
 */
public inherited sharing class SendEmailWithAttachment {
  /**
   * Request
   */
  public class Request {
    @InvocableVariable(label='To Addresses')
    public String[] toAddresses;
    @InvocableVariable(label='Cc Addresses')
    public String[] ccAddresses;
    @InvocableVariable(label='Bcc Addresses')
    public String[] bccAddresses;
    @InvocableVariable(label='Set email sender to Bcc *Default is false')
    public Boolean bccSender;
    @InvocableVariable(label='Organization-Wide Email Address Id')
    public String orgWideEmailAddressId;
    @InvocableVariable(
      label='Sender Name *Cannot be set if the orgWideEmailAddressId is set'
    )
    public String senderDisplayName;
    @InvocableVariable(label='Template Id')
    public String templateId;
    @InvocableVariable(label='Subject')
    public String subject;
    @InvocableVariable(label='Text Body')
    public String plainTextBody;
    @InvocableVariable(label='Html Body')
    public String htmlBody;
    @InvocableVariable(label='Use the sender email signature *Default is true')
    public Boolean useSignature;
    @InvocableVariable(
      label='File Ids *ContentVersionId, AttchmentId or DocumentId'
    )
    public String[] fileIds;
    @InvocableVariable(label='Related Record Id')
    public String whatId;
    @InvocableVariable(
      label='Target Object Id(Contact, Lead, User) *Required if template Id is set'
    )
    public String targetObjectId;
    @InvocableVariable(label='Set targetObjectId as recipient *Default is true')
    public Boolean treatTargetObjectAsRecipient;
    @InvocableVariable(
      label='Save As Activity *Save to targetObjectId and whatId records, default is true'
    )
    public Boolean saveAsActivity;
    @InvocableVariable(
      label='Calendar Appointment Id *ServiceAppointment for the .ics invite'
    )
    public String calendarAppointmentId;
    @InvocableVariable(
      label='Calendar Method *Request or Cancel, blank = no invite'
    )
    public String calendarMethod;
    @InvocableVariable(
      label='Log On Record Id *Saves the sent e-mail on this record (e.g. Account)'
    )
    public String logRelatedToId;
  }

  /**
   * Result
   */
  public class Result {
    @InvocableVariable(label='Send result *true=success、false=failure')
    public Boolean isSuccess;
    @InvocableVariable(label='Error message')
    public String errorMessage;
  }

  /**
   * Send Email
   * @description Send emails with attachments, one email per request. All
   * emails go out in one Messaging.sendEmail call (allOrNone=false) and each
   * request gets its own Result in request order, so Flow can bulkify the
   * action across interviews (SFSCH group-training-registration Task 6b,
   * 2026-10-16; before, only requests[0] was sent and one Result returned).
   * @param requests Email parameters
   * @return Result of sending each email, same order as requests
   */
  @InvocableMethod(label='Send Email (Send single email with attachments)')
  public static List<Result> sendEmail(List<Request> requests) {
    Set<Id> appointmentIds = new Set<Id>();
    Set<Id> senderIds = new Set<Id>();
    Set<Id> leadIds = new Set<Id>();
    for (Request req : requests) {
      if (wantsInvite(req)) {
        appointmentIds.add(req.calendarAppointmentId);
        if (isId(req.targetObjectId)) {
          leadIds.add(req.targetObjectId);
        }
      }
      if (!String.isBlank(req.orgWideEmailAddressId)) {
        senderIds.add(req.orgWideEmailAddressId);
      }
    }
    Map<Id, ServiceAppointment> appointments = AppointmentIcs.appointments(appointmentIds);
    Map<Id, OrgWideEmailAddress> senders = new Map<Id, OrgWideEmailAddress>(
      [SELECT Id, Address FROM OrgWideEmailAddress WHERE Id IN :senderIds]
    );
    // A Lead recipient (targetObjectId) is not in toAddresses but must be an invite attendee
    Map<Id, Lead> leads = new Map<Id, Lead>(
      [SELECT Id, Email FROM Lead WHERE Id IN :leadIds]
    );

    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    for (Request req : requests) {
      OrgWideEmailAddress sender = String.isBlank(req.orgWideEmailAddressId)
        ? null
        : senders.get(req.orgWideEmailAddressId);
      ServiceAppointment sa = wantsInvite(req)
        ? appointments.get(req.calendarAppointmentId)
        : null;
      String targetEmail = isId(req.targetObjectId) &&
        req.treatTargetObjectAsRecipient != false
        ? leads.get(req.targetObjectId)?.Email
        : null;
      mails.add(buildMail(req, sa, sender?.Address, targetEmail));
    }

    //Send email
    Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(mails, false);

    List<Result> results = new List<Result>();
    for (Messaging.SendEmailResult sendResult : sendResults) {
      Result result = new Result();
      result.isSuccess = sendResult.success;
      if (!result.isSuccess) {
        result.errorMessage = '';
        for (Messaging.SendEmailError error : sendResult.getErrors()) {
          result.errorMessage += error.getMessage() + ';';
        }
      }
      results.add(result);
    }
    logSentMails(requests, mails, results);
    return results;
  }

  private static Boolean wantsInvite(Request req) {
    return AppointmentIcs.isMethod(req.calendarMethod) &&
      isId(req.calendarAppointmentId);
  }

  // One EmailMessage per sent mail with logRelatedToId. A failed log never fails the
  // send: the mail is already out, so the error is only added to that Result.
  private static void logSentMails(
    List<Request> requests,
    List<Messaging.SingleEmailMessage> mails,
    List<Result> results
  ) {
    List<EmailMessage> logs = new List<EmailMessage>();
    List<Result> logged = new List<Result>();
    for (Integer i = 0; i < requests.size(); i++) {
      if (!results[i].isSuccess || !isId(requests[i].logRelatedToId)) {
        continue;
      }
      Messaging.SingleEmailMessage mail = mails[i];
      logs.add(
        new EmailMessage(
          RelatedToId = requests[i].logRelatedToId,
          Status = '3',
          Incoming = false,
          MessageDate = Datetime.now(),
          Subject = mail.getSubject(),
          HtmlBody = mail.getHtmlBody(),
          TextBody = mail.getPlainTextBody(),
          ToAddress = String.join(orEmpty(mail.getToAddresses()), '; '),
          BccAddress = String.join(orEmpty(mail.getBccAddresses()), '; ')
        )
      );
      logged.add(results[i]);
    }
    if (logs.isEmpty()) {
      return;
    }
    Database.SaveResult[] saved = Database.insert(logs, false);
    for (Integer i = 0; i < saved.size(); i++) {
      if (!saved[i].isSuccess()) {
        logged[i].errorMessage = 'Sent, not logged: ' + saved[i].getErrors()[0].getMessage();
      }
    }
  }

  private static Messaging.SingleEmailMessage buildMail(
    Request req,
    ServiceAppointment sa,
    String senderAddress,
    String targetEmail
  ) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    //Recipient
    mail.setToAddresses(req.toAddresses);
    mail.setCcAddresses(req.ccAddresses);
    mail.setBccAddresses(req.bccAddresses);
    if (req.bccSender != null) {
      mail.setBccSender(req.bccSender);
    }

    //Sender
    if (!String.isBlank(req.orgWideEmailAddressId)) {
      mail.setOrgWideEmailAddressId(req.orgWideEmailAddressId);
    } else {
      mail.setSenderDisplayName(req.senderDisplayName);
    }

    //Subject and body
    if (!String.isBlank(req.templateId)) {
      mail.setTemplateId(req.templateId);
    } else {
      mail.setSubject(req.subject);
      mail.setHtmlBody(req.htmlBody);
      mail.setPlainTextBody(req.plainTextBody);
    }

    //Use the sender email signature
    if (req.useSignature != null) {
      mail.setUseSignature(req.useSignature);
    }

    //Attachment
    mail.setEntityAttachments(req.fileIds);
    if (sa != null) {
      List<String> attendees = new List<String>();
      attendees.addAll(orEmpty(req.toAddresses));
      attendees.addAll(orEmpty(req.ccAddresses));
      if (String.isNotBlank(targetEmail)) {
        attendees.add(targetEmail);
      }
      mail.setFileAttachments(
        new List<Messaging.EmailFileAttachment>{
          AppointmentIcs.attachment(sa, req.calendarMethod, senderAddress, attendees)
        }
      );
    }

    //Related record Id
    mail.setWhatId(req.whatId);

    //Target object record Id (Contact, Lead, User)
    mail.setTargetObjectId(req.targetObjectId);

    //Set the target object Id (Contact, Lead, User) as the recipient
    if (req.treatTargetObjectAsRecipient != null) {
      mail.setTreatTargetObjectAsRecipient(req.treatTargetObjectAsRecipient);
    }

    //Save email to activity
    if (req.saveAsActivity != null) {
      mail.setSaveAsActivity(req.saveAsActivity);
    }

    return mail;
  }

  private static Boolean isId(String value) {
    if (String.isBlank(value)) {
      return false;
    }
    try {
      return Id.valueOf(value) != null;
    } catch (StringException e) {
      return false;
    }
  }

  private static List<String> orEmpty(List<String> values) {
    return values == null ? new List<String>() : values;
  }
}