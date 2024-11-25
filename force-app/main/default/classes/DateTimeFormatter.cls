public class DateTimeFormatter {
    @InvocableMethod(label='Format DateTime')
    public static List<DateTimeFormatResult> formatDateTime(List<DateTime> dateTimes) {
        List<DateTimeFormatResult> results = new List<DateTimeFormatResult>();
        for (DateTime dt : dateTimes) {
            DateTimeFormatResult result = new DateTimeFormatResult();
            result.formattedDate = dt.format('dd.MM.yyyy');
            result.formattedTime = dt.format('HH:mm');
            results.add(result);
        }
        return results;
    }

    public class DateTimeFormatResult {
        @InvocableVariable(label='Formatted Date')
        public String formattedDate;

        @InvocableVariable(label='Formatted Time')
        public String formattedTime;
    }
}