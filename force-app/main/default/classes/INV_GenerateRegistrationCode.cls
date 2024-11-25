/**
 * @description INV_GenerateRegistrationCode
 */
public class INV_GenerateRegistrationCode {
    // Wrapper class for the output since invocable methods work with lists
    /**
     * @description // Wrapper class for the output since invocable methods work with lists
     */
    public class RandomNumberResponse {
        @InvocableVariable
        public String randomNumber;
    }

    public class CharacterLength {
        @InvocableVariable
        public Integer characterLength;
    }
    /**
     * @description generate6DigitRandomNumber
     * @return List<RandomNumberResponse> 
     */
    @InvocableMethod(label='Generate 6 Digit Random Number' description='Generates a 6 digit random number and returns it.')
    public static List<RandomNumberResponse> generate6DigitRandomNumber(List<CharacterLength> characterLength) {

        CharacterLength myLength = new characterLength();

        if(characterLength != null && !characterLength.isEmpty()) {
            myLength = characterLength.get(0);
        }
        
        String randomNumberString = '';
        Boolean uniqueConflict = false;
        if(myLength != null && myLength.characterLength != null) {
            randomNumberString = generateRandomString(myLength.characterLength);

        }
        else {
            while (randomNumberString == '' || uniqueConflict){
                Long part1 = Math.abs(Crypto.getRandomLong());
                randomNumberString = String.valueOf(part1).left(6); // Get first 6 digits        
                AggregateResult[] checkCode = [SELECT count(Id) counter FROM Account WHERE Unique_Code__c =: randomNumberString OR One_Time_Token__c =: randomNumberString OR Login_Token__c =: randomNumberString];
                uniqueConflict = (Integer)checkCode[0].get('counter') == 0 ? false : true;
            }
            
        }   
        
        List<RandomNumberResponse> responseList = new List<RandomNumberResponse>();
        RandomNumberResponse response = new RandomNumberResponse();
        response.randomNumber = randomNumberString;
        responseList.add(response);
        
        return responseList;
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}