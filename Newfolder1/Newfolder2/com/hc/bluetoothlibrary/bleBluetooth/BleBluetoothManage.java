/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import android.app.Activity;
/*     */ import android.content.ComponentName;
/*     */ import android.content.Context;
/*     */ import android.content.Intent;
/*     */ import android.content.ServiceConnection;
/*     */ import android.os.Handler;
/*     */ import android.os.IBinder;
/*     */ import android.os.Message;
/*     */ import android.util.Log;
/*     */ import android.widget.Toast;
/*     */ import com.hc.bluetoothlibrary.AllBluetoothManage;
/*     */ import com.hc.bluetoothlibrary.DeviceModule;
/*     */ import com.hc.bluetoothlibrary.IBluetoothStop;
/*     */ import com.hc.bluetoothlibrary.tootl.IDataCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.IScanCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.util.ArrayList;
/*     */ import java.util.List;
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
/*     */ 
/*     */ 
/*     */ 
/*     */ public class BleBluetoothManage
/*     */ {
/*     */   static final int SERVICE_CALLBACK = 0;
/*     */   static final int SERVICE_CONNECT_SUCCEED = 1;
/*     */   static final int SERVICE_CONNECT_FAIL = 2;
/*     */   static final int SERVICE_ERROR_DISCONNECT = 3;
/*     */   static final int SERVICE_SEND_DATA_NUMBER = 4;
/*     */   static final int SERVICE_READ_LOG = 5;
/*     */   static final String MODULE_MAC = "MODULE_MAC";
/*     */   static final String MODULE_FRONT_DESK = "MODULE_FRONT_DESK";
/*     */   static final int SERVICE_READ_VELOCITY = 7;
/*     */   static final int SERVICE_READ_MTU = 8;
/*     */   static final String SERVICE_SEPARATOR = "/**separator**/";
/*     */   private BleScanManage mBleScanManage;
/*  64 */   private final Handler mTimeHandler = new Handler();
/*     */ 
/*     */ 
/*     */   
/*     */   private final Context mContext;
/*     */ 
/*     */ 
/*     */   
/*     */   private BluetoothLeService.DownloadBinder downloadBinder;
/*     */ 
/*     */ 
/*     */   
/*     */   private IDataCallback mIDataCallback;
/*     */ 
/*     */ 
/*     */   
/*     */   private Handler mDataHandler;
/*     */ 
/*     */   
/*     */   private BleReceivingProcess bleReceivingProcess;
/*     */ 
/*     */   
/*     */   private final ServiceConnection connection;
/*     */ 
/*     */ 
/*     */   
/*     */   private void setHandler() {
/*  91 */     this.mDataHandler = new Handler(msg -> {
/*     */           String data; if (this.mIDataCallback == null) {
/*     */             log("mIDataCallback is null", "e");
/*     */             return false;
/*     */           } 
/*     */           switch (msg.what) {
/*     */             case 0:
/*     */               this.bleReceivingProcess.splicingData((byte[])msg.obj, getAddress(msg), isFrontDesk(msg).booleanValue());
/*     */               break;
/*     */             case 1:
/*     */               if (msg.obj instanceof DeviceModule)
/*     */                 this.mIDataCallback.connectionSucceed((DeviceModule)msg.obj); 
/*     */               break;
/*     */             case 2:
/*     */               if (getAddress(msg) != null)
/*     */                 this.mIDataCallback.connectionFail(getAddress(msg), msg.obj.toString()); 
/*     */               log("service connect fail " + getAddress(msg));
/*     */               break;
/*     */             case 3:
/*     */               if (getAddress(msg) != null)
/*     */                 this.mIDataCallback.errorDisconnect(getAddress(msg)); 
/*     */               break;
/*     */             case 4:
/*     */               this.mIDataCallback.readNumber(Integer.parseInt(msg.obj.toString()));
/*     */               break;
/*     */             case 5:
/*     */               data = (String)msg.obj;
/*     */               try {
/*     */                 this.mIDataCallback.readLog(ToolClass.analysis(data, 0, "/**separator**/"), ToolClass.analysis(data, 1, "/**separator**/"), ToolClass.analysis(data, 2, "/**separator**/"));
/* 120 */               } catch (Exception e) {
/*     */                 e.printStackTrace();
/*     */               } 
/*     */               break;
/*     */             case 7:
/*     */               this.mIDataCallback.readVelocity(((Integer)msg.obj).intValue());
/*     */               break;
/*     */             case 8:
/*     */               this.mIDataCallback.callbackMTU(((Integer)msg.obj).intValue());
/*     */               break;
/*     */           } 
/*     */           return false;
/*     */         });
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void scanBluetooth(IScanCallback iScanCallback) {
/* 139 */     this.mBleScanManage.scanBluetooth(iScanCallback);
/*     */   }
/*     */   
/*     */   public void stopScan() {
/* 143 */     this.mBleScanManage.stopScan();
/*     */   }
/*     */ 
/*     */   
/*     */   public void scanBluetooth(List<DeviceModule> list, boolean isStart, IScanCallback iScanCallback) {
/* 148 */     this.mBleScanManage.scanBluetooth(list, isStart, iScanCallback);
/*     */   }
/*     */ 
/*     */   
/*     */   public void connectBluetooth(DeviceModule module, IDataCallback iDataCallback) {
/* 153 */     this.mIDataCallback = iDataCallback;
/* 154 */     log("获取需要连接的MAC: " + module.getDevice().getAddress());
/* 155 */     if (this.downloadBinder != null) {
/* 156 */       log("已有服务，直接连接蓝牙", "w");
/* 157 */       this.downloadBinder.connect(this.mContext, module);
/*     */       return;
/*     */     } 
/* 160 */     Intent serviceInter = new Intent(this.mContext, BluetoothLeService.class);
/* 161 */     this.mContext.bindService(serviceInter, this.connection, 1);
/* 162 */     this.mTimeHandler.postDelayed(() -> { this.downloadBinder.setHandler(this.mDataHandler); this.downloadBinder.connect(this.mContext, module); this.bleReceivingProcess = new BleReceivingProcess(this.downloadBinder, this.mIDataCallback); }300L);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void disConnectBluetooth(String mac) {
/* 171 */     if (this.downloadBinder == null)
/* 172 */       return;  this.downloadBinder.disconnect(mac);
/* 173 */     if (this.downloadBinder.getDevices().size() != 0)
/* 174 */       return;  log("没有连接蓝牙，关闭服务", "w");
/* 175 */     this.downloadBinder = null;
/* 176 */     this.mTimeHandler.postDelayed(() -> {
/*     */           try {
/*     */             this.mContext.unbindService(this.connection);
/* 179 */           } catch (Exception e) {
/*     */             e.printStackTrace();
/*     */           } 
/*     */         }500L);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setBluetoothState(String mac, boolean frontDesk) {
/* 191 */     if (this.downloadBinder != null) this.downloadBinder.setBluetoothState(mac, frontDesk);
/*     */   
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public List<DeviceModule> getConnectedDevices() {
/* 199 */     if (this.downloadBinder == null) return new ArrayList<>(); 
/* 200 */     return this.downloadBinder.getDevices();
/*     */   }
/*     */   
/*     */   public BleBluetoothManage(Context context) {
/* 204 */     this.connection = new ServiceConnection()
/*     */       {
/*     */         public void onServiceConnected(ComponentName name, IBinder service) {
/* 207 */           BleBluetoothManage.this.downloadBinder = (BluetoothLeService.DownloadBinder)service;
/* 208 */           BleBluetoothManage.this.log("绑定服务..");
/*     */         }
/*     */ 
/*     */         
/*     */         public void onServiceDisconnected(ComponentName name) {
/* 213 */           BleBluetoothManage.this.log("onServiceDisconnected"); }
/*     */       };
/*     */     this.mContext = context;
/*     */     init_ble();
/*     */     setHandler(); } private String getAddress(Message msg) {
/* 218 */     String address = null;
/*     */     try {
/* 220 */       address = msg.getData().getString("MODULE_MAC");
/* 221 */     } catch (Exception e) {
/* 222 */       e.printStackTrace();
/*     */     } 
/* 224 */     if (address == null || address.isEmpty()) return null; 
/* 225 */     return address;
/*     */   }
/*     */ 
/*     */   
/*     */   private Boolean isFrontDesk(Message msg) {
/* 230 */     boolean isFrontDesk = false;
/*     */     try {
/* 232 */       isFrontDesk = msg.getData().getBoolean("MODULE_FRONT_DESK");
/* 233 */     } catch (Exception e) {
/* 234 */       e.printStackTrace();
/*     */     } 
/* 236 */     return Boolean.valueOf(isFrontDesk);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setMTU(DeviceModule deviceModule, int mtu) {
/* 244 */     this.downloadBinder.setMTU(deviceModule, mtu);
/*     */   }
/*     */ 
/*     */   
/*     */   public void sendData(DeviceModule device, byte[] data) {
/* 249 */     this.downloadBinder.sendMultiple(device, data);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void stopSend(DeviceModule deviceModule, IBluetoothStop iBluetoothStop) {
/* 257 */     if (this.downloadBinder != null) this.downloadBinder.stopSend(deviceModule, iBluetoothStop); 
/* 258 */     log("停止发送", "w");
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setSendFileVelocity(DeviceModule deviceModule, AllBluetoothManage.SendFileVelocity velocity, int speed) {
/* 266 */     this.downloadBinder.setSendFileVelocity(deviceModule, velocity, speed);
/* 267 */     log("修改发送速率...");
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   private void init_ble() {
/* 273 */     if (!this.mContext.getPackageManager().hasSystemFeature("android.hardware.bluetooth_le")) {
/*     */       
/* 275 */       Toast.makeText(this.mContext, "不支持BLE蓝牙，请退出...", 0).show();
/* 276 */       ((Activity)this.mContext).finish();
/*     */       
/*     */       return;
/*     */     } 
/* 280 */     this.mBleScanManage = new BleScanManage(this.mContext, this.mIDataCallback);
/*     */   }
/*     */   
/*     */   private void log(String str) {
/* 284 */     Log.d("AppRun" + getClass().getSimpleName(), str);
/* 285 */     if (this.mIDataCallback != null) {
/* 286 */       this.mIDataCallback.readLog(getClass().getSimpleName(), str, "d");
/*     */     }
/*     */   }
/*     */   
/*     */   private void log(String str, String v) {
/* 291 */     if (v.equals("w")) {
/* 292 */       Log.w("AppRun" + getClass().getSimpleName(), str);
/* 293 */     } else if (v.equals("e")) {
/* 294 */       Log.e("AppRun" + getClass().getSimpleName(), str);
/*     */     } 
/* 296 */     if (this.mIDataCallback != null && !v.isEmpty()) this.mIDataCallback.readLog(getClass().getSimpleName(), str, v); 
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\BleBluetoothManage.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */