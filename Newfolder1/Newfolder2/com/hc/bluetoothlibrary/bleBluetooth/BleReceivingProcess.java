/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import android.os.Handler;
/*     */ import android.os.Message;
/*     */ import androidx.annotation.NonNull;
/*     */ import cn.hutool.core.util.ArrayUtil;
/*     */ import com.hc.bluetoothlibrary.tootl.IDataCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.ModuleParameters;
/*     */ import java.util.ArrayList;
/*     */ import java.util.HashMap;
/*     */ import java.util.List;
/*     */ import java.util.Map;
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
/*     */ 
/*     */ public class BleReceivingProcess
/*     */ {
/*     */   private final IDataCallback mIDataCallback;
/*     */   private final BluetoothLeService.DownloadBinder downloadBinder;
/*  30 */   private final Map<String, DataCache> deviceData = new HashMap<>();
/*     */ 
/*     */   
/*     */   private final Handler mCountDownHandler;
/*     */ 
/*     */ 
/*     */   
/*     */   public void splicingData(byte[] bytes, String mac, boolean isFrontDesk) {
/*  38 */     List<byte[]> dataArray = getDataArray(mac);
/*  39 */     this.mCountDownHandler.removeMessages(mac.hashCode());
/*  40 */     dataArray.add(bytes);
/*  41 */     if (isFrontDesk && dataArray.size() == 10) this.mIDataCallback.reading(true); 
/*  42 */     if (dataArray.size() >= ModuleParameters.getBleReadBuff() / bytes.length) {
/*  43 */       if (ModuleParameters.isCheckNewline()) checkNewlineData(mac); 
/*  44 */       dataToPhone(mac);
/*     */     } 
/*     */     
/*  47 */     Message message = this.mCountDownHandler.obtainMessage();
/*  48 */     message.obj = mac;
/*  49 */     message.what = mac.hashCode();
/*  50 */     this.mCountDownHandler.sendMessageDelayed(message, ModuleParameters.getTime() * 3L);
/*     */   }
/*     */   
/*     */   public BleReceivingProcess(BluetoothLeService.DownloadBinder downloadBinder, IDataCallback iDataCallback) {
/*  54 */     this.mCountDownHandler = new Handler(new Handler.Callback()
/*     */         {
/*     */           public boolean handleMessage(@NonNull Message msg) {
/*  57 */             String mac = (String)msg.obj;
/*  58 */             BleReceivingProcess.this.dataToPhone(mac);
/*  59 */             BleReceivingProcess.this.downloadBinder.receiveComplete(mac);
/*  60 */             BleReceivingProcess.this.mIDataCallback.reading(false);
/*  61 */             return false;
/*     */           }
/*     */         });
/*     */     this.mIDataCallback = iDataCallback;
/*     */     this.downloadBinder = downloadBinder;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private synchronized void checkNewlineData(String mac) {
/*  72 */     byte newline = 10;
/*  73 */     int bytePosition = -1;
/*     */ 
/*     */     
/*  76 */     List<byte[]> dataArray = getDataArray(mac);
/*  77 */     List<byte[]> dataBuffArray = getDataBuffArray(mac);
/*     */     int dataPosition;
/*  79 */     for (dataPosition = dataArray.size() - 1; dataPosition >= 0; dataPosition--) {
/*  80 */       bytePosition = ArrayUtil.lastIndexOf(dataArray.get(dataPosition), newline);
/*  81 */       if (bytePosition != -1)
/*     */         break; 
/*     */     } 
/*  84 */     if (bytePosition == -1)
/*  85 */       return;  if (dataPosition == dataArray.size() - 1 && ((byte[])dataArray.get(dataPosition)).length - 1 == bytePosition)
/*     */       return; 
/*  87 */     byte[] retainBytes = new byte[((byte[])dataArray.get(dataPosition)).length - bytePosition - 1];
/*  88 */     byte[] usableBytes = new byte[bytePosition + 1];
/*     */     
/*  90 */     System.arraycopy(dataArray.get(dataPosition), bytePosition + 1, retainBytes, 0, retainBytes.length);
/*  91 */     System.arraycopy(dataArray.get(dataPosition), 0, usableBytes, 0, usableBytes.length);
/*     */     
/*  93 */     dataBuffArray.add(retainBytes);
/*  94 */     if (dataPosition < dataArray.size() - 1)
/*  95 */     { dataBuffArray.addAll(dataArray.subList(dataPosition + 1, dataArray.size()));
/*  96 */       dataArray.subList(dataPosition, dataArray.size()).clear(); }
/*  97 */     else { dataArray.remove(dataArray.size() - 1); }
/*  98 */      dataArray.add(usableBytes);
/*     */   }
/*     */ 
/*     */   
/*     */   private void dataToPhone(String mac) {
/* 103 */     int length = 0;
/* 104 */     List<byte[]> dataArray = getDataArray(mac);
/* 105 */     List<byte[]> dataBuffArray = getDataBuffArray(mac);
/*     */     
/* 107 */     for (byte[] arrayOfByte : dataArray) {
/* 108 */       length += arrayOfByte.length;
/*     */     }
/*     */     
/* 111 */     byte[] bytes = new byte[length];
/* 112 */     int start = 0;
/* 113 */     for (byte[] data : dataArray) {
/* 114 */       System.arraycopy(data, 0, bytes, start, data.length);
/* 115 */       start += data.length;
/*     */     } 
/* 117 */     if (mac != null) this.mIDataCallback.readData((byte[])bytes.clone(), mac); 
/* 118 */     dataArray.clear();
/* 119 */     if (!dataBuffArray.isEmpty()) {
/* 120 */       dataArray.addAll(dataBuffArray);
/* 121 */       dataBuffArray.clear();
/*     */     } 
/*     */   }
/*     */   
/*     */   public synchronized List<byte[]> getDataArray(String mac) {
/* 126 */     DataCache dataCache = this.deviceData.get(mac);
/* 127 */     if (dataCache == null) {
/* 128 */       dataCache = new DataCache();
/* 129 */       this.deviceData.put(mac, dataCache);
/*     */     } 
/* 131 */     return dataCache.dataArray;
/*     */   }
/*     */   
/*     */   public synchronized List<byte[]> getDataBuffArray(String mac) {
/* 135 */     DataCache dataCache = this.deviceData.get(mac);
/* 136 */     if (dataCache == null) {
/* 137 */       dataCache = new DataCache();
/* 138 */       this.deviceData.put(mac, dataCache);
/*     */     } 
/* 140 */     return dataCache.dataBuffArray;
/*     */   }
/*     */   
/*     */   static class DataCache
/*     */   {
/* 145 */     private final List<byte[]> dataArray = (List)new ArrayList<>();
/* 146 */     private final List<byte[]> dataBuffArray = (List)new ArrayList<>();
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\BleReceivingProcess.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */