@isTest
public class RevolutMockFactory {
    
    public static void getRevolutMockData(String paymentId) {

        HttpCalloutMock createOrderMock = new SingleRequestMock(
                200,
                'Complete',
                '{"id":"6703fc6a-ad41-a5d9-b1cf-f8ca900e7461","token":"018f1b87-9640-4d2a-93dd-660310ebd0bd","type":"payment","state":"pending","created_at":"2024-10-07T15:21:14.733368Z","updated_at":"2024-10-07T15:21:14.733368Z","amount":1500,"currency":"EUR","outstanding_amount":1500,"capture_mode":"automatic","description":"ARX Fitness Training","checkout_url":"https://sandbox-checkout.revolut.com/payment-link/018f1b87-9640-4d2a-93dd-660310ebd0bd","metadata":{"paymentId":"' + paymentId + '","appointmentIds":"appointment1;appointment2;appoitment3"},"enforce_challenge":"automatic","redirect_url":"https://example.com","customer":{"id":"78071c4e-f483-4c63-b9ac-884bef63c68f","email":"testcustomer@testtest.com"}}',
                null
        );

        
        Map<String, HttpCalloutMock> endpoints = new Map<String,HttpCalloutMock>();
        RevolutBaseApi revolut = new RevolutBaseApi();
        endpoints.put(revolut.getRevolutBaseUrl() +'/api/orders', createOrderMock);

        HttpCalloutMock multiCalloutMock =  new MultiRequestMock(endpoints);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

    }

    /**
     * @description MultiRequestMock
     */
    public class MultiRequestMock implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;
        /**
         * @description MultiRequestMock
         * @param requests
         */
        public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }
         /**
         * @description multi mock respond
         * @param req
         * @return HTTPResponse
         */
        public HTTPResponse respond(HTTPRequest req) {

            HttpCalloutMock mock = requests.get(req.getEndpoint().substringBefore('?'));
    
            if (mock != null) {
                return mock.respond(req);
            } else {
                System.debug('HTTP callout not supported for test methods'); // NOPMD
            }

            return null;
        }
    }
    /**
     * @description single mock subclass
     */
    public class SingleRequestMock implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String bodyAsString;
        protected Map<String, String> responseHeaders;

        public SingleRequestMock(Integer code, String status, String body, // NOPMD
                Map<String, String> responseHeaders) {
            this.code = code;
            this.status = status;
            this.bodyAsString = body;
            this.responseHeaders = responseHeaders;
        }
        /**
         * @description single mock respond
         * @param req
         * @return HTTPResponse
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(code);
            resp.setStatus(status);
            resp.setBody(bodyAsString);

            if (responseHeaders != null) {
                for (String key : responseHeaders.keySet()) {
                    resp.setHeader(key, responseHeaders.get(key));
                }
            }

            return resp;
        }
    }
}