/**
 * Test class for Invocable class INV_GetStringCollectionFromString
 *
 * @author      Juraj Kopecky (juraj.kopecky@external.t-mobile.cz)
 * @created     June 2022
 */
@isTest
public inherited sharing class INV_GetCollectionFromStringTest{
     /**
    * @author          Juraj Kopecky (juraj.kopecky@external.t-mobile.cz)
    * @description     Test Method, call INV_GetStringCollectionFromString to convert Comma Separated String to List<String>
    * @param           List<Request> requestList
    */
    @isTest
    public static void convertStringToList() {

        INV_GetCollectionFromString.Request curRequest = new INV_GetCollectionFromString.Request();
        curRequest.commaSeparatedString= 'aaa; bbb; ccc';

        List<INV_GetCollectionFromString.Request> curRequests = new List<INV_GetCollectionFromString.Request>();
        curRequests.add(curRequest);
        List<INV_GetCollectionFromString.Result> curResponses = INV_GetCollectionFromString.execute(curRequests);
        System.debug('curResponses is:' + curResponses);
        System.assertEquals(curResponses[0].listStrings.size(), 3);
    }
}