public inherited sharing class Utility {
   
    public static Boolean isSandbox() {
        return DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName() == null ? false : true;

    }

    public static Map<String, Object> getMap(Map <String, Object> requestMap, String fieldApi) {

        return (Map<String, Object>) requestMap.get(fieldApi);
    }

    public static List<Object> getList(Map <String, Object> requestMap, String fieldApi) {

        return (List<Object>) requestMap.get(fieldApi);
    }

    public static String getString(Map <String, Object> requestMap, String fieldApi) {

        return (String) requestMap.get(fieldApi);
    }

    public static Id getId(Map <String, Object> requestMap, String fieldApi) {

        return (Id) requestMap.get(fieldApi);
    }

    public static Decimal getDecimal(Map <String, Object> requestMap, String fieldApi) {

        return (Decimal) requestMap.get(fieldApi);
    }

    public static Integer getInteger(Map <String, Object> requestMap, String fieldApi) {

        return (Integer) requestMap.get(fieldApi);
    }

}