/**
 * @description HttpService
 */
public without sharing class HttpService {

    static final Integer TIMEOUT = 120000;
    /**
     * @description sendGetRequestWithHeaders
     * @param endpoint
     * @param headers
     * @return HttpResponse
     */
    public static HttpResponse sendGetRequestWithHeaders(final String endpoint, final Map<String, String> headers) {
        HttpRequest req = createRequestWithHeaders(endpoint, headers);
        req.setMethod('GET');
        return new Http().send(req);
    }
    /**
     * @description sendPostRequestWithHeaders
     * @param endpoint
     * @param body
     * @param headers
     * @return HTTPResponse
     */
    public static HTTPResponse sendPostRequestWithHeaders(final String endpoint, final String body, final Map<String, String> headers) {
        HttpRequest req = createRequestWithHeaders(endpoint, headers);
        req.setMethod('POST');
        if (String.isNotBlank(body)) {
            req.setBody(body);
        }
        return new Http().send(req);
    }

    private static HttpRequest createRequestWithHeaders(final String endpoint, final Map<String, String> headers) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setTimeout(TIMEOUT);
        if (headers != null) {
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        return req;
    }

}