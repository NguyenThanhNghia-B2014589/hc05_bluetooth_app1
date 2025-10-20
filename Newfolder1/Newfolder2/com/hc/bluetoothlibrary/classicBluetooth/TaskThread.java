/*    */ package com.hc.bluetoothlibrary.classicBluetooth;
/*    */ 
/*    */ import android.os.Handler;
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ public class TaskThread
/*    */ {
/*    */   private WorkCallBack call;
/*    */   private final Handler handler;
/*    */   
/*    */   public TaskThread(Handler handler) {
/* 19 */     this.handler = handler;
/*    */   }
/*    */   
/*    */   public void setWorkCall(WorkCallBack call) {
/* 23 */     this.call = call;
/* 24 */     start();
/*    */   }
/*    */   
/*    */   private void start() {
/* 28 */     (new Thread(() -> {
/*    */           if (this.call != null) {
/*    */             boolean b;
/*    */             
/*    */             try {
/*    */               b = this.call.work();
/* 34 */             } catch (Exception e) {
/*    */               this.handler.post(());
/*    */               e.printStackTrace();
/*    */               return;
/*    */             } 
/*    */             if (b) {
/*    */               this.handler.post(());
/*    */             }
/*    */           } 
/* 43 */         })).start();
/*    */   }
/*    */   
/*    */   public static interface WorkCallBack {
/*    */     void succeed();
/*    */     
/*    */     boolean work() throws Exception;
/*    */     
/*    */     void error(Exception param1Exception);
/*    */   }
/*    */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\classicBluetooth\TaskThread.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */