@isTest
public without sharing class INV_GenerateRegistrationCodeTest {
    @isTest
    private static void generate6DigitRandomNumberTest() {
        List<INV_GenerateRegistrationCode.CharacterLength> characterLengths = new List<INV_GenerateRegistrationCode.CharacterLength>();
        INV_GenerateRegistrationCode.CharacterLength charLength = new INV_GenerateRegistrationCode.CharacterLength();
        charLength.characterLength = 6;
        characterLengths.add(charLength);

        List<INV_GenerateRegistrationCode.RandomNumberResponse> responses = INV_GenerateRegistrationCode.generate6DigitRandomNumber(characterLengths);
        System.assertEquals(1, responses.size());
        System.assertEquals(6, responses[0].randomNumber.length());
        System.assertNotEquals('', responses[0].randomNumber);
    }
}