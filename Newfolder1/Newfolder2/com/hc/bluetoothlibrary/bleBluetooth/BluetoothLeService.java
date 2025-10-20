/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import android.app.Service;
/*     */ import android.content.Context;
/*     */ import android.content.Intent;
/*     */ import android.os.Binder;
/*     */ import android.os.Build;
/*     */ import android.os.Handler;
/*     */ import android.os.IBinder;
/*     */ import android.os.Message;
/*     */ import android.util.Log;
/*     */ import com.hc.bluetoothlibrary.AllBluetoothManage;
/*     */ import com.hc.bluetoothlibrary.DeviceModule;
/*     */ import com.hc.bluetoothlibrary.IBluetoothStop;
/*     */ import com.hc.bluetoothlibrary.tootl.ModuleParameters;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import com.hc.bluetoothlibrary.tootl.VelocityCorrection;
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
/*     */ public class BluetoothLeService
/*     */   extends Service
/*     */ {
/*     */   private Handler mHandler;
/*  34 */   private final DownloadBinder mBinder = new DownloadBinder();
/*     */   
/*  36 */   private int mMTU = 20;
/*     */   
/*  38 */   private AllBluetoothManage.SendFileVelocity mSendFileVelocity = AllBluetoothManage.SendFileVelocity.LOW;
/*     */   
/*  40 */   private final Map<String, BleGattCallbackRealize> mDevicesGatt = new HashMap<>();
/*     */   
/*     */   class DownloadBinder
/*     */     extends Binder
/*     */   {
/*     */     void setHandler(Handler handler) {
/*  46 */       if (BluetoothLeService.this.mHandler == null) BluetoothLeService.this.mHandler = handler; 
/*  47 */       BluetoothLeService.this.log("服务创建成功");
/*     */     }
/*     */ 
/*     */     
/*     */     List<DeviceModule> getDevices() {
/*  52 */       List<DeviceModule> list = new ArrayList<>();
/*  53 */       for (String mac : BluetoothLeService.this.mDevicesGatt.keySet()) {
/*  54 */         BleGattCallbackRealize realize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(mac);
/*  55 */         if (realize == null)
/*  56 */           continue;  realize.getDevice().setConnected(true);
/*  57 */         list.add(realize.getDevice());
/*     */       } 
/*  59 */       return list;
/*     */     }
/*     */     
/*     */     void connect(Context context, DeviceModule device) {
/*  63 */       if (BluetoothLeService.this.mDevicesGatt.get(device.getMac()) != null)
/*  64 */         return;  BluetoothLeService.this.log("连接..");
/*     */       
/*  66 */       BleGattCallbackRealize bleGattCallbackRealize = new BleGattCallbackRealize(context, BluetoothLeService.this, BluetoothLeService.this.mHandler);
/*     */       
/*  68 */       if (Build.VERSION.SDK_INT >= 26) {
/*  69 */         if (ToolClass.checkPermission(context)) {
/*  70 */           device.getDevice().connectGatt(context, false, bleGattCallbackRealize, 2, 2);
/*     */         }
/*  72 */       } else if (Build.VERSION.SDK_INT >= 23) {
/*  73 */         device.getDevice().connectGatt(context, false, bleGattCallbackRealize, 2);
/*     */       } else {
/*  75 */         device.getDevice().connectGatt(context, false, bleGattCallbackRealize);
/*     */       } 
/*  77 */       bleGattCallbackRealize.setDeiceModule(device);
/*  78 */       BluetoothLeService.this.mDevicesGatt.put(device.getMac(), bleGattCallbackRealize);
/*     */     }
/*     */     
/*     */     void setMTU(DeviceModule device, int mtu) {
/*  82 */       BleGattCallbackRealize bleGattCallbackRealize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(device.getMac());
/*  83 */       if (bleGattCallbackRealize != null) bleGattCallbackRealize.setMTU(mtu); 
/*     */     }
/*     */     
/*     */     synchronized void sendMultiple(DeviceModule device, byte[] data) {
/*  87 */       BleGattCallbackRealize bleGattCallbackRealize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(device.getMac());
/*  88 */       if (bleGattCallbackRealize != null) bleGattCallbackRealize.sendMultiple(data);
/*     */     
/*     */     }
/*     */ 
/*     */     
/*     */     void receiveComplete(String mac) {
/*  94 */       BleGattCallbackRealize bleGattCallbackRealize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(mac);
/*  95 */       if (bleGattCallbackRealize != null) bleGattCallbackRealize.receiveComplete(); 
/*     */     }
/*     */     
/*     */     void stopSend(DeviceModule device, IBluetoothStop iBluetoothStop) {
/*  99 */       BleGattCallbackRealize bleGattCallbackRealize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(device.getMac());
/* 100 */       if (bleGattCallbackRealize != null) bleGattCallbackRealize.stopSend(iBluetoothStop);
/*     */     
/*     */     }
/*     */     
/*     */     void disconnect(String mac) {
/* 105 */       BleGattCallbackRealize bleGattCallbackRealize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(mac);
/* 106 */       if (bleGattCallbackRealize != null) bleGattCallbackRealize.disconnect(); 
/* 107 */       BluetoothLeService.this.mDevicesGatt.remove(mac);
/*     */     }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */     
/*     */     void setSendFileVelocity(DeviceModule deviceModule, AllBluetoothManage.SendFileVelocity velocity, int speed) {
/* 117 */       BluetoothLeService.this.mSendFileVelocity = velocity;
/* 118 */       setMTU(deviceModule, 512);
/* 119 */       BluetoothLeService.this.mHandler.postDelayed(() -> BluetoothLeService.this.setSendVelocity(deviceModule, speed), 500L);
/*     */     }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */     
/*     */     void setBluetoothState(String mac, boolean frontDesk) {
/* 128 */       for (String moduleMac : BluetoothLeService.this.mDevicesGatt.keySet()) {
/* 129 */         BleGattCallbackRealize realize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(moduleMac);
/* 130 */         if (realize != null) realize.setShowExtras(false);
/*     */       
/*     */       } 
/* 133 */       if (!frontDesk)
/*     */         return; 
/* 135 */       BleGattCallbackRealize bleGattCallbackRealize = (BleGattCallbackRealize)BluetoothLeService.this.mDevicesGatt.get(mac);
/* 136 */       if (bleGattCallbackRealize != null) bleGattCallbackRealize.setShowExtras(true);
/*     */     
/*     */     }
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void setSendVelocity(DeviceModule device, int speed) {
/*     */     int delayed;
/* 146 */     BleGattCallbackRealize bleGattCallbackRealize = this.mDevicesGatt.get(device.getMac());
/* 147 */     if (bleGattCallbackRealize != null) this.mMTU = bleGattCallbackRealize.getMTU(); 
/* 148 */     switch (this.mSendFileVelocity) {
/*     */       
/*     */       case LOW:
/* 151 */         ModuleParameters.setSendFileDelayedTime(this.mMTU);
/*     */         break;
/*     */       case HEIGHT:
/* 154 */         delayed = this.mMTU / 10;
/* 155 */         ModuleParameters.setSendFileDelayedTime(delayed);
/*     */         break;
/*     */       case SUPER:
/* 158 */         delayed = this.mMTU / 25;
/* 159 */         ModuleParameters.setSendFileDelayedTime(delayed);
/*     */         break;
/*     */       case MAX:
/* 162 */         ModuleParameters.setSendFileDelayedTime(0);
/*     */         break;
/*     */       case CUSTOM:
/* 165 */         VelocityCorrection.setGather();
/* 166 */         ModuleParameters.setSendFileDelayedTime(getDelayedTime(speed));
/*     */         break;
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private int getDelayedTime(int speed) {
/* 177 */     return Math.max(this.mMTU / speed - 3, 0);
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public IBinder onBind(Intent intent) {
/* 183 */     return (IBinder)this.mBinder;
/*     */   }
/*     */ 
/*     */   
/*     */   public void onCreate() {
/* 188 */     super.onCreate();
/* 189 */     log("开启服务..");
/*     */   }
/*     */ 
/*     */   
/*     */   public void onDestroy() {
/* 194 */     super.onDestroy();
/* 195 */     log("服务关闭..");
/*     */   }
/*     */ 
/*     */   
/*     */   private void sendLog(String data, String lv) {
/* 200 */     if (this.mHandler == null)
/* 201 */       return;  String str = "/**separator**/";
/* 202 */     Message message = this.mHandler.obtainMessage();
/* 203 */     message.what = 5;
/* 204 */     message.obj = getClass().getSimpleName() + str + data + str + lv + str;
/* 205 */     this.mHandler.sendMessage(message);
/*     */   }
/*     */ 
/*     */   
/*     */   public void log(String str) {
/* 210 */     Log.d("AppRunService", str);
/* 211 */     sendLog(str, "d");
/*     */   }
/*     */   public void log(String str, String e) {
/* 214 */     if (e.equals("i")) {
/* 215 */       Log.e("AppRunService", str);
/*     */       return;
/*     */     } 
/* 218 */     if (e.equals("e")) {
/* 219 */       Log.e("AppRunService", str);
/*     */     } else {
/* 221 */       Log.w("AppRunService", str);
/*     */     } 
/* 223 */     sendLog(str, e);
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\BluetoothLeService.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */