@IsTest
private class INV_GeneratePaymentHTMLtableTest {

    @IsTest
    static void testGeneratePaymentHTMLTableWithVatPayer() {
        // Prepare test data with VAT payer as true
        INV_GeneratePaymentHTMLtable.PaymentRequest request = new INV_GeneratePaymentHTMLtable.PaymentRequest();
        request.vatPayer = true;

        Product2 product = new Product2(
            name = 'Product A'
        );
        insert product;

        // Sample Payment_Items__c records
        Payment_Items__c paymentItem1 = new Payment_Items__c(
            Product__c = product.Id,
            Quantity__c = 2,
            Unit_Price_Without_VAT__c = 50.0,
            Unit_Price_VAT__c = 10.0,
            Unit_Price__c = 60.0,
            Sum_To_Amount__c = true,
            VAT_Number__c = 20
        );

        Payment_Items__c paymentItem2 = new Payment_Items__c(
            Product__c = product.Id,
            Quantity__c = 1,
            Unit_Price_Without_VAT__c = 200.0,
            Unit_Price_VAT__c = 40.0,
            Unit_Price__c = 240.0,
            Sum_To_Amount__c = true,
            VAT_Number__c = 20
        );

        request.paymentItems = new List<Payment_Items__c>{ paymentItem1, paymentItem2 };

        List<INV_GeneratePaymentHTMLtable.PaymentRequest> requestList = new List<INV_GeneratePaymentHTMLtable.PaymentRequest>{ request };

        // Call the method
        List<INV_GeneratePaymentHTMLtable.PaymentHTMLResult> results = INV_GeneratePaymentHTMLtable.generatePaymentHTMLTable(requestList);

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertNotEquals(null, results[0].HTMLTable, 'The HTMLTable should not be null');
        System.assert(results[0].HTMLTable.contains('<table'), 'The HTMLTable should contain a table tag');
    }

    @IsTest
    static void testGeneratePaymentHTMLTableWithoutVatPayer() {

        Product2 product = new Product2(
            name = 'Product A'
        );
        insert product;
        // Prepare test data with VAT payer as false
        INV_GeneratePaymentHTMLtable.PaymentRequest request = new INV_GeneratePaymentHTMLtable.PaymentRequest();
        request.vatPayer = false;

        // Sample Payment_Items__c records
        Payment_Items__c paymentItem = new Payment_Items__c(
            Product__c = product.Id,
            Quantity__c = 3,
            Unit_Price_Without_VAT__c = 0.0,    // Not relevant without VAT
            Unit_Price_VAT__c = 0.0,            // Not relevant without VAT
            Unit_Price__c = 60.0,
            Sum_To_Amount__c = true,
            VAT_Number__c = 0
        );

        request.paymentItems = new List<Payment_Items__c>{ paymentItem };

        List<INV_GeneratePaymentHTMLtable.PaymentRequest> requestList = new List<INV_GeneratePaymentHTMLtable.PaymentRequest>{ request };

        // Call the method
        List<INV_GeneratePaymentHTMLtable.PaymentHTMLResult> results = INV_GeneratePaymentHTMLtable.generatePaymentHTMLTable(requestList);

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertNotEquals(null, results[0].HTMLTable, 'The HTMLTable should not be null');
        System.assert(results[0].HTMLTable.contains('<table'), 'The HTMLTable should contain a table tag');
        System.assert(!results[0].HTMLTable.contains('cena bez DPH/ks'), 'The HTMLTable should not contain VAT-specific columns');
    }
}