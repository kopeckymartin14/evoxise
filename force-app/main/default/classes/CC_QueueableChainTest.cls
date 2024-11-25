/**
 * Created by Martin Kopecky on 18.04.2024.
 */

 @IsTest
 private class CC_QueueableChainTest {
     @IsTest
     static void testBehavior() {
         CC_QueueableChain.QueueableChain chain = new CC_QueueableChain.QueueableChain();
         chain.add(new Wrapper('Tst'));
         chain.add(new Wrapper('Tst2'));
         Test.startTest();
         Queueable q1 = new Wrapper('Tst');
         CC_QueueableChain.enqueue(new Wrapper('Tst'));
         CC_QueueableChain.enqueueList(new List<Queueable> { new Wrapper('Tst'), new Wrapper('Tst2') });
         q1.execute(null);
         chain.execute(null);
         Test.stopTest();
     }
 
     public class Wrapper extends CC_QueueableChain.QueueableWrapper {
         public Wrapper(String name) {
             super(name);
         }
         public void work() {
             System.debug('QueueableWrapper.work()');
         }
     }
 }