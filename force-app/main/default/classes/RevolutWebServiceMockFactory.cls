@isTest
public class RevolutWebServiceMockFactory {
    
    public static String getRevolutWebhook(String type, String orderId) {

        Map<String, String> webhooks = new Map<String,String>();
        webhooks.put('orderPaid', getOrderCompleted(orderId));

        return webhooks.get(type);

    }

    public static String getOrderCompleted(String orderId) {
        return '{\n' +
            '"order_id": "' + orderId + '",\n' +
            '"event": "ORDER_COMPLETED"\n' +
            '}';
    }
}