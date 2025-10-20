/*     */ package com.hc.bluetoothlibrary.classicBluetooth;
/*     */ 
/*     */ import android.app.Activity;
/*     */ import android.app.AlertDialog;
/*     */ import android.bluetooth.BluetoothAdapter;
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.content.BroadcastReceiver;
/*     */ import android.content.Context;
/*     */ import android.content.DialogInterface;
/*     */ import android.content.Intent;
/*     */ import android.content.IntentFilter;
/*     */ import android.os.Handler;
/*     */ import android.util.Log;
/*     */ import android.widget.Toast;
/*     */ import androidx.annotation.Nullable;
/*     */ import com.hc.bluetoothlibrary.AllBluetoothManage;
/*     */ import com.hc.bluetoothlibrary.DeviceModule;
/*     */ import com.hc.bluetoothlibrary.IBluetoothStop;
/*     */ import com.hc.bluetoothlibrary.tootl.IDataCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.IScanCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.ModuleParameters;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.io.OutputStream;
/*     */ import java.io.PrintWriter;
/*     */ import java.io.StringWriter;
/*     */ import java.io.Writer;
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
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class ClassicBluetoothManage
/*     */ {
/*     */   private BluetoothAdapter mBtAdapter;
/*  51 */   private final Map<String, BluetoothHandle> mBluetoothArray = new HashMap<>();
/*     */   
/*  53 */   private final Map<String, BluetoothDevice> mModuleMap = new HashMap<>();
/*  54 */   private final List<DeviceModule> mModuleArray = new ArrayList<>();
/*     */   
/*     */   private IScanCallback mIScanCallback;
/*     */   
/*     */   private IDataCallback mIDataCallback;
/*     */   
/*     */   private final Context mContext;
/*     */   private boolean mIsScanSign = true;
/*  62 */   private final Handler mTimeHandler = new Handler();
/*     */   
/*  64 */   private final List<byte[]> mSendData = (List)new ArrayList<>();
/*     */   
/*     */   private boolean mIsWork = false;
/*     */   
/*     */   private Thread mSendThread;
/*     */   
/*     */   private IBluetoothStop mIBluetoothStop;
/*     */   
/*     */   private boolean mIsStopSend = false;
/*     */   
/*     */   private String mFrontDeskBluetoothMac;
/*     */   
/*     */   private final BroadcastReceiver mReceiver;
/*     */   
/*     */   private final BroadcastReceiver mConnectListener;
/*     */   private BroadcastReceiver receiver;
/*     */   
/*     */   public void scanBluetooth(IScanCallback iScanCallback) {
/*  82 */     if (this.mIScanCallback == null) this.mIScanCallback = iScanCallback; 
/*  83 */     if (this.mIsScanSign) {
/*  84 */       initBroadcast();
/*  85 */       listClear();
/*  86 */       if (ToolClass.checkPermission(this.mContext)) {
/*  87 */         log("开始扫描周围蓝牙..");
/*  88 */         this.mBtAdapter.startDiscovery();
/*  89 */         this.mIsScanSign = false;
/*  90 */         this.mTimeHandler.postDelayed(() -> { log("时间到，停止扫描,mIScanCallback: " + ((this.mIScanCallback == null) ? 1 : 0), "e"); this.mBtAdapter.cancelDiscovery(); this.mIsScanSign = true; unBroadcast(); if (this.mIScanCallback != null) this.mIScanCallback.stopScan();  }10000L);
/*     */       } 
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void stopScan() {
/* 102 */     if (!this.mIsScanSign) {
/* 103 */       log("主动停止..");
/* 104 */       this.mTimeHandler.removeMessages(0);
/* 105 */       if (ToolClass.checkPermission(this.mContext)) {
/* 106 */         this.mBtAdapter.cancelDiscovery();
/*     */       }
/* 108 */       unBroadcast();
/* 109 */       this.mIsScanSign = true;
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public void connectBluetooth(DeviceModule deviceModule, IDataCallback iDataCallback) {
/* 115 */     this.mIDataCallback = iDataCallback;
/* 116 */     log("开始连接2.0蓝牙，地址是：" + deviceModule.getMac(), "w");
/* 117 */     connect(deviceModule);
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public void sendData(DeviceModule deviceModule, byte[] data) {
/* 123 */     this.mFrontDeskBluetoothMac = deviceModule.getMac();
/* 124 */     if (this.mFrontDeskBluetoothMac == null || this.mBluetoothArray.get(this.mFrontDeskBluetoothMac) == null || ((BluetoothHandle)this.mBluetoothArray
/* 125 */       .get(this.mFrontDeskBluetoothMac)).getBluetoothSocket() == null) {
/* 126 */       Toast.makeText(this.mContext, "请连上蓝牙再发送数据", 0).show();
/*     */       return;
/*     */     } 
/* 129 */     this.mIsStopSend = false;
/* 130 */     this.mSendData.add(data);
/*     */   }
/*     */ 
/*     */   
/*     */   public void disconnectBluetooth(String mac) {
/* 135 */     close(mac);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public List<DeviceModule> getDevicesArray() {
/* 142 */     return this.mModuleArray;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public List<DeviceModule> getConnectedDevices() {
/* 149 */     List<DeviceModule> devices = new ArrayList<>();
/* 150 */     for (String mac : this.mBluetoothArray.keySet()) {
/* 151 */       ((BluetoothHandle)this.mBluetoothArray.get(mac)).getDeviceModule().setConnected(true);
/* 152 */       devices.add(((BluetoothHandle)this.mBluetoothArray.get(mac)).getDeviceModule());
/*     */     } 
/* 154 */     return devices;
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public boolean startBluetooth() {
/* 160 */     if ((this.mBtAdapter == null || !this.mBtAdapter.isEnabled()) && 
/* 161 */       ToolClass.checkPermission(this.mContext)) {
/* 162 */       Intent enableBtIntent = new Intent("android.bluetooth.adapter.action.REQUEST_ENABLE");
/* 163 */       ((Activity)this.mContext).startActivityForResult(enableBtIntent, 1);
/* 164 */       setStartBluetoothBroad();
/* 165 */       return false;
/*     */     } 
/* 167 */     return true;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void stopSend(IBluetoothStop iBluetoothStop) {
/* 175 */     this.mIBluetoothStop = iBluetoothStop;
/* 176 */     this.mIsStopSend = true;
/* 177 */     log("停止发送", "w");
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setSendFileVelocity(AllBluetoothManage.SendFileVelocity velocity) {
/* 185 */     switch (velocity) {
/*     */       case LOW:
/* 187 */         ModuleParameters.setSendFileDelayedTime(5000);
/*     */         break;
/*     */       case HEIGHT:
/* 190 */         ModuleParameters.setSendFileDelayedTime(3000);
/*     */         break;
/*     */       case SUPER:
/* 193 */         ModuleParameters.setSendFileDelayedTime(2000);
/*     */         break;
/*     */       case MAX:
/* 196 */         ModuleParameters.setSendFileDelayedTime(1000);
/*     */         break;
/*     */       case CUSTOM:
/* 199 */         ModuleParameters.setSendFileDelayedTime(0);
/*     */         break;
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setBluetoothState(@Nullable String bluetoothMac, boolean frontDesk) {
/* 210 */     for (BluetoothHandle handle : this.mBluetoothArray.values()) {
/* 211 */       handle.setShowExtras(false);
/*     */     }
/* 213 */     if (!frontDesk)
/* 214 */       return;  if (bluetoothMac != null) {
/* 215 */       BluetoothHandle bluetoothHandle = this.mBluetoothArray.get(bluetoothMac);
/* 216 */       if (bluetoothHandle != null) bluetoothHandle.setShowExtras(frontDesk);
/*     */     
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public ClassicBluetoothManage(Context context) {
/* 225 */     this.mReceiver = new BroadcastReceiver()
/*     */       {
/*     */         public void onReceive(Context context, Intent intent) {
/* 228 */           String action = intent.getAction();
/*     */ 
/*     */           
/* 231 */           if ("android.bluetooth.device.action.FOUND".equals(action)) {
/*     */             
/* 233 */             int rssi = 10;
/*     */ 
/*     */             
/* 236 */             BluetoothDevice device = (BluetoothDevice)intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
/* 237 */             if (device == null)
/*     */               return; 
/* 239 */             if (intent.getExtras() != null) rssi = intent.getExtras().getShort("android.bluetooth.device.extra.RSSI");
/*     */             
/* 241 */             boolean bondState = (ToolClass.checkPermission(ClassicBluetoothManage.this.mContext) && device.getBondState() == 12);
/*     */ 
/*     */             
/* 244 */             ClassicBluetoothManage.this.addModule(device, bondState, rssi);
/*     */           }
/* 246 */           else if ("android.bluetooth.adapter.action.DISCOVERY_FINISHED".equals(action)) {
/* 247 */             if (ClassicBluetoothManage.this.mModuleArray.size() == 0) {
/* 248 */               String noDevices = "没有找到新设备";
/* 249 */               ClassicBluetoothManage.this.mModuleArray.add(new DeviceModule(noDevices, null));
/*     */             } 
/* 251 */             if (ClassicBluetoothManage.this.mIScanCallback != null) ClassicBluetoothManage.this.mIScanCallback.stopScan(); 
/* 252 */             ClassicBluetoothManage.this.log("搜索完成", "e");
/*     */           } 
/*     */         }
/*     */       };
/*     */ 
/*     */     
/* 258 */     this.mConnectListener = new BroadcastReceiver()
/*     */       {
/*     */         public void onReceive(Context context, Intent intent) {
/* 261 */           String action = intent.getAction();
/* 262 */           if (action != null && action.equals("android.bluetooth.device.action.ACL_DISCONNECTED") && 
/* 263 */             ClassicBluetoothManage.this.mIDataCallback != null) {
/* 264 */             ClassicBluetoothManage.this.log("监听到蓝牙断线", "e");
/* 265 */             BluetoothDevice device = (BluetoothDevice)intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
/*     */             
/* 267 */             if (device != null) ClassicBluetoothManage.this.mIDataCallback.errorDisconnect(device.getAddress()); 
/*     */           } 
/*     */         }
/*     */       };
/*     */     this.mContext = context;
/*     */     init();
/*     */   }
/*     */   private void setStartBluetoothBroad() {
/* 275 */     this.receiver = new BroadcastReceiver()
/*     */       {
/*     */         public void onReceive(Context context, Intent intent) {
/* 278 */           if (intent.getAction() != null && intent.getAction().equals("android.bluetooth.adapter.action.STATE_CHANGED")) {
/* 279 */             int blueState = intent.getIntExtra("android.bluetooth.adapter.extra.STATE", 0);
/* 280 */             if (blueState == 12) {
/* 281 */               ClassicBluetoothManage.this.log("注销广播..");
/* 282 */               ClassicBluetoothManage.this.mContext.unregisterReceiver(ClassicBluetoothManage.this.receiver);
/* 283 */               if (!ToolClass.isOpenGPS(ClassicBluetoothManage.this.mContext)) ClassicBluetoothManage.this.startLocation(); 
/*     */             } 
/*     */           } 
/*     */         }
/*     */       };
/* 288 */     this.mContext.registerReceiver(this.receiver, new IntentFilter("android.bluetooth.adapter.action.STATE_CHANGED"));
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void init() {
/* 296 */     this.mBtAdapter = BluetoothAdapter.getDefaultAdapter();
/*     */   }
/*     */ 
/*     */   
/*     */   private void listClear() {
/* 301 */     this.mModuleArray.clear();
/* 302 */     this.mModuleMap.clear();
/*     */   }
/*     */ 
/*     */   
/*     */   private void addModule(BluetoothDevice device, boolean isBeenConnected, int rssi) {
/* 307 */     int size = this.mModuleMap.size();
/* 308 */     this.mModuleMap.put(device.getAddress(), device);
/* 309 */     if (this.mModuleMap.size() > size) {
/* 310 */       DeviceModule deviceModule = new DeviceModule(ToolClass.getDeviceName(this.mContext, device), device, isBeenConnected, this.mContext, rssi);
/* 311 */       this.mModuleArray.add(deviceModule);
/* 312 */       updateList(deviceModule);
/*     */     } else {
/* 314 */       for (DeviceModule module : this.mModuleArray) {
/* 315 */         if (module.getMac().equals(device.getAddress())) {
/* 316 */           module.setRssi(rssi);
/* 317 */           updateList(null);
/*     */         } 
/*     */       } 
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   private void updateList(DeviceModule deviceModule) {
/* 326 */     if (this.mIScanCallback != null) this.mIScanCallback.updateRecycler(deviceModule);
/*     */   
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void connect(DeviceModule deviceModule) {
/*     */     try {
/* 335 */       if (!this.mIsScanSign) {
/* 336 */         scanBluetooth(null);
/* 337 */         log("停止扫描蓝牙");
/*     */       } 
/*     */       
/* 340 */       log("2.0蓝牙的UUID是:00001101-0000-1000-8000-00805F9B34FB", "w");
/* 341 */       threadConnect(deviceModule);
/* 342 */     } catch (Exception e) {
/* 343 */       e.printStackTrace();
/* 344 */       Writer w = new StringWriter();
/* 345 */       e.printStackTrace(new PrintWriter(w));
/* 346 */       Toast.makeText(this.mContext, "连接失败！", 0).show();
/* 347 */       log("建立socket失败：" + w, "e");
/*     */       
/* 349 */       if (this.mIDataCallback != null) this.mIDataCallback.connectionFail(deviceModule.getMac(), e.toString());
/*     */     
/*     */     } 
/*     */   }
/*     */   
/*     */   private void threadConnect(final DeviceModule deviceModule) throws Exception {
/* 355 */     final BluetoothHandle bluetoothHandle = new BluetoothHandle(this.mContext, deviceModule, this.mIDataCallback);
/*     */     
/* 357 */     (new TaskThread(this.mTimeHandler)).setWorkCall(new TaskThread.WorkCallBack()
/*     */         {
/*     */           public void succeed() {
/* 360 */             if (!bluetoothHandle.setBluetoothStream()) {
/* 361 */               Toast.makeText(ClassicBluetoothManage.this.mContext, "建立蓝牙Socket监听或发送失败，请断开尝试重新连接!", 0).show();
/*     */               return;
/*     */             } 
/* 364 */             ClassicBluetoothManage.this.mIsWork = true;
/* 365 */             ClassicBluetoothManage.this.log("蓝牙socket连接成功,地址为: " + deviceModule.getMac());
/* 366 */             ClassicBluetoothManage.this.mBluetoothArray.put(deviceModule.getMac(), bluetoothHandle);
/* 367 */             if (ClassicBluetoothManage.this.mIDataCallback != null) ClassicBluetoothManage.this.mIDataCallback.connectionSucceed(deviceModule); 
/* 368 */             ClassicBluetoothManage.this.mFrontDeskBluetoothMac = deviceModule.getMac();
/* 369 */             ClassicBluetoothManage.this.setSendThread();
/* 370 */             ClassicBluetoothManage.this.mContext.registerReceiver(ClassicBluetoothManage.this.mConnectListener, new IntentFilter("android.bluetooth.device.action.ACL_DISCONNECTED"));
/*     */           }
/*     */ 
/*     */ 
/*     */           
/*     */           public boolean work() throws Exception {
/* 376 */             if (ToolClass.checkPermission(ClassicBluetoothManage.this.mContext)) {
/* 377 */               ClassicBluetoothManage.this.log("准备开始建立socket连接...");
/* 378 */               bluetoothHandle.getBluetoothSocket().connect();
/*     */             } 
/* 380 */             return true;
/*     */           }
/*     */ 
/*     */           
/*     */           public void error(Exception e) {
/* 385 */             bluetoothHandle.close();
/* 386 */             Writer w = new StringWriter();
/* 387 */             e.printStackTrace(new PrintWriter(w));
/* 388 */             ClassicBluetoothManage.this.log("连接失败: " + w, "e");
/* 389 */             if (ClassicBluetoothManage.this.mIDataCallback != null) ClassicBluetoothManage.this.mIDataCallback.connectionFail(deviceModule.getMac(), e.toString());
/*     */           
/*     */           }
/*     */         });
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void setSendThread() {
/* 400 */     if (this.mSendThread != null)
/* 401 */       return;  this.mSendThread = new Thread(() -> {
/*     */           byte[] bytes = new byte[1024]; int position = 0;
/*     */           while (this.mIsWork) {
/*     */             if (this.mSendData.size() > 0) {
/*     */               try {
/*     */                 loopSend(position, bytes);
/*     */                 if (this.mIsStopSend && this.mSendData.size() != 0)
/*     */                   this.mSendData.clear(); 
/* 409 */               } catch (Exception e) {
/*     */                 e.printStackTrace();
/*     */               } 
/*     */             }
/*     */           } 
/*     */           log("发送线程结束..");
/*     */         });
/* 416 */     this.mSendThread.start();
/* 417 */     log("发送线程就绪..");
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private synchronized void loopSend(int position, byte[] bytes) throws Exception {
/* 428 */     if (!this.mIsWork)
/* 429 */       return;  if (this.mBluetoothArray.get(this.mFrontDeskBluetoothMac) == null) {
/* 430 */       throw new Exception("获取输出流失败,蓝牙组里没有 " + this.mFrontDeskBluetoothMac + " 地址的蓝牙!!");
/*     */     }
/* 432 */     OutputStream outputStream = ((BluetoothHandle)this.mBluetoothArray.get(this.mFrontDeskBluetoothMac)).getOutputBluetooth();
/* 433 */     if (outputStream == null) throw new Exception(this.mFrontDeskBluetoothMac + " 地址蓝牙获取到输出流为空");
/*     */ 
/*     */     
/* 436 */     dataIntegration();
/* 437 */     byte[] dataByte = this.mSendData.get(0);
/*     */     
/* 439 */     if (dataByte != null && dataByte.length > 1024) {
/*     */       do {
/* 441 */         System.arraycopy(dataByte, position, bytes, 0, 1024);
/* 442 */         position += 1024;
/* 443 */         outputStream.write(bytes);
/*     */ 
/*     */         
/* 446 */         if (ModuleParameters.getSendFileDelayedTime() > 1000) {
/* 447 */           for (int i = 0; i < 16; i++) {
/* 448 */             this.mIDataCallback.readNumber(bytes.length / 16);
/* 449 */             Thread.sleep((ModuleParameters.getSendFileDelayedTime() / 16));
/*     */           } 
/* 451 */         } else if (ModuleParameters.getSendFileDelayedTime() == 0) {
/* 452 */           this.mIDataCallback.readNumber(bytes.length);
/*     */         } else {
/* 454 */           int commonFactor = getMaxCommonFactor(bytes.length, ModuleParameters.getSendFileDelayedTime());
/* 455 */           for (int i = 0; i < commonFactor; i++) {
/* 456 */             this.mIDataCallback.readNumber(bytes.length / commonFactor);
/* 457 */             Thread.sleep((ModuleParameters.getSendFileDelayedTime() / commonFactor));
/*     */           } 
/*     */         } 
/* 460 */       } while (position + 1024 <= dataByte.length && !this.mIsStopSend);
/* 461 */       if (this.mIsStopSend) {
/* 462 */         outputStream.flush();
/* 463 */         this.mSendData.remove(0);
/* 464 */         callbackStopSend();
/*     */         return;
/*     */       } 
/* 467 */       byte[] temp = new byte[dataByte.length - position];
/* 468 */       System.arraycopy(dataByte, position, temp, 0, dataByte.length - position);
/* 469 */       outputStream.write(temp);
/* 470 */       this.mIDataCallback.readNumber(temp.length);
/* 471 */     } else if (dataByte != null && dataByte.length > 0) {
/* 472 */       outputStream.write(dataByte);
/* 473 */       this.mIDataCallback.readNumber(dataByte.length);
/*     */     } 
/* 475 */     outputStream.flush();
/* 476 */     this.mSendData.remove(0);
/* 477 */     if (ModuleParameters.getLevel() > 0) {
/* 478 */       Thread.sleep((ModuleParameters.getLevel() * 10));
/*     */     }
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private synchronized void dataIntegration() {
/* 486 */     if (this.mSendData.size() < 5)
/* 487 */       return;  int allLength = 0;
/* 488 */     for (byte[] data : this.mSendData) {
/* 489 */       allLength += data.length;
/*     */     }
/* 491 */     byte[] bytes = new byte[allLength];
/* 492 */     int nowLength = 0;
/* 493 */     for (int i = 0; i < this.mSendData.size(); i++) {
/* 494 */       System.arraycopy(this.mSendData.get(i), 0, bytes, nowLength, ((byte[])this.mSendData.get(i)).length);
/* 495 */       nowLength += ((byte[])this.mSendData.get(i)).length;
/*     */     } 
/* 497 */     this.mSendData.clear();
/* 498 */     this.mSendData.add(bytes);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void callbackStopSend() {
/* 505 */     this.mIsStopSend = false;
/* 506 */     if (this.mIBluetoothStop != null) {
/* 507 */       this.mTimeHandler.post(() -> this.mIBluetoothStop.completeStop());
/*     */     }
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   private void close(String mac) {
/* 514 */     if (mac == null)
/* 515 */       return;  BluetoothHandle bluetoothHandle = this.mBluetoothArray.get(mac);
/* 516 */     if (bluetoothHandle == null)
/* 517 */       return;  bluetoothHandle.close();
/* 518 */     this.mBluetoothArray.remove(mac);
/* 519 */     if (this.mFrontDeskBluetoothMac.equals(mac) && this.mSendData.size() > 0) this.mSendData.clear(); 
/* 520 */     if (this.mBluetoothArray.size() != 0)
/* 521 */       return;  this.mIsWork = false;
/* 522 */     closeThread();
/*     */     try {
/* 524 */       this.mContext.unregisterReceiver(this.mConnectListener);
/* 525 */     } catch (Exception e) {
/* 526 */       e.printStackTrace();
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   private void closeThread() {
/* 532 */     if (this.mSendThread != null) this.mSendThread.interrupt(); 
/* 533 */     this.mSendThread = null;
/* 534 */     log("关闭线程..");
/*     */   }
/*     */ 
/*     */   
/*     */   private void initBroadcast() {
/* 539 */     this.mContext.registerReceiver(this.mReceiver, new IntentFilter("android.bluetooth.device.action.FOUND"));
/* 540 */     this.mContext.registerReceiver(this.mReceiver, new IntentFilter("android.bluetooth.adapter.action.DISCOVERY_FINISHED"));
/*     */     
/* 542 */     this.mContext.registerReceiver(this.mReceiver, new IntentFilter("android.bluetooth.adapter.action.DISCOVERY_STARTED"));
/* 543 */     log("注册广播接收器..");
/*     */   }
/*     */ 
/*     */   
/*     */   private void unBroadcast() {
/* 548 */     this.mContext.unregisterReceiver(this.mReceiver);
/* 549 */     log("注销广播接收器..");
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private int getMaxCommonFactor(int num1, int num2) {
/* 559 */     if (num1 == 0 || num2 == 0) return 0;
/*     */     
/*     */     while (true) {
/* 562 */       int temp = num1 % num2;
/* 563 */       num1 = num2;
/* 564 */       num2 = temp;
/* 565 */       if (num2 == 0)
/* 566 */         return num1; 
/*     */     } 
/*     */   }
/*     */   private void startLocation() {
/* 570 */     AlertDialog.Builder builder = new AlertDialog.Builder(this.mContext, 5);
/* 571 */     builder.setTitle("提示")
/* 572 */       .setMessage("请前往打开手机的位置权限!")
/* 573 */       .setCancelable(false)
/* 574 */       .setPositiveButton("确定", (dialog, which) -> {
/*     */           Intent intent = new Intent("android.settings.LOCATION_SOURCE_SETTINGS");
/*     */           ((Activity)this.mContext).startActivityForResult(intent, 10);
/* 577 */         }).show();
/*     */   }
/*     */   
/*     */   private void log(String str) {
/* 581 */     Log.d("AppRunClassicManage", str);
/* 582 */     if (this.mIDataCallback != null)
/* 583 */       this.mIDataCallback.readLog(getClass().getSimpleName(), str, "d"); 
/*     */   }
/*     */   
/*     */   private void log(String str, String lv) {
/* 587 */     if (lv.equals("e")) {
/* 588 */       Log.e("AppRunClassicManage", str);
/*     */     } else {
/* 590 */       Log.w("AppRunClassicManage", str);
/*     */     } 
/* 592 */     if (this.mIDataCallback != null)
/* 593 */       this.mIDataCallback.readLog(getClass().getSimpleName(), str, lv); 
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\classicBluetooth\ClassicBluetoothManage.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */