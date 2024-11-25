public without sharing class SchedulerCMPController {

    @AuraEnabled
    public static String getTrainer(String xToken) {
        
        List<ServiceResource> resources = [SELECT Id, Token__c FROM ServiceResource WHERE Token__c =: xToken];
        return !resources.isEmpty() && resources.get(0).Token__c != null ? resources.get(0).Id  : null;
    }

    @AuraEnabled
    public static List<SchedulerWrapData.parentWrap> schedulerData(Id serviceTeritoryId, Id trainerId) {

        ServiceTerritory territory;
        if(serviceTeritoryId==null){
             territory = [SELECT Id, OperatingHoursId FROM ServiceTerritory WHERE Id = '0Hh9V000000IpiPSAS'];
        }else {
             territory = [SELECT Id, OperatingHoursId FROM ServiceTerritory WHERE Id =: serviceTeritoryId];
        }
       
        List<TimeSlot> weekTimes = [SELECT Id, OperatingHoursId, StartTime, EndTime, DayOfWeek FROM TimeSlot WHERE OperatingHoursId =: territory.OperatingHoursId];
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

        List<ServiceTerritoryMember> terMember =    [SELECT Id, ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember 
                                                    WHERE ServiceTerritoryId =: territory.Id];
        List<Id> resourceId = new List<Id>();
        for (ServiceTerritoryMember item : terMember) {
            resourceId.add(item.ServiceResourceId);
        }
        List<ServiceResource> resources = [SELECT Id, Name, IsPerson__c FROM ServiceResource WHERE Id IN: resourceId ORDER BY IsPerson__c DESC];

        List<ResourceAbsence> absences = [SELECT Id, ResourceId, Start, End FROM ResourceAbsence WHERE ResourceId IN :resourceId];
        List<Shift> shifts = [SELECT Id, ServiceResourceId, StartTime, EndTime, Status FROM Shift WHERE ServiceResourceId IN :resourceId AND ServiceTerritoryId =:territory.Id AND Status ='Confirmed'];

        
        Date todayDate = Date.today();
        todayDate = todayDate.addDays(-20);
        DateTime startOfToday = DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day());
        List<ServiceAppointment> appointments = [SELECT Id, ServiceTerritoryId, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE ServiceTerritoryId =: territory.Id AND SchedStartTime >= :startOfToday AND (Status = 'Paid' OR Status = 'Unpaid')];
        List<Id> appointmentIds = new List<Id>();

        for (ServiceAppointment item : appointments) {
            appointmentIds.add(item.Id);
            System.debug(item);
        }
        List<AssignedResource> assignResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource WHERE ServiceResourceId IN: resourceId AND ServiceAppointmentId IN: appointmentIds];

        Map<Id, List<ServiceAppointment>> resourceAppointmentsMap = new Map<Id, List<ServiceAppointment>>();
        for (AssignedResource ar : assignResource) {
            ServiceAppointment app = [SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Account.Name, Account.Phone, Email, ParentRecord.Name FROM ServiceAppointment WHERE Id = :ar.ServiceAppointmentId];
            if (!resourceAppointmentsMap.containsKey(ar.ServiceResourceId)) {
                resourceAppointmentsMap.put(ar.ServiceResourceId, new List<ServiceAppointment>());
            }
            resourceAppointmentsMap.get(ar.ServiceResourceId).add(app);
        }

        Integer boxInteger = 1;
        for (Integer i = 0; i < 28; i++) {
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
                rec.dayName = dayName;
                rec.dayDate = currentDatetime.format('dd-MM-yyyy');
                rec.startTime = timeSlotMap.get(dayName).StartTime;
                rec.endTime = timeSlotMap.get(dayName).EndTime;

                Integer startTimeInt = timeSlotMap.get(dayName).StartTime.hour();
                Integer endTimeInt = timeSlotMap.get(dayName).EndTime.hour();
                rec.workingHours = createWorkingHoursTimeLine(startTimeInt, endTimeInt-1);
                rec.mainData = new List<SchedulerWrapData.mainDataWrap>();

                Map<Datetime,SchedulerWrapData.AvailabilityTrainer> mapTrainers = new Map<Datetime, SchedulerWrapData.AvailabilityTrainer>();
                Map<Datetime,SchedulerWrapData.AvailabilityMachine> mapMachines = new Map<Datetime, SchedulerWrapData.AvailabilityMachine>();
                SchedulerWrapData.AvailabilityMachine availMachine = new SchedulerWrapData.AvailabilityMachine(0,0,0);
                SchedulerWrapData.AvailabilityTrainer availTrainer = new SchedulerWrapData.AvailabilityTrainer(0,0,0);
                for (ServiceResource res : resources) {
                    
                    
                    SchedulerWrapData.mainDataWrap mainData = new SchedulerWrapData.mainDataWrap();

                    mainData.resName = res.Name;
                    mainData.resId = res.Id;
                    mainData.isPerson = res.IsPerson__c;
                    mainData.selectedTrainer = trainerId != null && trainerId == res.Id ? true : false;
                    mainData.scheduledTimes = new List<SchedulerWrapData.mainDataChild>();

                    List<ServiceAppointment> resAppointments = resourceAppointmentsMap.containsKey(res.Id) ? resourceAppointmentsMap.get(res.Id) : new List<ServiceAppointment>();

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

                            Datetime currentSlotTime = currentDatetime.addHours(currentHour).addMinutes(j * 15);

                            if(!mapTrainers.containsKey(currentSlotTime)) {
                                mapTrainers.put(currentSlotTime, availTrainer);
                            }
                            availTrainer = mapTrainers.get(currentSlotTime);
                            if(!mapMachines.containsKey(currentSlotTime)) {
                                mapMachines.put(currentSlotTime, availMachine);
                            }
                            availMachine = mapMachines.get(currentSlotTime);

                            if (currentSlotTime >= currentDatetime.addHours(endTimeInt)) {
                                break;
                            }
                            // Check for absences specific to the resource
                            for (ResourceAbsence absence : resAbsences) {
                                if (currentSlotTime >= absence.Start && currentSlotTime < absence.End) {
                                    isGrey = true;
                                    break;
                                }
                            }

                            // Check for shifts specific to the resource
                            if (!isGrey) {
                                Boolean isWithinShift = false;
                                for (Shift shift : resShifts) {
                                    if (currentSlotTime >= shift.StartTime && currentSlotTime < shift.EndTime ) {
                                        isWithinShift = true;
                                        break;
                                    }
                                }
                                if (!isWithinShift) {
                                    isGrey = true;
                                    
                                }
                            }

                            // Check for appointments
                            if (!isGrey) {
                                for (ServiceAppointment app : resAppointments) {
                                    if (app.SchedStartTime <= currentSlotTime && app.SchedEndTime > currentSlotTime) {
                                        isRed = true;
                                        if(mainData.selectedTrainer) {
                                            tooltips.add(app.Account.Name);
                                            tooltips.add(app.Email);
                                            tooltips.add(app.Account.Phone);
                                            tooltips.add(app.SchedStartTime.format() + ' - ' + app.SchedEndTime.format());
                                        }
                                        break;
                                    }
                                }
                            }

                            if (isGrey) {
                                mainDataChild.boxes.add('grey');
                                box.box = 'grey';
                                isTooltip = true;
                                if(mainData.selectedTrainer) {
                                    tooltips.add('V tomto čase nepracuješ');
                                }
                                else {
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
                                if(mainData.selectedTrainer) {
                                    if(box.box == 'white') {
                                        tooltips.add('V tomto čase máš voľný slot');
                                    }
                                }
                                else {
                                    tooltips.add(isRed ? 'Tréning je rezervovaný' : 'Tréning je k dispozícii');

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

    private static List<String> createWorkingHoursTimeLine(Integer startTime, Integer endTime) {
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
        String hours = intTime < 10 ? '0' + String.valueOf(intTime) : String.valueOf(intTime);
        return hours + ':00';
    }
}