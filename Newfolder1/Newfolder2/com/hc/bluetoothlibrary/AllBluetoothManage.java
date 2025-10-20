/*     */ package com.hc.bluetoothlibrary;
/*     */ 
/*     */ import android.app.Activity;
/*     */ import android.content.Context;
/*     */ import android.os.Handler;
/*     */ import android.util.Log;
/*     */ import com.hc.bluetoothlibrary.bleBluetooth.BleBluetoothManage;
/*     */ import com.hc.bluetoothlibrary.classicBluetooth.ClassicBluetoothManage;
/*     */ import com.hc.bluetoothlibrary.tootl.IDataCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.IScanCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.ModuleParameters;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.util.ArrayList;
/*     */ import java.util.List;
/*     */ 
/*     */ 
/*     */ 
/*     */ public class AllBluetoothManage
/*     */ {
/*     */   private final Context mContext;
/*     */   private final ClassicBluetoothManage mClassicManage;
/*     */   private final BleBluetoothManage mBleManage;
/*  23 */   private final List<DeviceModule> mClassicBluetoothArray = new ArrayList<>(); private IDataCallback mIDataCallback;
/*  24 */   private final List<DeviceModule> mScanAllModuleArray = new ArrayList<>();
/*     */   private final IBluetooth mIBluetooth;
/*     */   
/*     */   private enum State {
/*  28 */     refresh, leisure; }
/*  29 */   private State mState = State.leisure;
/*     */   
/*     */   private boolean mUpdateTheLimit = false;
/*  32 */   private final Handler mTimeHandler = new Handler();
/*     */   
/*  34 */   public enum SendFileVelocity { LOW, HEIGHT, SUPER, MAX, CUSTOM; }
/*     */   
/*     */   public AllBluetoothManage(Context context, IBluetooth iBluetooth) {
/*  37 */     this.mContext = context;
/*  38 */     this.mClassicManage = new ClassicBluetoothManage(context);
/*  39 */     this.mBleManage = new BleBluetoothManage(context);
/*  40 */     this.mIBluetooth = iBluetooth;
/*  41 */     ModuleParameters.init(context);
/*  42 */     setIDataCallback();
/*     */   }
/*     */ 
/*     */   
/*     */   public boolean mixScan() {
/*  47 */     if (this.mState == State.refresh) return false; 
/*  48 */     this.mState = State.refresh;
/*  49 */     this.mClassicBluetoothArray.clear();
/*  50 */     this.mClassicManage.scanBluetooth(new IScanCallback()
/*     */         {
/*     */           public void stopScan()
/*     */           {
/*  54 */             AllBluetoothManage.this.log("classic扫描结束", "w");
/*     */             
/*  56 */             AllBluetoothManage.this.testMessyCode();
/*     */           }
/*     */ 
/*     */ 
/*     */           
/*     */           public void updateRecycler(DeviceModule deviceModule) {
/*  62 */             if (deviceModule != null) AllBluetoothManage.this.mClassicBluetoothArray.add(deviceModule); 
/*  63 */             AllBluetoothManage.this.callbackActivity(deviceModule, false);
/*     */           }
/*     */         });
/*  66 */     return true;
/*     */   }
/*     */ 
/*     */   
/*     */   public boolean bleScan() {
/*  71 */     if (this.mState == State.refresh) return false; 
/*  72 */     this.mState = State.refresh;
/*  73 */     this.mBleManage.scanBluetooth(new IScanCallback()
/*     */         {
/*     */           public void stopScan() {
/*  76 */             AllBluetoothManage.this.log("ble扫描结束", "w");
/*  77 */             AllBluetoothManage.this.mIBluetooth.updateEnd();
/*  78 */             AllBluetoothManage.this.mState = AllBluetoothManage.State.leisure;
/*     */           }
/*     */ 
/*     */           
/*     */           public void updateRecycler(DeviceModule deviceModule) {
/*  83 */             AllBluetoothManage.this.callbackActivity(deviceModule, true);
/*     */           }
/*     */         });
/*  86 */     return true;
/*     */   }
/*     */   
/*     */   public void stopScan() {
/*     */     try {
/*  91 */       this.mIBluetooth.updateEnd();
/*  92 */       this.mClassicManage.stopScan();
/*  93 */       this.mBleManage.stopScan();
/*  94 */     } catch (Exception e) {
/*  95 */       e.printStackTrace();
/*     */     } finally {
/*  97 */       this.mState = State.leisure;
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void connect(DeviceModule deviceModule) {
/* 106 */     stopScan();
/*     */     
/* 108 */     if (deviceModule.isBLE()) {
/* 109 */       log("进入ble的连接方式", "w");
/* 110 */       this.mBleManage.connectBluetooth(deviceModule, this.mIDataCallback);
/*     */     } else {
/* 112 */       log("进入2.0的连接方式", "w");
/* 113 */       this.mClassicManage.connectBluetooth(deviceModule, this.mIDataCallback);
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public void disconnect(DeviceModule deviceModule) {
/* 119 */     if (deviceModule != null) {
/* 120 */       deviceModule.setConnected(false);
/* 121 */       if (deviceModule.isBLE()) {
/* 122 */         log("断开BLE蓝牙", "w");
/* 123 */         this.mBleManage.disConnectBluetooth(deviceModule.getMac());
/*     */       } else {
/* 125 */         this.mClassicManage.disconnectBluetooth(deviceModule.getMac());
/*     */       } 
/*     */     } else {
/* 128 */       throw new RuntimeException("disconnect Bluetooth device is null!");
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public void sendData(DeviceModule deviceModule, byte[] data) {
/* 134 */     if (deviceModule.isBLE()) {
/* 135 */       this.mBleManage.sendData(deviceModule, data);
/*     */     } else {
/* 137 */       this.mClassicManage.sendData(deviceModule, data);
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setMTU(DeviceModule deviceModule, int mtu) {
/* 147 */     if (deviceModule.isBLE()) {
/* 148 */       this.mBleManage.setMTU(deviceModule, mtu);
/*     */     }
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void stopSend(DeviceModule deviceModule, IBluetoothStop callback) {
/* 158 */     if (deviceModule != null)
/* 159 */     { if (deviceModule.isBLE()) {
/* 160 */         this.mBleManage.stopSend(deviceModule, callback);
/*     */       } else {
/* 162 */         this.mClassicManage.stopSend(callback);
/*     */       }
/*     */        }
/* 165 */     else if (this.mClassicManage != null) { this.mClassicManage.stopSend(callback); }
/*     */   
/*     */   }
/*     */ 
/*     */   
/*     */   public boolean isStartBluetooth() {
/* 171 */     return this.mClassicManage.startBluetooth();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setSendFileVelocity(DeviceModule deviceModule, int... v) {
/*     */     SendFileVelocity velocity;
/* 183 */     switch (v[0]) {
/*     */       case 1:
/* 185 */         velocity = SendFileVelocity.LOW;
/*     */         break;
/*     */       case 2:
/* 188 */         velocity = SendFileVelocity.HEIGHT;
/*     */         break;
/*     */       case 3:
/* 191 */         velocity = SendFileVelocity.SUPER;
/*     */         break;
/*     */       case 4:
/* 194 */         velocity = SendFileVelocity.MAX;
/*     */         break;
/*     */       case 5:
/* 197 */         velocity = SendFileVelocity.CUSTOM;
/*     */         break;
/*     */       default:
/* 200 */         velocity = SendFileVelocity.LOW;
/* 201 */         log("设置文件发送速度失败,没有这个选项:" + v[0], "e");
/*     */         break;
/*     */     } 
/* 204 */     if (deviceModule.isBLE()) {
/* 205 */       this.mBleManage.setSendFileVelocity(deviceModule, velocity, (v[0] == 5) ? v[1] : 0);
/*     */     } else {
/* 207 */       this.mClassicManage.setSendFileVelocity(velocity);
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setBluetoothState(DeviceModule deviceModule, boolean frontDesk) {
/* 218 */     if (deviceModule.isBLE()) {
/* 219 */       this.mBleManage.setBluetoothState(deviceModule.getMac(), frontDesk);
/*     */     } else {
/* 221 */       this.mClassicManage.setBluetoothState(deviceModule.getMac(), frontDesk);
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public List<DeviceModule> getConnectedDevices() {
/* 231 */     List<DeviceModule> devices = new ArrayList<>();
/* 232 */     if (this.mClassicManage != null) devices.addAll(this.mClassicManage.getConnectedDevices()); 
/* 233 */     if (this.mBleManage != null) devices.addAll(this.mBleManage.getConnectedDevices()); 
/* 234 */     return devices;
/*     */   }
/*     */   
/*     */   private synchronized void callbackActivity(DeviceModule deviceModule, boolean cooling) {
/* 238 */     if (this.mIBluetooth != null) {
/*     */ 
/*     */       
/* 241 */       if ((cooling || this.mUpdateTheLimit) && deviceModule == null) {
/*     */         return;
/*     */       }
/* 244 */       if (deviceModule == null) {
/* 245 */         this.mUpdateTheLimit = true;
/* 246 */         this.mTimeHandler.postDelayed(() -> this.mUpdateTheLimit = false, 200L);
/*     */       } 
/*     */       
/* 249 */       this.mIBluetooth.updateList(deviceModule);
/* 250 */       if (deviceModule != null) this.mScanAllModuleArray.add(deviceModule);
/*     */     
/*     */     } 
/*     */   }
/*     */   
/*     */   private void testMessyCode() {
/* 256 */     final List<DeviceModule> list = getMessyCodeArray();
/* 257 */     this.mBleManage.scanBluetooth(list, true, new IScanCallback()
/*     */         {
/*     */           public void stopScan() {
/* 260 */             AllBluetoothManage.this.log("=====解码=====", "w");
/* 261 */             for (DeviceModule deviceModule : list) {
/* 262 */               AllBluetoothManage.this.log("name: " + deviceModule.getName());
/* 263 */               if (AllBluetoothManage.this.mIBluetooth != null) {
/* 264 */                 AllBluetoothManage.this.mIBluetooth.updateMessyCode(deviceModule);
/*     */               }
/*     */             } 
/* 267 */             if (AllBluetoothManage.this.mIBluetooth != null) AllBluetoothManage.this.mIBluetooth.updateEnd(); 
/* 268 */             AllBluetoothManage.this.mState = AllBluetoothManage.State.leisure;
/*     */           }
/*     */ 
/*     */ 
/*     */           
/*     */           public void updateRecycler(DeviceModule deviceModule) {}
/*     */         });
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   private void setIDataCallback() {
/* 280 */     this.mIDataCallback = new IDataCallback()
/*     */       {
/*     */         public synchronized void readData(byte[] data, String mac)
/*     */         {
/* 284 */           if (AllBluetoothManage.this.mIBluetooth != null) AllBluetoothManage.this.mIBluetooth.readData(mac, data);
/*     */         
/*     */         }
/*     */         
/*     */         public void connectionFail(String mac, String cause) {
/* 289 */           AllBluetoothManage.this.log(mac + " 模块连接失败,原因是: " + cause, "e");
/* 290 */           errorDisconnect(mac);
/*     */         }
/*     */ 
/*     */         
/*     */         public void connectionSucceed(DeviceModule module) {
/* 295 */           AllBluetoothManage.this.log(module.getMac() + " 模块连接成功");
/* 296 */           if (AllBluetoothManage.this.mIBluetooth != null) {
/* 297 */             AllBluetoothManage.this.mIBluetooth.connectSucceed(module);
/*     */           }
/*     */         }
/*     */ 
/*     */         
/*     */         public void reading(boolean isStart) {
/* 303 */           ((Activity)AllBluetoothManage.this.mContext).runOnUiThread(() -> {
/*     */                 if (AllBluetoothManage.this.mIBluetooth != null)
/*     */                   AllBluetoothManage.this.mIBluetooth.reading(isStart); 
/*     */               });
/*     */         }
/*     */         
/*     */         public void errorDisconnect(String mac) {
/* 310 */           DeviceModule deviceModule = AllBluetoothManage.this.getDeviceModule(mac);
/* 311 */           if (AllBluetoothManage.this.mIBluetooth != null) AllBluetoothManage.this.mIBluetooth.errorDisconnect(deviceModule); 
/* 312 */           if (deviceModule != null && deviceModule.isBLE()) {
/* 313 */             AllBluetoothManage.this.mBleManage.disConnectBluetooth(mac);
/*     */           } else {
/* 315 */             AllBluetoothManage.this.mClassicManage.disconnectBluetooth(mac);
/*     */           } 
/*     */         }
/*     */ 
/*     */         
/*     */         public void readNumber(int number) {
/* 321 */           ((Activity)AllBluetoothManage.this.mContext).runOnUiThread(() -> {
/*     */                 if (AllBluetoothManage.this.mIBluetooth != null)
/*     */                   AllBluetoothManage.this.mIBluetooth.readNumber(number); 
/*     */               });
/*     */         }
/*     */         
/*     */         public void readLog(String className, String data, String lv) {
/* 328 */           if (AllBluetoothManage.this.mIBluetooth != null) {
/* 329 */             AllBluetoothManage.this.mIBluetooth.readLog(className, data, lv);
/*     */           } else {
/* 331 */             AllBluetoothManage.this.log("mIBluetooth is null", "w");
/*     */           } 
/*     */         }
/*     */ 
/*     */ 
/*     */         
/*     */         public void readVelocity(int velocity) {
/* 338 */           if (AllBluetoothManage.this.mIBluetooth != null) AllBluetoothManage.this.mIBluetooth.readVelocity(velocity);
/*     */         
/*     */         }
/*     */         
/*     */         public void callbackMTU(int mtu) {
/* 343 */           if (AllBluetoothManage.this.mIBluetooth != null) AllBluetoothManage.this.mIBluetooth.callbackMTU(mtu); 
/*     */         }
/*     */       };
/*     */   }
/*     */   
/*     */   private DeviceModule getDeviceModule(String mac) {
/* 349 */     for (DeviceModule deviceModule : this.mClassicBluetoothArray) {
/* 350 */       if (deviceModule.getMac().equals(mac)) {
/* 351 */         return deviceModule;
/*     */       }
/*     */     } 
/* 354 */     for (DeviceModule deviceModule : this.mScanAllModuleArray) {
/* 355 */       if (deviceModule.getMac().equals(mac)) {
/* 356 */         return deviceModule;
/*     */       }
/*     */     } 
/* 359 */     return null;
/*     */   }
/*     */   
/*     */   private List<DeviceModule> getMessyCodeArray() {
/* 363 */     List<DeviceModule> list = new ArrayList<>();
/* 364 */     for (DeviceModule deviceModule : this.mClassicBluetoothArray) {
/* 365 */       if (deviceModule.isBLE() && ToolClass.pattern(deviceModule.getName())) {
/* 366 */         list.add(deviceModule);
/*     */       }
/*     */     } 
/* 369 */     return list;
/*     */   }
/*     */ 
/*     */   
/*     */   private void log(String log) {
/* 374 */     Log.d("AppRun" + getClass().getSimpleName(), log);
/* 375 */     if (this.mIBluetooth != null)
/* 376 */       this.mIBluetooth.readLog(getClass().getSimpleName(), log, "d"); 
/*     */   }
/*     */   
/*     */   private void log(String log, String lv) {
/* 380 */     if (lv.equals("e")) {
/* 381 */       Log.e("AppRun" + getClass().getSimpleName(), log);
/*     */     } else {
/* 383 */       Log.w("AppRun" + getClass().getSimpleName(), log);
/*     */     } 
/* 385 */     if (this.mIBluetooth != null)
/* 386 */       this.mIBluetooth.readLog(getClass().getSimpleName(), log, lv); 
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\AllBluetoothManage.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */