global virtual class RevolutBaseApi {
    private static RevolutBaseApi instance;
    /**
     * @description getInstance
     * @param type
     * @return RevolutBaseApi
     */
    public static RevolutBaseApi getInstance(Type type) {
        if (RevolutBaseApi.instance == null) {
            RevolutBaseApi.instance = (RevolutBaseApi) type.newInstance();
        }

        return RevolutBaseApi.instance;
    }

     /**
     * @description getRevolutAccount
     * @return String
     */
    public String getRevolutAccount() {
        return getUserRevolutKey().Revolut_Account__c;
    }

    /**
     * @description standard implementation, just taking first entry can be overridden for more complex logic
     * @return Revolut_Key__mdt
     */
    protected virtual Revolut_Key__mdt getUserRevolutKey() {
        return Utility.isSandbox() ? Revolut_Key__mdt.getInstance('Revolut_UnityCloud') : Revolut_Key__mdt.getInstance('Revolut');
    }

    /**
     * @description Retrieves Revolut public key for custom metadata
     * @return String
     */
    public String getRevolutPublicKey() {
        Revolut_Key__mdt userKey = getUserRevolutKey();

        if (userKey != null && !Test.isRunningTest()) {
            return userKey.Public_Key__c;
        }

        return null;
    }

    /**
     * @description Retrieves Revolut private key for custom metadata - do not share this key!
     * @return String
     */
    @TestVisible
    private String getRevolutPrivateKey() {
        Revolut_Key__mdt userKey = getUserRevolutKey();

        return userKey?.Private_Key__c;
    }

     /**
     * @description Retrieves Revolut private key for custom metadata - do not share this key!
     * @return String
     */
    @TestVisible
    private String getRevolutBaseUrl() {
        Revolut_Key__mdt userKey = getUserRevolutKey();

        return userKey?.Base_Url__c;
    }

    @TestVisible
    private String getRevolutApiVersion() {
        Revolut_Key__mdt userKey = getUserRevolutKey();

        return userKey?.API_Version__c;
    }

    /**
     * @description main method for executing all POST requests, and logging errors if applied
     * @param endpoint
     * @param isPost
     * @return Map<String, Object>
     */
    protected Map<String, Object> executeRequest(String endpoint, Boolean isPost, String body) {
        Map<String, Object> out = new Map<String, Object>();

        String privateKey = getRevolutPrivateKey();
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        headers.put('Authorization', 'Bearer ' + privateKey);
        headers.put('Revolut-Api-Version', getRevolutApiVersion());

        HttpResponse response;

        if (isPost) {
            response = HttpService.sendPostRequestWithHeaders(endpoint, body, headers);
        } else {
            response = HttpService.sendGetRequestWithHeaders(endpoint, headers);
        }


        out = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        
        out.put('httpStatusCode', response.getStatusCode());
        out.put('httpStatusMessage', response.getStatus());

        return out;
    }

    public RevolutWrapperClass.RevolutResponse createOrder(String url, Integer amount, string description, String customerId, 
                                                            String paymentId, String appointmentIds,
                                                            String email, String fullName) { // NOPMD
 //Integer amount, String customerId, String url, String paymentMethod, String paymentId,String appointmentIds
        RevolutWrapperClass.RevolutResponse result = new RevolutWrapperClass.RevolutResponse();

        RevolutWrapperClass.RevolutOrder revolutwrapper = new RevolutWrapperClass.RevolutOrder();
        RevolutWrapperClass.RevolutMetadata metadata = new RevolutWrapperClass.RevolutMetadata();
        RevolutWrapperClass.RevolutCustomer customer = new RevolutWrapperClass.RevolutCustomer();

        String endpoint = getRevolutBaseUrl() + '/api/orders';

        // Add each payment item to the endpoint
        // revolutwrapper.amount = amount;
        revolutwrapper.amount = amount;
        revolutwrapper.currencyCode = 'EUR';
        revolutwrapper.description = description;
        revolutWrapper.redirect_url = url;

        // metadata.orderNumber = 'test';
        metadata.paymentId = paymentId;
                                                   
        if(appointmentIds != null ) {
			metadata.appointmentIds = appointmentIds;
		}

        if(customerId != null) {
            customer.id = customerId;
        }
        else {
            customer.email = email;
            customer.full_name = fullName;
        }
       

        revolutwrapper.metadata = metadata;
        revolutwrapper.customer = customer;
        String body = JSON.serializePretty(revolutWrapper);
        body = body.replace('currencyCode','currency');

        System.debug('body: ' + body);
        Map<String, Object> responseMap = executeRequest(endpoint, true, body);

        Integer responseCode = Integer.valueOf(responseMap.get('httpStatusCode'));
        try {
            if (responseCode == 200 || responseCode == 201) {

                result.id = (String) responseMap.get('id');
                result.checkout_url = (String) responseMap.get('checkout_url');
                Map<String,Object> mapCustomer = (Map<String,Object>)responseMap.get('customer');
                customer.id = (String)mapCustomer.get('id');
                result.customer = customer;
            } else {
                if (!Test.isRunningTest()) {
                    System.debug('responseMap: ' + responseMap);
                    throw new RevolutException('Order Creation error.');
                }
            }
        }
        catch (Exception e) {
            System.debug('getMessage: ' + e.getMessage());
            System.debug('getStackTraceString: ' + e.getStackTraceString());
            System.debug('getLineNumber: ' + e.getLineNumber());
        }
        return result;
    }

    /**
     * @description RevolutException
     */
    public class RevolutException extends Exception {
    }
}