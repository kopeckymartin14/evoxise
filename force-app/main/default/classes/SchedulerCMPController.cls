// Project:     SchedulerDEV
// Developer:   Claude
// Reviewer:    Juraj Kopecky
// Date:        2026-09-03
// Story/Task:  SFSCH-slot-board-booking
// Description: buildForTerritory now stamps parentWrap.territoryId and, per box,
//              startIso / resId / isFree for the timeTable slot board.
// Date:        2026-09-04
// Story/Task:  SFSCH-slot-board-booking (enhancements)
// Description: red boxes carry Box.appointmentId (Machine Usage absence ->
//              Service_Appointment__c, AssignedResource -> ServiceAppointmentId).
// Date:        2026-10-29
// Story/Task:  evoxise-zone-session
// Description: getTrainer accepts only a trainer token from today's login (as the zone flow does).
public without sharing class SchedulerCMPController {
  @AuraEnabled
  public static String getTrainer(String xToken) {
    List<ServiceResource> resources = [
      SELECT Id, Token__c
      FROM ServiceResource
      WHERE Token__c = :xToken AND Valid_Date_Login__c = TODAY
    ];
    return !resources.isEmpty() && resources.get(0).Token__c != null
      ? resources.get(0).Id
      : null;
  }

  @AuraEnabled
  public static List<SchedulerWrapData.parentWrap> schedulerData(
    Id serviceTeritoryId,
    Id trainerId
  ) {
    // When no territory is passed (e.g. home page), show ALL active territories
    // stacked together (each parentWrap tagged with its territoryName). When an
    // explicit territory is passed, show only that one.
    List<SchedulerWrapData.parentWrap> combined = new List<SchedulerWrapData.parentWrap>();
    if (serviceTeritoryId == null) {
      for (ServiceTerritory t : [
        SELECT Id
        FROM ServiceTerritory
        WHERE IsActive = TRUE
        ORDER BY Name
      ]) {
        combined.addAll(buildForTerritory(t.Id, trainerId));
      }
    } else {
      combined.addAll(buildForTerritory(serviceTeritoryId, trainerId));
    }
    return combined;
  }

  private static List<SchedulerWrapData.parentWrap> buildForTerritory(
    Id serviceTeritoryId,
    Id trainerId
  ) {
    ServiceTerritory territory = [
      SELECT Id, Name, OperatingHoursId
      FROM ServiceTerritory
      WHERE Id = :serviceTeritoryId
    ];

    List<TimeSlot> weekTimes = [
      SELECT Id, OperatingHoursId, StartTime, EndTime, DayOfWeek
      FROM TimeSlot
      WHERE OperatingHoursId = :territory.OperatingHoursId
    ];
    Map<String, TimeSlot> timeSlotMap = new Map<String, TimeSlot>();
    SchedulerWrapData.weekOperatinghours weekOperating = new SchedulerWrapData.weekOperatinghours();
    for (TimeSlot item : weekTimes) {
      if (item.DayOfWeek == 'Monday') {
        weekOperating.mondayStart = item.StartTime;
        weekOperating.mondayEnd = item.EndTime;
      } else if (item.DayOfWeek == 'Tuesday') {
        weekOperating.tuesdayStart = item.StartTime;
        weekOperating.tuesdayEnd = item.EndTime;
      } else if (item.DayOfWeek == 'Wednesday') {
        weekOperating.wednesdayStart = item.StartTime;
        weekOperating.wednesdayEnd = item.EndTime;
      } else if (item.DayOfWeek == 'Thursday') {
        weekOperating.thursdayStart = item.StartTime;
        weekOperating.thursdayEnd = item.EndTime;
      } else if (item.DayOfWeek == 'Friday') {
        weekOperating.fridayStart = item.StartTime;
        weekOperating.fridayEnd = item.EndTime;
      } else if (item.DayOfWeek == 'Saturday') {
        weekOperating.saturdayStart = item.StartTime;
        weekOperating.saturdayEnd = item.EndTime;
      } else if (item.DayOfWeek == 'Sunday') {
        weekOperating.sundayStart = item.StartTime;
        weekOperating.sundayEnd = item.EndTime;
      }
      timeSlotMap.put(item.DayOfWeek, item);
    }
    Date currentDate = Date.today();

    List<SchedulerWrapData.parentWrap> out = new List<SchedulerWrapData.parentWrap>();

    List<ServiceTerritoryMember> terMember = [
      SELECT Id, ServiceResourceId, ServiceTerritoryId
      FROM ServiceTerritoryMember
      WHERE ServiceTerritoryId = :territory.Id
    ];
    List<Id> resourceId = new List<Id>();
    for (ServiceTerritoryMember item : terMember) {
      resourceId.add(item.ServiceResourceId);
    }
    List<ServiceResource> resources = [
      SELECT Id, Name, IsPerson__c
      FROM ServiceResource
      WHERE Id IN :resourceId
      ORDER BY IsPerson__c DESC
    ];

    List<ResourceAbsence> absences = [
      SELECT Id, ResourceId, Start, End, Type, Service_Appointment__c
      FROM ResourceAbsence
      WHERE ResourceId IN :resourceId
    ];
    List<Shift> shifts = [
      SELECT Id, ServiceResourceId, StartTime, EndTime, Status
      FROM Shift
      WHERE
        ServiceResourceId IN :resourceId
        AND ServiceTerritoryId = :territory.Id
        AND Status = 'Confirmed'
        AND StartTime >= :currentDate
        AND EndTime <= NEXT_N_DAYS:14
      ORDER BY StartTime ASC
    ];

    Date todayDate = Date.today();
    // todayDate = todayDate.addDays(-20);
    DateTime startOfToday = DateTime.newInstance(
      todayDate.year(),
      todayDate.month(),
      todayDate.day()
    );
    System.debug('startOfToday: ' + startOfToday);
    List<ServiceAppointment> appointments = [
      SELECT Id, ServiceTerritoryId, SchedStartTime, SchedEndTime
      FROM ServiceAppointment
      WHERE
        ServiceTerritoryId = :territory.Id
        AND SchedStartTime >= :startOfToday
        AND (Status = 'Paid'
        OR Status = 'Unpaid')
    ];
    List<Id> appointmentIds = new List<Id>();

    for (ServiceAppointment item : appointments) {
      appointmentIds.add(item.Id);
      System.debug(item);
    }
    List<AssignedResource> assignResource = [
      SELECT
        Id,
        ServiceAppointmentId,
        ServiceAppointment.AppointmentNumber,
        ServiceAppointment.SchedStartTime,
        ServiceAppointment.SchedEndTime,
        ServiceAppointment.Account.Name,
        ServiceAppointment.Lead__r.Name,
        ServiceAppointment.Lead__r.MobilePhone,
        ServiceAppointment.Account.Phone,
        ServiceAppointment.Email,
        ServiceAppointment.ParentRecord.name,
        ServiceResourceId
      FROM AssignedResource
      WHERE
        ServiceResourceId IN :resourceId
        AND ServiceAppointmentId IN :appointmentIds
    ];

    Map<Id, List<ServiceAppointment>> resourceAppointmentsMap = new Map<Id, List<ServiceAppointment>>();
    Map<Id, List<AssignedResource>> assignedResourceMap = new Map<Id, List<AssignedResource>>();
    for (AssignedResource ar : assignResource) {
      // ServiceAppointment app = [SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Account.Name, Account.Phone, Email, ParentRecord.Name FROM ServiceAppointment WHERE Id = :ar.ServiceAppointmentId];
      if (!assignedResourceMap.containsKey(ar.ServiceResourceId)) {
        // if (!resourceAppointmentsMap.containsKey(ar.ServiceResourceId)) {
        // resourceAppointmentsMap.put(ar.ServiceResourceId, new List<ServiceAppointment>());
        assignedResourceMap.put(
          ar.ServiceResourceId,
          new List<AssignedResource>()
        );
      }
      // resourceAppointmentsMap.get(ar.ServiceResourceId).add(app);
      assignedResourceMap.get(ar.ServiceResourceId).add(ar);
    }

    Integer boxInteger = 1;
    for (Integer i = 0; i < 14; i++) {
      SchedulerWrapData.parentWrap rec = new SchedulerWrapData.parentWrap();
      currentDate = currentDate.addDays(+i);
      Datetime currentDatetime = datetime.newInstance(
        currentDate.year(),
        currentDate.month(),
        currentDate.day()
      );
      // Format Datetime to get the day name
      String dayName = currentDatetime.format('EEEE');
      if (timeSlotMap.containsKey(dayName)) {
        rec.territoryName = territory.Name;
        // SFSCH-slot-board-booking: the board needs the id, not just the name.
        rec.territoryId = territory.Id;
        rec.dayName = dayName;
        rec.dayDate = currentDatetime.format('dd-MM-yyyy');
        rec.startTime = timeSlotMap.get(dayName).StartTime;
        rec.endTime = timeSlotMap.get(dayName).EndTime;

        Integer startTimeInt = timeSlotMap.get(dayName).StartTime.hour();
        Integer endTimeInt = timeSlotMap.get(dayName).EndTime.hour();
        rec.workingHours = createWorkingHoursTimeLine(
          startTimeInt,
          endTimeInt - 1
        );
        rec.mainData = new List<SchedulerWrapData.mainDataWrap>();

        Map<Datetime, SchedulerWrapData.AvailabilityTrainer> mapTrainers = new Map<Datetime, SchedulerWrapData.AvailabilityTrainer>();
        Map<Datetime, SchedulerWrapData.AvailabilityMachine> mapMachines = new Map<Datetime, SchedulerWrapData.AvailabilityMachine>();
        SchedulerWrapData.AvailabilityMachine availMachine = new SchedulerWrapData.AvailabilityMachine(
          0,
          0,
          0
        );
        SchedulerWrapData.AvailabilityTrainer availTrainer = new SchedulerWrapData.AvailabilityTrainer(
          0,
          0,
          0
        );
        for (ServiceResource res : resources) {
          SchedulerWrapData.mainDataWrap mainData = new SchedulerWrapData.mainDataWrap();

          mainData.resName = res.Name;
          mainData.resId = res.Id;
          mainData.isPerson = res.IsPerson__c;
          mainData.selectedTrainer = trainerId != null &&
            trainerId == res.Id
            ? true
            : false;
          mainData.scheduledTimes = new List<SchedulerWrapData.mainDataChild>();

          // List<ServiceAppointment> resAppointments = resourceAppointmentsMap.containsKey(res.Id) ? resourceAppointmentsMap.get(res.Id) : new List<ServiceAppointment>();
          List<AssignedResource> resAppointments = assignedResourceMap.containsKey(
              res.Id
            )
            ? assignedResourceMap.get(res.Id)
            : new List<AssignedResource>();

          // Filter absences and shifts for the current resource
          List<ResourceAbsence> resAbsences = new List<ResourceAbsence>();
          for (ResourceAbsence absence : absences) {
            if (absence.ResourceId == res.Id) {
              resAbsences.add(absence);
            }
          }

          List<Shift> resShifts = new List<Shift>();
          for (Shift shift : shifts) {
            if (shift.ServiceResourceId == res.Id) {
              resShifts.add(shift);
            }
          }

          for (Integer k = 0; k <= endTimeInt - startTimeInt; k++) {
            SchedulerWrapData.mainDataChild mainDataChild = new SchedulerWrapData.mainDataChild();
            mainDataChild.boxes = new List<String>();
            mainDataChild.boxes2 = new List<SchedulerWrapData.Box>();

            Integer currentHour = k + startTimeInt;

            for (Integer j = 0; j < 4; j++) {
              Boolean isRed = false;
              Boolean isGrey = false;
              List<String> tooltips = new List<String>();
              Boolean isTooltip = false;
              SchedulerWrapData.Box box = new SchedulerWrapData.Box();

              Datetime currentSlotTime = currentDatetime.addHours(currentHour)
                .addMinutes(j * 15);
              // SFSCH-slot-board-booking: ISO-8601 with explicit offset so the
              // LWC can hand it straight to the booking flow as text.
              box.startIso = currentSlotTime.format(
                'yyyy-MM-dd\'T\'HH:mm:ssXXX',
                'Europe/Bratislava'
              );
              box.resId = res.Id;

              if (!mapTrainers.containsKey(currentSlotTime)) {
                mapTrainers.put(currentSlotTime, availTrainer);
              }
              availTrainer = mapTrainers.get(currentSlotTime);
              if (!mapMachines.containsKey(currentSlotTime)) {
                mapMachines.put(currentSlotTime, availMachine);
              }
              availMachine = mapMachines.get(currentSlotTime);

              if (currentSlotTime >= currentDatetime.addHours(endTimeInt)) {
                break;
              }
              // Check for absences specific to the resource.
              // Machine occupancy absences (Type = 'Machine Usage') mean the
              // machine is busy with a training -> show RED like a booking.
              // Any other absence means the resource is unavailable -> GREY.
              for (ResourceAbsence absence : resAbsences) {
                if (
                  currentSlotTime >= absence.Start &&
                  currentSlotTime < absence.End
                ) {
                  if (absence.Type == 'Machine Usage') {
                    isRed = true;
                    // SFSCH-slot-board-booking: lets the board open the
                    // modify flow for the training occupying this machine.
                    box.appointmentId = absence.Service_Appointment__c;
                  } else {
                    isGrey = true;
                  }
                  break;
                }
              }

              // Check for shifts specific to the resource.
              // Skip when isRed (a Machine Usage absence already marked this
              // slot as busy) so the machine occupancy isn't greyed out by the
              // absence of a trainer-style shift on the machine.
              if (!isGrey && !isRed) {
                Boolean isWithinShift = false;
                for (Shift shift : resShifts) {
                  if (
                    currentSlotTime >= shift.StartTime &&
                    currentSlotTime < shift.EndTime
                  ) {
                    isWithinShift = true;
                    break;
                  }
                }
                if (!isWithinShift) {
                  isGrey = true;
                }
              }

              // Check for appointments
              if (!isGrey && !isRed) {
                // for (ServiceAppointment app : resAppointments) {
                for (assignedResource app : resAppointments) {
                  if (
                    app.ServiceAppointment.SchedStartTime <= currentSlotTime &&
                    app.ServiceAppointment.SchedEndTime > currentSlotTime
                  ) {
                    isRed = true;
                    box.appointmentId = app.ServiceAppointmentId;
                    if (mainData.selectedTrainer || mainData.isPerson) {
                      tooltips.add(
                        app.ServiceAppointment.Account.Name != null
                          ? app.ServiceAppointment.Account.Name
                          : app.ServiceAppointment.Lead__r.Name
                      );
                      tooltips.add(app.ServiceAppointment.Email);
                      tooltips.add(
                        app.ServiceAppointment.Account.Phone != null
                          ? app.ServiceAppointment.Account.Phone
                          : app.ServiceAppointment.Lead__r.MobilePhone
                      );
                      tooltips.add(
                        app.ServiceAppointment.SchedStartTime.format() +
                          ' - ' +
                          app.ServiceAppointment.SchedEndTime.format()
                      );
                    }
                    break;
                  }
                }
              }

              if (isGrey) {
                mainDataChild.boxes.add('grey');
                box.box = 'grey';
                isTooltip = true;
                if (mainData.selectedTrainer) {
                  tooltips.add('V tomto čase nepracuješ');
                } else {
                  tooltips.add('Tréning nie je k dispozícii');
                }
                // if(res.IsPerson__c) {
                //     availTrainer.grey += 1;
                //     isTooltip = true;
                //     tooltips.add('Tréner nie je k dispozícii');
                // }
                // else {
                //     availMachine.grey += 1;
                //     isTooltip = true;
                //     tooltips.add('Tréning nie je k dispozícii test');
                // }
              } else {
                mainDataChild.boxes.add(isRed ? 'red' : 'white');
                box.box = isRed ? 'red' : 'white';
                isTooltip = true;
                if (mainData.selectedTrainer) {
                  if (box.box == 'white') {
                    tooltips.add('V tomto čase máš voľný slot');
                  }
                } else {
                  tooltips.add(
                    isRed ? 'Tréning je rezervovaný' : 'Tréning je k dispozícii'
                  );
                }
                // if(box.box == 'red') {
                //     if(res.isPerson__c) {
                //         availTrainer.red += 1;
                //         isTooltip = true;
                //         tooltips.add('Tréner je rezervovaný');
                //     }
                //     else {
                //         availMachine.red += 1;
                //         isTooltip = true;
                //         tooltips.add('Tréning je rezervovaný');

                //     }
                // }
                // if(box.box == 'white') {
                //     if(res.isPerson__c) {
                //         availTrainer.white += 1;
                //         isTooltip = true;
                //         tooltips.add('Tréner je k dispozícii');
                //     }
                //     else {
                //         if(availTrainer.white == 0) {
                //             box.box = 'grey';
                //             availMachine.grey += 1;
                //             isTooltip = true;
                //             tooltips.add('Tréning nie je k dispozícii');
                //         }
                //         else {
                //             availMachine.white += 1;
                //             isTooltip = true;
                //             tooltips.add('Tréning je k dispozícii');
                //         }
                //     }
                // }
              }
              mapTrainers.put(currentSlotTime, availTrainer);
              mapMachines.put(currentSlotTime, availMachine);
              box.boxId = String.valueOf(boxInteger);
              // SFSCH-slot-board-booking: only white boxes are bookable.
              box.isFree = (box.box == 'white');
              box.tooltips = tooltips;
              box.isTooltip = isTooltip;
              boxInteger++;
              mainDataChild.boxes2.add(box);
            }
            mainData.scheduledTimes.add(mainDataChild);
          }
          rec.mainData.add(mainData);
        }

        // System.debug('rec num ' + i);
        // System.debug(rec.workingHours);
        // System.debug(rec.dayName);
        // System.debug(rec.dayDate);
        // System.debug(rec.startTime);
        // System.debug(rec.endTime);
        // System.debug('break ');
        // System.debug('break ');
        // System.debug('break ');
        out.add(rec);
      }
      currentDate = currentDate.addDays(-i);
    }
    return out;
  }

  private static List<String> createWorkingHoursTimeLine(
    Integer startTime,
    Integer endTime
  ) {
    Integer numberHoursBetween = endTime - startTime;
    List<String> workingHours = new List<String>();
    workingHours.add(returnTimeFromInteger(startTime));
    for (Integer i = 1; i + startTime < endTime; i++) {
      workingHours.add(returnTimeFromInteger(startTime + i));
    }
    workingHours.add(returnTimeFromInteger(endTime));
    return workingHours;
  }

  private static String returnTimeFromInteger(Integer intTime) {
    if (intTime == null || intTime < 0 || intTime > 23) {
      return 'Invalid Time';
    }
    String hours = intTime < 10
      ? '0' + String.valueOf(intTime)
      : String.valueOf(intTime);
    return hours + ':00';
  }

  @AuraEnabled
  public static List<ServiceAppointment> getMultiTrainings() {
    return [
      SELECT
        Id,
        ServiceTerritoryId,
        SchedStartTime,
        SchedEndTime,
        Product__r.Name
      FROM ServiceAppointment
      WHERE
        WorkType.AppointmentCategoryId != NULL
        AND SchedStartTime >= TODAY
        AND Status != 'Canceled'
      LIMIT 3
    ];
  }

  @AuraEnabled
  public static Website_Settings__c getWebsiteSettings() {
    return Website_Settings__c.getInstance();
  }
}