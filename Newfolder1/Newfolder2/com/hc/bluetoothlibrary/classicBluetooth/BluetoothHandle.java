/*     */ package com.hc.bluetoothlibrary.classicBluetooth;
/*     */ 
/*     */ import android.app.Activity;
/*     */ import android.bluetooth.BluetoothSocket;
/*     */ import android.content.Context;
/*     */ import android.util.Log;
/*     */ import android.widget.Toast;
/*     */ import cn.hutool.core.util.ArrayUtil;
/*     */ import com.hc.bluetoothlibrary.DeviceModule;
/*     */ import com.hc.bluetoothlibrary.tootl.IDataCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.ModuleParameters;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.io.IOException;
/*     */ import java.io.InputStream;
/*     */ import java.io.OutputStream;
/*     */ import java.io.PrintWriter;
/*     */ import java.io.StringWriter;
/*     */ import java.io.Writer;
/*     */ import java.util.Arrays;
/*     */ import java.util.Timer;
/*     */ import java.util.TimerTask;
/*     */ import java.util.UUID;
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
/*     */ 
/*     */ public class BluetoothHandle
/*     */ {
/*     */   private boolean isShowExtras = true;
/*     */   private final String bluetoothMac;
/*     */   private final BluetoothSocket bluetoothSocket;
/*     */   private OutputStream outputBluetooth;
/*     */   private InputStream inputBluetooth;
/*     */   private boolean mIsWork = false;
/*     */   private final IDataCallback mIDataCallback;
/*     */   private Thread listenerThread;
/*     */   private final Context context;
/*  46 */   private byte[] mCacheBytes = null;
/*     */   
/*     */   private final DeviceModule mDeviceModule;
/*     */   
/*     */   private Timer mTimer;
/*     */   
/*     */   private TimerTask mTimerTask;
/*  53 */   private int mSectionNumber = 0;
/*     */   
/*     */   public BluetoothHandle(Context context, DeviceModule device, IDataCallback iDataCallback) throws Exception {
/*  56 */     this.context = context;
/*  57 */     this.bluetoothMac = device.getMac();
/*  58 */     this.mIDataCallback = iDataCallback;
/*  59 */     this.mDeviceModule = device;
/*  60 */     if (!ToolClass.checkPermission(context)) throw new RuntimeException("错误: 没有Android13的蓝牙权限"); 
/*  61 */     this.bluetoothSocket = device.getDevice().createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"));
/*     */   }
/*     */ 
/*     */   
/*     */   public boolean setBluetoothStream() {
/*     */     try {
/*  67 */       this.outputBluetooth = this.bluetoothSocket.getOutputStream();
/*  68 */     } catch (IOException e) {
/*  69 */       Toast.makeText(this.context, "设置发送失败!", 0).show();
/*  70 */       e.printStackTrace();
/*  71 */       return false;
/*     */     } 
/*     */     
/*     */     try {
/*  75 */       this.inputBluetooth = this.bluetoothSocket.getInputStream();
/*  76 */       this.mIsWork = true;
/*  77 */       setBluetoothListener();
/*  78 */       log("成功设置监听流...");
/*  79 */     } catch (IOException e) {
/*  80 */       Toast.makeText(this.context, "设置接收失败!!", 0).show();
/*  81 */       e.printStackTrace();
/*  82 */       return false;
/*     */     } 
/*  84 */     return true;
/*     */   }
/*     */   
/*     */   public DeviceModule getDeviceModule() {
/*  88 */     return this.mDeviceModule;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void setBluetoothListener() {
/*  95 */     this.listenerThread = new Thread(() -> {
/*     */           int arrayLength = ModuleParameters.getClassicReadBuff(); byte[] bytes = new byte[arrayLength]; byte[] dataByte = null;
/*     */           while (this.mIsWork) {
/*     */             if (bytes.length != ModuleParameters.getClassicReadBuff())
/*     */               bytes = new byte[ModuleParameters.getClassicReadBuff()]; 
/*     */             if (this.inputBluetooth != null) {
/*     */               try {
/*     */                 if (this.inputBluetooth.available() != 0) {
/*     */                   while (true) {
/*     */                     int length = this.inputBluetooth.read(bytes);
/*     */                     if (this.isShowExtras)
/*     */                       accessRate(length); 
/*     */                     int temp = lengthArray(dataByte);
/*     */                     if (temp > 200 && this.isShowExtras)
/*     */                       this.mIDataCallback.reading(true); 
/*     */                     if (arrayLength - temp < length && dataByte != null) {
/*     */                       if (ModuleParameters.isCheckNewline())
/*     */                         dataByte = checkNewline(dataByte); 
/*     */                       dataSubmitted(dataByte, null);
/*     */                       dataByte = null;
/*     */                     } 
/*     */                     if (this.mCacheBytes != null) {
/*     */                       dataByte = addByteArray(dataByte, this.mCacheBytes, this.mCacheBytes.length);
/*     */                       this.mCacheBytes = null;
/*     */                     } 
/*     */                     dataByte = addByteArray(dataByte, bytes, length);
/*     */                     clearArray(bytes);
/*     */                     delayed(ModuleParameters.getTime());
/*     */                     if (this.inputBluetooth.available() == 0) {
/*     */                       dataSubmitted(dataByte, bytes);
/*     */                       dataByte = null;
/*     */                       break;
/*     */                     } 
/*     */                   } 
/*     */                   if (this.isShowExtras) {
/*     */                     this.mIDataCallback.reading(false);
/*     */                     stopAccessRate();
/*     */                   } 
/*     */                 } 
/* 134 */               } catch (Exception e) {
/*     */                 e.printStackTrace();
/*     */               } 
/*     */             }
/*     */           } 
/*     */         });
/* 140 */     this.listenerThread.start();
/*     */   }
/*     */ 
/*     */   
/*     */   public void close() {
/* 145 */     this.mIsWork = false;
/* 146 */     closeThread();
/*     */     try {
/* 148 */       if (this.outputBluetooth != null) this.outputBluetooth.close(); 
/* 149 */       this.outputBluetooth = null;
/*     */       
/* 151 */       if (this.inputBluetooth != null) this.inputBluetooth.close(); 
/* 152 */       this.inputBluetooth = null;
/*     */       
/* 154 */       if (this.bluetoothSocket != null) this.bluetoothSocket.close();
/*     */       
/* 156 */       log("成功断开蓝牙");
/* 157 */     } catch (IOException e) {
/* 158 */       log("断开蓝牙失败...", "e");
/* 159 */       e.printStackTrace();
/* 160 */       Writer w = new StringWriter();
/* 161 */       e.printStackTrace(new PrintWriter(w));
/* 162 */       log("断开蓝牙失败：" + w, "e");
/*     */     } finally {
/*     */       try {
/* 165 */         if (this.bluetoothSocket != null) {
/* 166 */           this.bluetoothSocket.close();
/*     */         }
/* 168 */       } catch (Exception e) {
/* 169 */         e.printStackTrace();
/*     */       } 
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   private void closeThread() {
/* 176 */     if (this.listenerThread != null) this.listenerThread.interrupt(); 
/* 177 */     this.listenerThread = null;
/* 178 */     log("关闭线程..");
/*     */   }
/*     */   
/*     */   public BluetoothSocket getBluetoothSocket() {
/* 182 */     return this.bluetoothSocket;
/*     */   }
/*     */   
/*     */   public OutputStream getOutputBluetooth() {
/* 186 */     return this.outputBluetooth;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public boolean isShowExtras() {
/* 193 */     return this.isShowExtras;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setShowExtras(boolean isShowExtras) {
/* 200 */     this.isShowExtras = isShowExtras;
/*     */   }
/*     */   
/*     */   private void clearArray(byte[] as) {
/* 204 */     Arrays.fill(as, (byte)0);
/*     */   }
/*     */   
/*     */   private int lengthArray(byte[] as) {
/* 208 */     if (as == null) return 0; 
/* 209 */     return as.length;
/*     */   }
/*     */   
/*     */   private byte[] addByteArray(byte[] byte_1, byte[] byte_2, int length) {
/* 213 */     int buffLength = 0;
/* 214 */     if (byte_1 != null) buffLength = byte_1.length; 
/* 215 */     byte[] byte_3 = new byte[buffLength + length];
/*     */     
/* 217 */     if (byte_1 != null) System.arraycopy(byte_1, 0, byte_3, 0, byte_1.length);
/*     */     
/* 219 */     System.arraycopy(byte_2, 0, byte_3, buffLength, length);
/* 220 */     return byte_3;
/*     */   }
/*     */ 
/*     */   
/*     */   private void delayed(int ms) throws Exception {
/* 225 */     for (int i = 0; i < ms; i++) {
/* 226 */       Thread.sleep(1L);
/* 227 */       if (this.inputBluetooth.available() != 0)
/*     */         return; 
/*     */     } 
/*     */   }
/*     */   private byte[] checkNewline(byte[] dataBytes) {
/* 232 */     byte newline = 10;
/* 233 */     int position = ArrayUtil.lastIndexOf(dataBytes, newline);
/* 234 */     if (position == -1) return dataBytes;
/*     */ 
/*     */     
/* 237 */     byte[] usableBytes = new byte[position + 1];
/* 238 */     this.mCacheBytes = new byte[dataBytes.length - position - 1];
/*     */     
/* 240 */     System.arraycopy(dataBytes, 0, usableBytes, 0, usableBytes.length);
/* 241 */     System.arraycopy(dataBytes, position + 1, this.mCacheBytes, 0, this.mCacheBytes.length);
/*     */     
/* 243 */     return usableBytes;
/*     */   }
/*     */ 
/*     */   
/*     */   private void accessRate(int length) {
/* 248 */     if (this.mTimerTask == null) {
/* 249 */       this.mTimerTask = new TimerTask()
/*     */         {
/*     */           public void run() {
/* 252 */             ((Activity)BluetoothHandle.this.context).runOnUiThread(() -> {
/*     */                   BluetoothHandle.this.mIDataCallback.readVelocity(BluetoothHandle.this.mSectionNumber * 5);
/*     */                   BluetoothHandle.this.mSectionNumber = 0;
/*     */                 });
/*     */           }
/*     */         };
/* 258 */       if (this.mTimer == null) this.mTimer = new Timer(); 
/* 259 */       this.mTimer.schedule(this.mTimerTask, 200L, 200L);
/*     */     } 
/* 261 */     this.mSectionNumber += length;
/*     */   }
/*     */ 
/*     */   
/*     */   private void stopAccessRate() {
/* 266 */     if (this.mTimerTask != null) this.mTimerTask.cancel(); 
/* 267 */     this.mTimerTask = null;
/* 268 */     this.mSectionNumber = 0;
/*     */   }
/*     */   
/*     */   private void dataSubmitted(byte[] bytes_1, byte[] bytes_2) {
/* 272 */     updateUi((byte[])bytes_1.clone());
/* 273 */     if (bytes_2 != null) clearArray(bytes_2);
/*     */   
/*     */   }
/*     */   
/*     */   private void updateUi(byte[] data) {
/* 278 */     if (this.mIDataCallback != null) {
/* 279 */       ((Activity)this.context).runOnUiThread(() -> this.mIDataCallback.readData(data, this.bluetoothMac));
/*     */     }
/*     */   }
/*     */ 
/*     */   
/*     */   private void log(String str) {
/* 285 */     Log.d(getClass().getSimpleName() + "," + this.bluetoothMac, str);
/* 286 */     if (this.mIDataCallback != null) {
/* 287 */       this.mIDataCallback.readLog(getClass().getSimpleName() + "," + this.bluetoothMac, str, "d");
/*     */     }
/*     */   }
/*     */ 
/*     */   
/*     */   private void log(String str, String lv) {
/* 293 */     if (lv.equals("e")) {
/* 294 */       Log.e(getClass().getSimpleName() + "," + this.bluetoothMac, str);
/*     */     } else {
/* 296 */       Log.w(getClass().getSimpleName() + "," + this.bluetoothMac, str);
/*     */     } 
/* 298 */     if (this.mIDataCallback != null)
/* 299 */       this.mIDataCallback.readLog(getClass().getSimpleName() + "," + this.bluetoothMac, str, lv); 
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\classicBluetooth\BluetoothHandle.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */