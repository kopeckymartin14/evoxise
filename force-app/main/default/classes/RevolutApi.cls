global without sharing class RevolutApi extends RevolutBaseApi {

    @AuraEnabled
    global static String getRevolutPublicKey() {
        return getInstance(RevolutApi.class).getRevolutPublicKey();
    }

    public static RevolutWrapperClass.RevolutResponse createOrder(String url, Integer amount, String description, String customerId,
                                                                        String paymentId, String appointmentIds, String email, String fullName ) { // NOPMD
        return getInstance(RevolutApi.class).createOrder(url, amount, description, customerId,  paymentId, appointmentIds, email, fullName);
    }

    @InvocableMethod(label='Create Revolut Order')
    public static OutputVariables[] createOrder(List<InputVariables> inputVariables) {
        // Assuming only one input variable set is provided
        InputVariables input = inputVariables.get(0);

        String customerId = input.customerId;
        String paymentId = input.paymentId;
        String appointmentIds = input.appointmentIds;
        String url = input.url;
        Integer amount = input.amount;
        String description = input.description;
        String fullName = input.fullName;
        String email = input.email;
        // List<PaymentItemWrapper> paymentItems = input.paymentItems;

        OutputVariables[] results = new List<OutputVariables>();

        RevolutWrapperClass.RevolutResponse result = createOrder(url, amount, description, customerId, paymentId, appointmentIds, email, fullName);
        results.add(new OutputVariables(result.id, result.customer.id, result.checkout_url));
        return results;
    }

    public class InputVariables {
        @InvocableVariable
        public String customerId;
        @InvocableVariable
        public String paymentId;
        @InvocableVariable
        public String appointmentIds;
        @InvocableVariable
        public String url;
        @InvocableVariable
        public String description;
        @InvocableVariable
        public String fullName;
        @InvocableVariable
        public String email;
        @InvocableVariable
        public Integer amount;
       
    }

    public class OutputVariables {
        @InvocableVariable
        public String orderId;
        @InvocableVariable
        public String customerId;
        @InvocableVariable
        public String checkoutUrl;
        public OutputVariables(String orderId, String customerId, String checkoutUrl) {
            this.orderId = orderId;
            this.customerId = customerId;
            this.checkoutUrl = checkoutUrl;
        }
    }
}