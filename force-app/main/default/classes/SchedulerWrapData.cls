public without sharing class SchedulerWrapData {
    public class tableInfo {  
        @AuraEnabled
        public Id serviceResourceId { get; set; } 
    
    }
    public class weekOperatinghours {  
        @AuraEnabled
        public Time mondayStart { get; set; }
        @AuraEnabled
        public Time mondayEnd { get; set; }
        
        @AuraEnabled
        public Time tuesdayStart { get; set; }
        @AuraEnabled
        public Time tuesdayEnd { get; set; }
        
        @AuraEnabled
        public Time wednesdayStart { get; set; }
        @AuraEnabled
        public Time wednesdayEnd { get; set; }
        
        @AuraEnabled
        public Time thursdayStart { get; set; }
        @AuraEnabled
        public Time thursdayEnd { get; set; }
        
        @AuraEnabled
        public Time fridayStart { get; set; }
        @AuraEnabled
        public Time fridayEnd { get; set; }
        
        @AuraEnabled
        public Time saturdayStart { get; set; }
        @AuraEnabled
        public Time saturdayEnd { get; set; }
        
        @AuraEnabled
        public Time sundayStart { get; set; }
        @AuraEnabled
        public Time sundayEnd { get; set; }
    
    }
    public class parentWrap {  
        @AuraEnabled
        public String dayName { get; set; }
        @AuraEnabled
        public String dayDate { get; set; }
        @AuraEnabled
        public Time startTime { get; set; }
        @AuraEnabled
        public Time endTime { get; set; }
        @AuraEnabled
        public List<String> workingHours { get; set; }
        @AuraEnabled
        public List<mainDataWrap> mainData { get; set; }

        
    }
    public class mainDataWrap{
        @AuraEnabled
        public String resName { get; set; }
        @AuraEnabled
        public String resId { get; set; }
        @AuraEnabled
        public Boolean isPerson { get; set; }
        @AuraEnabled
        public Boolean selectedTrainer { get; set; }
        @AuraEnabled
        public List<mainDataChild> scheduledTimes { get; set; }
    }
    public class mainDataChild{
        @AuraEnabled
        public List<String> boxes { get; set; }
        @AuraEnabled
        public List<Box> boxes2 { get; set; }
    }

    public class Box {
        @AuraEnabled
        public String box { get; set; }
        @AuraEnabled
        public String boxId { get; set; }
        @AuraEnabled
        public String tooltip { get; set; }
        @AuraEnabled
        public List<String> tooltips { get; set; }
        @AuraEnabled
        public String tooltip2 { get; set; }
        @AuraEnabled
        public Boolean isTooltip { get; set; }
    }

    public class AvailabilityTrainer {
        @AuraEnabled
        public Integer grey { get; set; }
        @AuraEnabled
        public Integer red { get; set; }
        @AuraEnabled
        public Integer white { get; set; }

        public AvailabilityTrainer(Integer grey, integer red, integer white) {
            this.grey = grey;
            this.red = red;
            this.white = white;
        }

    }
    public class AvailabilityMachine {
        @AuraEnabled
        public Integer grey { get; set; }
        @AuraEnabled
        public Integer red { get; set; }
        @AuraEnabled
        public Integer white { get; set; }

        public AvailabilityMachine(Integer grey, integer red, integer white) {
            this.grey = grey;
            this.red = red;
            this.white = white;
        }

    }


}