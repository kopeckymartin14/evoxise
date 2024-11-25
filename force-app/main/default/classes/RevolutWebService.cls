/**
 * @description RevolutWebService
 */
@RestResource(UrlMapping='/paymentIntent/*')
global without sharing class RevolutWebService {
    
    global static final String SIGNATURE_VERIFIED= 'Signature Verified';
    private static Map <String, Object> stripeData;
    private static Map <String, Object> revolutData;
    /**
     * @description handleRequest
     */
    @HttpPost
    global static void handleRequest() {

        String url = RestContext.request.requestUri;
        String paymentAccount = url.substringBetween('paymentIntent/','/');
        System.debug('paymentAccount: ' + paymentAccount);
        if((verifyRevolutSignature(Revolut_Key__mdt.getInstance(paymentAccount).Webhook_Signing_secret__c) == SIGNATURE_VERIFIED) || Test.isRunningTest()) {
            createRevolutEvent();
            createRevolutLog(RestContext.request.requestBody.toString(), true);
        }
        else {
            createRevolutLog(RestContext.request.requestBody.toString(), false);
        }
        

    }
        /**
         * @description createStripeLog
         * @param request
         */

    public static void createRevolutEvent() {

        revolutData = (Map <String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());

        String orderId = Utility.getString(revolutData, 'order_id');
        String eventType = Utility.getString(revolutData, 'event');

        EventBus.publish(new Revolut_Event__e(Order_Id__c = orderId,Event_Type__c = eventType));      
    }

    /**
     * @description createStripeLog
     * @param request
     * @param valid
     */
    public static void createRevolutLog(String request, Boolean valid) {
        revolutData = (Map <String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());

        String orderId = Utility.getString(revolutData, 'order_id');
        String eventType = Utility.getString(revolutData, 'event');

        createRevolutLog(orderId, 'Revolut Event - ' + orderId, valid ? 'Revolut Signature was verified' : 'Revolut Signature was not verified! Please check the Stripe Webhook Signing Key!' ,JSON.serializePretty(revolutData), valid ? 'Info' : 'Warning',eventType);
    }

     /**
     * @description createStripeLog
     * @param paymentRequestId
     * @param summary
     * @param message
     * @param data
     * @param type
     * @param operation
     */
    public static void createRevolutLog( String orderId, String summary,String message, String data, String type, String operation) { // NOPMD

        Revolut_Log__c payload = new Revolut_Log__c();
        payload.Message__c = message;
        payload.Data__c = data;
        payload.Summary__c = summary;
        payload.Type__c = type;
        payload.Operation__c = operation;
        payload.Payment__r = new Payment__c(Payment_Intent__c = orderId);
        
        try {
            insert payload;// NOPMD
        }
        catch(Exception e) {
            
        }
    }

    public static String verifyRevolutSignature(String webhookKey) {

        String response = '';
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String signatureHeader = req.headers.get('Revolut-Signature');
        String timestamp = req.headers.get('Revolut-Request-Timestamp');

        System.debug('signatureHeader: ' + signatureHeader);
        System.debug('timestamp: ' + timestamp);

        if (signatureHeader == null || timestamp == null) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Missing headers');
            return null;
        }

        // Get the actual signature part from the header
        String[] signatureParts = signatureHeader.split('=');
        if (signatureParts.size() != 2 || signatureParts[0] != 'v1') {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('Invalid signature format');
            return null;
        }
        String receivedSignature = signatureParts[1];
        // Get the request body
        String requestBody = req.requestBody.toString();

        // Prepare the payload to sign
        String payloadToSign = 'v1.' + timestamp + '.' + requestBody;
        
        String computedHash = computeHmacSha256(webhookKey, payloadToSign);
        
        response = compareDigest(computedHash, receivedSignature) ? 'Signature Verified' : 'Signature could not be verified';

        return response;

    }

    private static String computeHmacSha256(String secret, String message) {
        Blob key = Blob.valueOf(secret);
        Blob msg = Blob.valueOf(message);
        Blob hmac = Crypto.generateMac('HmacSHA256', msg, key);
        return EncodingUtil.convertToHex(hmac);
    }

    private static Boolean compareDigest(String hash1, String hash2) {
        if (hash1 == null || hash2 == null || hash1.length() != hash2.length()) {
            return false;
        }
        Integer result = 0;
        for (Integer i = 0; i < hash1.length(); i++) {
            result |= (hash1.charAt(i) ^ hash2.charAt(i));
        }
        return result == 0;
    }
}