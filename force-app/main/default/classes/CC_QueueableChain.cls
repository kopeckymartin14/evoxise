/**************************************************************************************************
* Name               : CC_QueueableChain 
* Description        : Queueable framwork for asynchronous callouts   
* Test Class         : CC_QueueableChainTest     
* Created Date       : 18/04/2024                                                                  
* Created By         : Martin Kopecky                                                            
*
*Modification LOG
*   ----------------------------------------------------------------------------------------------
*   Who         Reviewer            When               What
*   ----------------------------------------------------------------------------------------------
*   Martin      Juraj Kopecky       18/04/2024         Initial Version
*                                                     
**************************************************************************************************/
/**
 * @description Queueable framwork for asynchronous callouts 
 */
 public with sharing class CC_QueueableChain {
    @TestVisible
    private static QueueableChain currentChain = new QueueableChain();

    
    /**
     * @description //enqueue job to chain
     * @param queueable
     */
    public static void enqueue(Queueable queueable) {
        if (System.isQueueable()) {
            currentChain.add(queueable);
        } else {
            QueueableChain chain = new QueueableChain();
            chain.add(queueable);
            chain.commitQueue();
        }
    }
    
    /**
     * @description //enqueue job to chain
     * @param queueableList
     */
    public static void enqueueList(List<Queueable> queueableList) {
        if (System.isQueueable()) {
            for(Queueable q : queueableList) {
                currentChain.add(q);
            }
        } else {
            QueueableChain chain = new QueueableChain();
            for(Queueable q : queueableList) {
                chain.add(q);
            }
            chain.commitQueue();
        }
    }

    
    /**
     * @description //Sub class implements Queueable
     */
    public class QueueableChain implements Queueable, Database.AllowsCallouts {
        @TestVisible
        private List<Queueable> chain = new List<Queueable>();
        @TestVisible
        private Queueable currentJob;

        
        /**
         * @description //execute queueable callouts
         * @param ctx
         */
        public void execute(QueueableContext ctx) {
            if (!this.chain.isEmpty()) {
                for (Queueable job : this.chain) {
                    enqueue(job);
                }
            }

            if (this.currentJob == null) {
                return;
            }

            this.currentJob.execute(ctx);
        }

        
        /**
         * @description //add job to chain
         * @param queueable
         */
        public void add(Queueable queueable) {
            if (this.currentJob == null) {
                this.currentJob = queueable;
            } else {
                this.chain.add(queueable);
            }
        }

      
        /**
         * @description   //commit method to the Queue
         */
        public void commitQueue() {
            if (!Test.isRunningTest()) {
                System.enqueueJob(this);
            }
        }
    }

    //Queueable Wrapper
    /**
     * @description subclass QueueableWrapper
     */
    public abstract class QueueableWrapper implements Queueable, Database.AllowsCallouts {
        public String name;
        /**
         * @description QueueableWrapper
         * @param name
         */
        public QueueableWrapper(String name) {
            this.name = name;
        }

        abstract void work();

        //execute
        /**
         * @description execute
         * @param ctx
         */
        public void execute(QueueableContext ctx) {
            this.work();
            currentChain.commitQueue();
        }
    }
}