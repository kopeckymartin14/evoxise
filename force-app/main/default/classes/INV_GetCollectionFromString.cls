/**
 * Invcable class for flows converting comma seprated String to List<String>
 *
 * @author      Juraj Kopecky (juraj.kopecky@external.t-mobile.cz)
 * @created     June 2022
 */
global inherited sharing class INV_GetCollectionFromString {
    /**
    * @author          Juraj Kopecky (juraj.kopecky@external.t-mobile.cz)
    * @description     Returns List Of strings from Comma Separated String
    * @param           List<Request> requestList => String commaSeparatedString
    * @return          List<Result> results  => List<String> listStrings
    */
    @InvocableMethod(label='Get String Collection from Comma Separated String' description='Given a Comma separated string and hydrate it into List Strings')
    global static List <Result> execute (List<Request> requestList) {
        
        List<Result> results =  new List<Result>();
        
        for (Request request: requestList) {
           
            String inputs = request.commaSeparatedString.Replace('; ',';');
            Result result = new Result();
            List<String> stringValues = inputs.split(';');
            result.listStrings= stringValues;
       
              
            results.add(result);
        }
        return results;
    }



    global class Request {
        
        /**
         * @description    Comma Separated String, come from Multipicklist or Multicheckbox
         */
        @InvocableVariable(label='Comma Separated String')
        global String commaSeparatedString;
        
     
    }
    /**
     * @description     Returned list of Strings
     */
    global class Result {
        @InvocableVariable(description='List Strings')
        global List<String> listStrings;

 
    }
}