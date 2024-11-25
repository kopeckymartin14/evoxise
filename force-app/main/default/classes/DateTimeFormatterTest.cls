@IsTest
public class DateTimeFormatterTest {
    @IsTest
    static void testFormatDateTime() {
        List<DateTime> dateTimes = new List<DateTime>();
        dateTimes.add(DateTime.newInstance(2022, 1, 1, 12, 0, 0));
        dateTimes.add(DateTime.newInstance(2022, 2, 1, 12, 0, 0));
        dateTimes.add(DateTime.newInstance(2022, 3, 1, 12, 0, 0));

        List<DateTimeFormatter.DateTimeFormatResult> results = DateTimeFormatter.formatDateTime(dateTimes);

        System.assertEquals(3, results.size());
        System.assertEquals('01.01.2022', results[0].formattedDate);
        System.assertEquals('12:00', results[0].formattedTime);
        System.assertEquals('01.02.2022', results[1].formattedDate);
        System.assertEquals('12:00', results[1].formattedTime);
        System.assertEquals('01.03.2022', results[2].formattedDate);
        System.assertEquals('12:00', results[2].formattedTime);
    }
}