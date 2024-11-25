public without sharing class RevolutQueueable extends CC_QueueableChain.QueueableWrapper {
    private String orderId;
    private String eventType;

    /**
     * @description RevolutQueueable
     * @param orderId
     * @param eventType
     */
    public RevolutQueueable(String orderId, String eventType) {
        super('RevolutQueueable');
        this.orderId = orderId;
        this.eventType = eventType;

    }

    /**
     * @description work
     */
    public void work() {
        Map<String, Object> params = new Map<String, Object>();
        params.put('orderId', orderId);
        params.put('eventType', eventType);
        System.debug('params: ' + params);
        System.debug('currentUser: ' + UserInfo.getUserEmail());
        Flow.Interview.SFSCH_Post_Payment_Processes RevolutPaymentFlow = new Flow.Interview.SFSCH_Post_Payment_Processes(params);
        if(!Test.isRunningTest()) {
            RevolutPaymentFlow.start();
        }
        System.debug('finuh: ');

    }
}