// Project:     SchedulerDEV (Evoxise)
// Developer:   Juraj Kopecky
// Reviewer:    -
// Date:        2026-10-29
// Story/Task:  evoxise-booking-ics
// Description: Calendar invite (.ics) for booking e-mails,
//              so a training the client booked shows up in their calendar.
/**
 * Builds the iCalendar invite for a ServiceAppointment.
 *
 * One appointment is one calendar event: UID = the appointment Id, so a later
 * Request (new time) updates the event and a Cancel removes it. SEQUENCE grows with
 * LastModifiedDate, which every reschedule or cancellation changes. Times are UTC,
 * so no VTIMEZONE block is needed and summer / winter time cannot shift the event.
 *
 * `without sharing`: booking e-mails are sent by system-mode flows from the guest
 * site; the appointment Id comes from the flow, never from the visitor.
 */
public without sharing class AppointmentIcs {
  public static final String REQUEST = 'Request';
  public static final String CANCEL = 'Cancel';
  public static final String FILE_NAME = 'evoxise-trening.ics';

  private static final String CRLF = '\r\n';
  private static final String UID_DOMAIN = '@evoxise.sk';
  private static final String TITLE_PREFIX = 'Evoxise – ';
  private static final String DESCRIPTION = 'Rezervácia tréningu v Evoxise. Zmenu alebo zrušenie nájdeš v klientskej zóne: https://www.evoxise.sk';
  private static final Datetime SEQUENCE_EPOCH = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
  private static final Integer FOLD_OCTETS = 74;

  /**
   * @param appointmentIds ServiceAppointment Ids
   * @return appointments with a scheduled start and end, by Id
   */
  public static Map<Id, ServiceAppointment> appointments(Set<Id> appointmentIds) {
    if (appointmentIds == null || appointmentIds.isEmpty()) {
      return new Map<Id, ServiceAppointment>();
    }
    return new Map<Id, ServiceAppointment>(
      [
        SELECT
          Id,
          Subject,
          SchedStartTime,
          SchedEndTime,
          LastModifiedDate,
          Street,
          PostalCode,
          City,
          ServiceTerritory.Name,
          ServiceTerritory.Street,
          ServiceTerritory.PostalCode,
          ServiceTerritory.City
        FROM ServiceAppointment
        WHERE Id IN :appointmentIds AND SchedStartTime != NULL AND SchedEndTime != NULL
      ]
    );
  }

  /**
   * @param method REQUEST or CANCEL (case-insensitive)
   * @return true when the value asks for an invite
   */
  public static Boolean isMethod(String method) {
    return REQUEST.equalsIgnoreCase(method) || CANCEL.equalsIgnoreCase(method);
  }

  /**
   * @param sa appointment from appointments()
   * @param method REQUEST or CANCEL
   * @param organizerEmail sender address (the org-wide address)
   * @param attendeeEmails recipients of the e-mail
   * @return the .ics file content
   */
  public static String build(
    ServiceAppointment sa,
    String method,
    String organizerEmail,
    List<String> attendeeEmails
  ) {
    Boolean cancel = CANCEL.equalsIgnoreCase(method);
    // A cancellation of one group attendee leaves the appointment unchanged: +1 keeps it newer.
    Long sequence = (sa.LastModifiedDate.getTime() - SEQUENCE_EPOCH.getTime()) / 1000 + (cancel ? 1 : 0);
    List<String> lines = new List<String>{
      'BEGIN:VCALENDAR',
      'PRODID:-//Evoxise//Rezervacie//SK',
      'VERSION:2.0',
      'CALSCALE:GREGORIAN',
      'METHOD:' + (cancel ? 'CANCEL' : 'REQUEST'),
      'BEGIN:VEVENT',
      'UID:' + sa.Id + UID_DOMAIN,
      'SEQUENCE:' + sequence,
      'DTSTAMP:' + utc(Datetime.now()),
      'DTSTART:' + utc(sa.SchedStartTime),
      'DTEND:' + utc(sa.SchedEndTime),
      'SUMMARY:' + escape(title(sa)),
      'LOCATION:' + escape(location(sa)),
      'DESCRIPTION:' + escape(DESCRIPTION),
      'STATUS:' + (cancel ? 'CANCELLED' : 'CONFIRMED'),
      'TRANSP:OPAQUE'
    };
    if (String.isNotBlank(organizerEmail)) {
      lines.add('ORGANIZER;CN=Evoxise:mailto:' + organizerEmail);
    }
    for (String email : attendeeEmails == null ? new List<String>() : attendeeEmails) {
      if (String.isNotBlank(email)) {
        // The client booked it: already accepted, no reply expected
        lines.add('ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=FALSE:mailto:' + email.trim());
      }
    }
    if (!cancel) {
      lines.addAll(new List<String>{ 'BEGIN:VALARM', 'ACTION:DISPLAY', 'DESCRIPTION:' + escape(title(sa)), 'TRIGGER:-PT2H', 'END:VALARM' });
    }
    lines.addAll(new List<String>{ 'END:VEVENT', 'END:VCALENDAR' });

    List<String> folded = new List<String>();
    for (String line : lines) {
      folded.add(fold(line));
    }
    return String.join(folded, CRLF) + CRLF;
  }

  /**
   * @param sa appointment from appointments()
   * @param method REQUEST or CANCEL
   * @param organizerEmail sender address
   * @param attendeeEmails recipients
   * @return the .ics file as an e-mail attachment
   */
  public static Messaging.EmailFileAttachment attachment(
    ServiceAppointment sa,
    String method,
    String organizerEmail,
    List<String> attendeeEmails
  ) {
    Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
    file.setFileName(FILE_NAME);
    file.setContentType(
      'text/calendar; charset=UTF-8; method=' + (CANCEL.equalsIgnoreCase(method) ? 'CANCEL' : 'REQUEST')
    );
    file.setBody(Blob.valueOf(build(sa, method, organizerEmail, attendeeEmails)));
    return file;
  }

  private static String title(ServiceAppointment sa) {
    return TITLE_PREFIX + (String.isBlank(sa.Subject) ? 'tréning' : sa.Subject);
  }

  // The appointment's own address (events such as Spartan), else the studio's, else its name
  @TestVisible
  private static String location(ServiceAppointment sa) {
    String own = address(sa.Street, sa.PostalCode, sa.City);
    if (String.isNotBlank(own)) {
      return own;
    }
    ServiceTerritory territory = sa.ServiceTerritory;
    if (territory == null) {
      return '';
    }
    String studio = address(territory.Street, territory.PostalCode, territory.City);
    return String.isNotBlank(studio) ? 'Evoxise ' + territory.Name + ', ' + studio : 'Evoxise ' + territory.Name;
  }

  private static String address(String street, String postalCode, String city) {
    String town = String.join(nonBlank(new List<String>{ postalCode, city }), ' ');
    return String.join(nonBlank(new List<String>{ street, town }), ', ');
  }

  private static List<String> nonBlank(List<String> values) {
    List<String> kept = new List<String>();
    for (String value : values) {
      if (String.isNotBlank(value)) {
        kept.add(value.trim());
      }
    }
    return kept;
  }

  private static String utc(Datetime value) {
    return value.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
  }

  // RFC 5545 3.3.11 TEXT escaping
  @TestVisible
  private static String escape(String value) {
    return (value == null ? '' : value)
      .replace('\\', '\\\\')
      .replace(';', '\\;')
      .replace(',', '\\,')
      .replace('\r\n', '\\n')
      .replace('\n', '\\n');
  }

  // RFC 5545 3.1: lines longer than 75 octets continue on the next line after CRLF + space,
  // never splitting a multi-byte character
  @TestVisible
  private static String fold(String line) {
    if (Blob.valueOf(line).size() <= FOLD_OCTETS) {
      return line;
    }
    List<String> parts = new List<String>();
    String current = '';
    Integer octets = 0;
    Integer i = 0;
    while (i < line.length()) {
      // whole code points, so an emoji (surrogate pair) is never split
      Integer width = line.codePointAt(i) > 65535 ? 2 : 1;
      String ch = line.substring(i, i + width);
      i += width;
      Integer size = Blob.valueOf(ch).size();
      if (octets + size > FOLD_OCTETS) {
        parts.add(current);
        current = ' ';
        octets = 1;
      }
      current += ch;
      octets += size;
    }
    parts.add(current);
    return String.join(parts, CRLF);
  }
}