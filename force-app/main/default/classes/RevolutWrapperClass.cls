public without sharing class RevolutWrapperClass {
    
    public enum RevolutStates {PENDING, PROCESSING, AUTHORISED, COMPLETED, CANCELLED , FAILED}

    public enum RevolutEvents {ORDER_AUTHORISED, ORDER_CANCELLED, ORDER_COMPLETED, ORDER_PAYMENT_AUTHENTICATED, ORDER_PAYMENT_DECLINED , ORDER_PAYMENT_FAILED}

    public class RevolutOrder {
        public Integer amount {get; set; }
        public String currencyCode {get; set; }
        public String description {get; set; }
        public String redirect_url {get; set; }
        public RevolutMetadata metadata {get; set; }
        public RevolutCustomer customer {get; set; }
 
    }

    public class RevolutMetadata {
        public String paymentId {get; set; }
        public String appointmentIds {get; set; }

    }

    public class RevolutCustomer {
        public String id {get; set; }
        public String email {get; set; }
        public String full_name {get; set; }
        public String phone {get; set; }

    }

    // public class RevolutOrderList {
    //     public Integer limits {get; set; }
    //     public datetime created_before {get; set; }
    //     public datetime to_created_date {get; set; }
    //     public datetime from_created_date {get; set; }
    //     public String customer_id {get; set; }
    //     public String email {get; set; }
    //     public List<String> state {get; set; }
    // }

    // public class RevolultWebhook {
    //     public String url {get; set; }
    //     public List<String> state {get; set; }
    // }


    public class RevolutResponse {
        public String id {get; set; }
        public String error {get; set; }
        public String checkout_url {get; set; }
        public RevolutCustomer customer {get; set; }
    }
}