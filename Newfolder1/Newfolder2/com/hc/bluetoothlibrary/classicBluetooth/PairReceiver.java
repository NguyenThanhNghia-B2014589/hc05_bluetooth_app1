/*     */ package com.hc.bluetoothlibrary.classicBluetooth;
/*     */ 
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.content.BroadcastReceiver;
/*     */ import android.content.Context;
/*     */ import android.content.Intent;
/*     */ import android.os.Build;
/*     */ import android.util.Log;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.util.Timer;
/*     */ import java.util.TimerTask;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class PairReceiver
/*     */   extends BroadcastReceiver
/*     */ {
/*     */   private static final String mBluetoothPin = "1234";
/*     */   private PairCallback mCallback;
/*     */   private final Context mContent;
/*  29 */   private int mLoopNumber = 0;
/*  30 */   private final String mClassName = getClass().getSimpleName();
/*     */   
/*     */   public PairReceiver(Context context, PairCallback callback) {
/*  33 */     this.mCallback = callback;
/*  34 */     this.mContent = context;
/*     */   }
/*     */ 
/*     */   
/*     */   public void onReceive(Context context, Intent intent) {
/*  39 */     if (intent == null)
/*     */       return; 
/*  41 */     String action = intent.getAction();
/*  42 */     if (action != null && action.equals("android.bluetooth.device.action.PAIRING_REQUEST")) {
/*  43 */       final BluetoothDevice bluetoothDevice = (BluetoothDevice)intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
/*  44 */       Log.d("AppRun" + this.mClassName, "接收到广播");
/*  45 */       abortBroadcast();
/*  46 */       if (bluetoothDevice == null) {
/*  47 */         Log.e("AppRun" + this.mClassName, "bluetoothDevice is null !!");
/*     */         return;
/*     */       } 
/*     */       try {
/*  51 */         if (Build.VERSION.SDK_INT >= 19) {
/*  52 */           if (ToolClass.checkPermission(this.mContent)) {
/*  53 */             bluetoothDevice.setPin("1234".getBytes());
/*     */           }
/*     */         } else {
/*  56 */           ClsUtils.setPin((Class)bluetoothDevice.getClass(), bluetoothDevice, "1234");
/*     */         } 
/*  58 */       } catch (Exception e) {
/*  59 */         e.printStackTrace();
/*     */       } 
/*     */       
/*  62 */       final Timer timer = new Timer();
/*     */       
/*  64 */       final TimerTask taskIsBond = new TimerTask()
/*     */         {
/*     */           public void run() {
/*  67 */             Log.w("AppRun" + PairReceiver.this.mClassName, "Bluetooth bond state is none,connect bluetooth");
/*  68 */             if (PairReceiver.this.mCallback != null) {
/*     */               try {
/*  70 */                 PairReceiver.this.mCallback.connect();
/*  71 */               } catch (Exception e) {
/*  72 */                 e.printStackTrace();
/*     */               } 
/*     */             }
/*     */           }
/*     */         };
/*     */       
/*  78 */       TimerTask taskCloseRadio = new TimerTask()
/*     */         {
/*     */           public void run() {
/*  81 */             PairReceiver.this.mLoopNumber++;
/*  82 */             boolean bondState = (ToolClass.checkPermission(PairReceiver.this.mContent) && bluetoothDevice.getBondState() == 10);
/*  83 */             Log.d("AppRun" + PairReceiver.this.mClassName, "loop,device bond state is " + bluetoothDevice.getBondState());
/*  84 */             if (PairReceiver.this.mLoopNumber == 8 || bondState) {
/*     */               try {
/*  86 */                 cancel();
/*  87 */                 PairReceiver.this.mContent.unregisterReceiver(PairReceiver.this);
/*  88 */               } catch (Exception e) {
/*  89 */                 e.printStackTrace();
/*     */               } 
/*  91 */               Log.w("AppRun" + PairReceiver.this.mClassName, "Close broadcast,delayed 500 ms,connect bluetooth");
/*  92 */               timer.schedule(taskIsBond, 500L);
/*     */               return;
/*     */             } 
/*  95 */             if (bluetoothDevice.getBondState() == 12 && PairReceiver.this.mCallback != null) {
/*     */               try {
/*  97 */                 Log.d("AppRun" + PairReceiver.this.mClassName, "Close broadcast, bluetooth bond state is bonded (success)");
/*  98 */                 PairReceiver.this.mCallback.connect();
/*  99 */                 PairReceiver.this.mContent.unregisterReceiver(PairReceiver.this);
/* 100 */                 PairReceiver.this.mCallback = null;
/* 101 */                 cancel();
/* 102 */               } catch (Exception e) {
/* 103 */                 e.printStackTrace();
/*     */               } 
/*     */             }
/*     */           }
/*     */         };
/* 108 */       timer.schedule(taskCloseRadio, 300L, 200L);
/*     */     } 
/*     */   }
/*     */   
/*     */   public static interface PairCallback {
/*     */     void connect() throws Exception;
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\classicBluetooth\PairReceiver.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */