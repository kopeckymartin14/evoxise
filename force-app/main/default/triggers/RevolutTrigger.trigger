/**
 * Created by Martin Kopecky on 27.07.2024.
 */

 trigger RevolutTrigger on Revolut_Event__e (after insert) {

    for(Revolut_Event__e e : Trigger.new) {

        // Map<String, Object> params = new Map<String, Object>();
        // params.put('orderId', e.Order_Id__c);
        // params.put('eventType', e.Event_Type__c);
        // params.put('appointmentIds', new List<String>());
        // System.debug('params: ' + params);

        System.debug('e.Order_Id__c: ' + e.Order_Id__c);
        System.debug('e.Event_Type__c: ' + e.Event_Type__c);
        CC_QueueableChain.enqueue(new RevolutQueueable(e.Order_Id__c, e.Event_Type__c));

        // Flow.Interview.SFSCH_Post_Payment_Processes RevolutPaymentFlow = new Flow.Interview.SFSCH_Post_Payment_Processes(params);
        // RevolutPaymentFlow.start();
    }
}