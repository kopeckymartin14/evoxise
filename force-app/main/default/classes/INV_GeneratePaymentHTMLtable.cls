public class INV_GeneratePaymentHTMLtable {

    @InvocableMethod(label='Generate Payment HTML Table')
    public static List<PaymentHTMLResult> generatePaymentHTMLTable(List<PaymentRequest> requestList) {
        List<Payment_Items__c> paymentItems = requestList[0].paymentItems;
        Boolean vatPayer = requestList[0].vatPayer;

        List<PaymentHTMLResult> response = new List<PaymentHTMLResult>();
        PaymentHTMLResult result = new PaymentHTMLResult();
        response.add(result);

        // Generate HTML table for Payment Items based on VAT Payer status
        List<String> output = generateHTMLTable(paymentItems, vatPayer);
        result.HTMLTable = output[0];

        return response;
    }

    public class PaymentRequest {
        @InvocableVariable(required=true)
        public List<Payment_Items__c> paymentItems;

        @InvocableVariable(required=true)
        public Boolean vatPayer;
    }

    public class PaymentHTMLResult {
        @InvocableVariable
        public string HTMLTable;

        public PaymentHTMLResult(){}
    }

    public static List<String> generateHTMLTable(List<Payment_Items__c> paymentItems, Boolean vatPayer) {
        List<String> output = new List<String>();
        decimal totalAmount = 0;
        decimal vatRate = 0.2; // Example VAT rate of 20%
        decimal totalVAT = 0;
        decimal totalAmountWithVAT = 0;
    
        string htmlString = '<div style="width:100%; overflow: auto;"><table align="left" style="border-collapse: collapse;margin: 20px auto;">' +
                            '<thead><tr><th colspan=' + (vatPayer ? '8' : '4') + ' style="border: 1px solid #000;padding: 3px;text-align: center; background-color: #f2f2f2;">Produkt Rekapitulácia</th></tr>' +
                            '<tr><th style="border: 1px solid #000;padding: 3px;text-align: left; background-color: #f2f2f2;">Produkt</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: left; background-color: #f2f2f2;">Množstvo</th>' +
                            (vatPayer ? '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">cena bez DPH/ks</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">DPH/ks</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">cena s DPH/ks</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">Spolu bez DPH</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">DPH</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">Spolu s DPH</th>' :
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">Jednotková cena</th>' +
                            '<th style="border: 1px solid #000;padding: 3px;text-align: right; background-color: #f2f2f2;">Spolu</th>') + 
                            '</tr></thead><tbody>';
    
        for(Payment_Items__c payment : paymentItems) {
            decimal amount = payment.TotalAmountWithoutVAT2__c != null ? payment.TotalAmountWithoutVAT2__c : 0;
            decimal vat = payment.TotalAmountVAT2__c != null ? payment.TotalAmountVAT2__c : 0;
            decimal amountWithVAT = payment.Total_Amount__c != null ? payment.Total_Amount__c : 0;
            decimal unitWithoutVAT = payment.Unit_Price_Without_VAT__c != null ? payment.Unit_Price_Without_VAT__c : 0;
            decimal unitWithVAT = payment.Unit_Price__c != null ? payment.Unit_Price__c : 0;
            decimal unitVAT = payment.Unit_Price_VAT__c != null ? payment.Unit_Price_VAT__c : 0;
            integer quantity = (INTEGER)payment.Quantity__c;
            integer VATnumber = (INTEGER)payment.VAT_Number__c;
    
            htmlString += '<tr><td style="border: 1px solid #000;padding: 3px;text-align: left;font-weight: bold;">' + payment.Product_Name__c + '</td>' +
                          '<td style="border: 1px solid #000;padding: 3px;padding-right:100px;text-align: left;">' + quantity + '</td>';
    
            if(vatPayer) {
                htmlString += '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + unitWithoutVAT.setScale(2) + '</td>' +
                              '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + unitVAT.setScale(2) + ' (' + VATnumber +'%)</td>' +
                              '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + unitWithVAT.setScale(2) + '</td>' +
                              '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + amount.setScale(2) + '</td>' +
                              '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + vat.setScale(2) + ' (' + VATnumber + '%)</td>' +
                              '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + amountWithVAT.setScale(2) + '</td>';
            } else {
                htmlString += '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + unitWithVAT.setScale(2) + '</td>';
                htmlString += '<td style="border: 1px solid #000;padding: 3px;text-align: right;">€' + amountWithVAT.setScale(2) + '</td>';
            }
    
            if(!Test.isRunningTest()) {
                totalAmount += amount;
                totalVAT += vat;
                totalAmountWithVAT += amountWithVAT;
            }
        }
    
        htmlString += '<tr><td colspan=' + (vatPayer ? '5' : '3') + ' style="border: 1px solid #000;padding: 3px;text-align: center; font-weight: bold;">TOTAL</td>';
        if(vatPayer) {
            htmlString += '<td style="border: 1px solid #000;padding: 3px;text-align: right; font-weight: bold;">€' + totalAmount.setScale(2) + '</td>' +
                          '<td style="border: 1px solid #000;padding: 3px;text-align: right; font-weight: bold;">€' + totalVAT.setScale(2) + '</td>' +
                          '<td style="border: 1px solid #000;padding: 3px;text-align: right; font-weight: bold;">€' + totalAmountWithVAT.setScale(2) + '</td>';
        } else {
            htmlString += '<td style="border: 1px solid #000;padding: 3px;text-align: right; font-weight: bold;">€' + totalAmountWithVAT.setScale(2) + '</td>';
        }
    
        htmlString += '</tr></tbody></table></div>';
    
        output.add(htmlString);
        return output;
    }
}