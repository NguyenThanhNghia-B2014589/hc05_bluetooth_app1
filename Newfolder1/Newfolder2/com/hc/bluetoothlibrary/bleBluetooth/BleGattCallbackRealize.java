/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import android.app.Service;
/*     */ import android.bluetooth.BluetoothGatt;
/*     */ import android.bluetooth.BluetoothGattCallback;
/*     */ import android.bluetooth.BluetoothGattCharacteristic;
/*     */ import android.bluetooth.BluetoothGattDescriptor;
/*     */ import android.bluetooth.BluetoothGattService;
/*     */ import android.content.Context;
/*     */ import android.os.Build;
/*     */ import android.os.Handler;
/*     */ import android.os.HandlerThread;
/*     */ import android.os.Message;
/*     */ import android.util.Log;
/*     */ import android.widget.Toast;
/*     */ import androidx.annotation.NonNull;
/*     */ import com.hc.bluetoothlibrary.DeviceModule;
/*     */ import com.hc.bluetoothlibrary.IBluetoothStop;
/*     */ import com.hc.bluetoothlibrary.tootl.ModuleParameters;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.util.ArrayList;
/*     */ import java.util.List;
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
/*     */ public class BleGattCallbackRealize
/*     */   extends BluetoothGattCallback
/*     */ {
/*     */   private static final String SERVICE_EIGENVALUE_SEND = "0000ffe1-0000-1000-8000-00805f9b34fb";
/*     */   private static final String SERVICE_EIGENVALUE_READ = "00002902-0000-1000-8000-00805f9b34fb";
/*     */   private final Handler mHandler;
/*     */   private final Service mService;
/*  41 */   private final Handler mTimeHandler = new Handler();
/*     */   
/*     */   private boolean isShowExtras = true;
/*     */   
/*     */   private boolean mIsStartHeightPriority = false;
/*     */   
/*     */   private Timer mTimer;
/*     */   
/*     */   private TimerTask mTimerTask;
/*     */   
/*  51 */   private int mSectionNumber = 0;
/*     */   
/*  53 */   private final List<byte[]> mDataBuff = (List)new ArrayList<>();
/*     */   
/*  55 */   private int mMTU = 20;
/*     */   
/*     */   private boolean sendDataSign = true;
/*     */   
/*     */   private DeviceModule mDeiceModule;
/*     */   
/*     */   private BluetoothGattCharacteristic mNeedCharacteristic;
/*     */   
/*     */   private BluetoothGatt mBluetoothGatt;
/*     */   
/*     */   private Handler mChildThreadHandler;
/*     */   
/*     */   private HandlerThread mHandlerThread;
/*     */   
/*     */   private IBluetoothStop mIBluetoothStop;
/*     */   
/*     */   private boolean mIsStopSend = false;
/*     */   
/*     */   private final List<BluetoothGattCharacteristic> characteristics;
/*     */   private final Context context;
/*     */   
/*     */   public BleGattCallbackRealize(Context context, Service service, Handler handler) {
/*  77 */     this.context = context;
/*  78 */     this.mHandler = handler;
/*  79 */     this.mService = service;
/*  80 */     this.characteristics = new ArrayList<>();
/*  81 */     initThread();
/*     */   }
/*     */   
/*     */   public void setDeiceModule(DeviceModule mDeiceModule) {
/*  85 */     this.mDeiceModule = mDeiceModule;
/*     */   }
/*     */   
/*     */   public DeviceModule getDevice() {
/*  89 */     return this.mDeiceModule;
/*     */   }
/*     */   
/*     */   public int getMTU() {
/*  93 */     return this.mMTU;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public synchronized void sendMultiple(byte[] data) {
/* 102 */     if (this.mNeedCharacteristic == null) {
/* 103 */       log("错误，没有拿到写入特征", "e");
/*     */       
/*     */       return;
/*     */     } 
/*     */     
/* 108 */     boolean isSendBuffNull = (this.mDataBuff.size() < 2);
/* 109 */     this.mDataBuff.addAll(ToolClass.getSendDataByte(data, this.mMTU));
/* 110 */     if (isSendBuffNull) this.mChildThreadHandler.sendEmptyMessage(0);
/*     */   
/*     */   }
/*     */ 
/*     */   
/*     */   public void receiveComplete() {
/* 116 */     if (this.mTimerTask != null) this.mTimerTask.cancel(); 
/* 117 */     this.mTimerTask = null;
/* 118 */     this.mSectionNumber = 0;
/*     */   }
/*     */   
/*     */   public void stopSend(IBluetoothStop iBluetoothStop) {
/* 122 */     this.mIBluetoothStop = iBluetoothStop;
/* 123 */     if (this.mDataBuff.size() > 0) {
/* 124 */       this.mIsStopSend = true;
/* 125 */       log("执行停止发送...");
/*     */     } 
/*     */   }
/*     */   
/*     */   public void setMTU(int mtu) {
/* 130 */     if (Build.VERSION.SDK_INT >= 21 && 
/* 131 */       ToolClass.checkPermission(this.context)) {
/* 132 */       if (mtu < 23) {
/* 133 */         log("设置MTU: " + this.mBluetoothGatt.requestMtu(23), "w");
/*     */       } else {
/* 135 */         log("设置MTU: " + this.mBluetoothGatt.requestMtu(mtu), "w");
/*     */       } 
/*     */     } else {
/* 138 */       sendHandler(8, Integer.valueOf(-2));
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public void disconnect() {
/* 144 */     if (this.mHandlerThread != null) this.mHandlerThread.quitSafely(); 
/* 145 */     if (this.mBluetoothGatt != null && ToolClass.checkPermission(this.context)) {
/* 146 */       log("执行断开ble蓝牙操作..", "w");
/* 147 */       this.mBluetoothGatt.disconnect();
/* 148 */       this.mBluetoothGatt.close();
/* 149 */       this.mBluetoothGatt = null;
/*     */     } 
/*     */   }
/*     */   
/*     */   public boolean isShowExtras() {
/* 154 */     return this.isShowExtras;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setShowExtras(boolean showExtras) {
/* 161 */     this.isShowExtras = showExtras;
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
/* 167 */     if (newState == 133) {
/* 168 */       log("出现133问题，需要扫描重连", "e");
/* 169 */       sendHandler(2, "出现133错误");
/*     */     } 
/* 171 */     if (newState == 2 && 
/* 172 */       ToolClass.checkPermission(this.context)) {
/* 173 */       log("连接成功，开始获取服务UUID");
/*     */       
/* 175 */       if (detectionGatt(gatt))
/*     */         return; 
/* 177 */       this.mTimeHandler.postDelayed(() -> { if (detectionGatt(gatt)) return;  gatt.discoverServices(); }1500L);
/*     */ 
/*     */ 
/*     */       
/* 181 */       this.mTimeHandler.postDelayed(() -> { if (detectionGatt(gatt)) return;  log("获取服务UUID超时，断开重连", "e"); sendHandler(3, null); }5500L);
/*     */ 
/*     */ 
/*     */     
/*     */     }
/* 186 */     else if (newState == 0) {
/* 187 */       log("蓝牙断开", "e");
/* 188 */       sendHandler(3, null);
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
/* 196 */     super.onCharacteristicWrite(gatt, characteristic, status);
/* 197 */     if (status == 0)
/*     */     
/*     */     { 
/*     */       
/* 201 */       if ((characteristic.getValue()).length == 0) {
/* 202 */         this.sendDataSign = true;
/*     */         
/*     */         return;
/*     */       } 
/*     */       
/* 207 */       sendHandler(4, 
/* 208 */           String.valueOf((characteristic.getValue()).length));
/* 209 */       this.sendDataSign = true; }
/* 210 */     else { log("status is " + status, "e"); }
/*     */   
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
/* 217 */     if (status == 0)
/*     */     {
/*     */       
/* 220 */       if (ToolClass.checkPermission(this.context)) {
/* 221 */         log("设置监听成功,可以发送数据了...");
/* 222 */         log("服务中连接成功，给与的返回名称是->" + gatt.getDevice().getName());
/* 223 */         log("服务中连接成功，给与的返回地址是->" + gatt.getDevice().getAddress());
/* 224 */         this.mBluetoothGatt = gatt;
/* 225 */         sendHandler(1, this.mDeiceModule);
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
/*     */   
/*     */   public void onServicesDiscovered(BluetoothGatt gatt, int status) {
/* 238 */     if (detectionGatt(gatt))
/*     */       return; 
/* 240 */     this.mTimeHandler.removeMessages(0);
/* 241 */     List<BluetoothGattService> servicesLists = gatt.getServices();
/* 242 */     log("扫描到服务的个数:" + servicesLists.size());
/* 243 */     int i = 0;
/*     */     
/* 245 */     for (BluetoothGattService servicesList : servicesLists) {
/* 246 */       i++;
/* 247 */       log("-----------打印服务----------");
/* 248 */       log(i + "号服务的uuid: " + servicesList.getUuid().toString());
/*     */       
/* 250 */       List<BluetoothGattCharacteristic> gattCharacteristics = servicesList.getCharacteristics();
/*     */       
/* 252 */       int j = 0;
/* 253 */       log("----------打印特征-----------");
/* 254 */       for (BluetoothGattCharacteristic gattCharacteristic : gattCharacteristics) {
/* 255 */         j++;
/* 256 */         isNotifyAndWrite(gattCharacteristic);
/* 257 */         if (gattCharacteristic.getUuid().toString().equals("0000ffe1-0000-1000-8000-00805f9b34fb")) {
/*     */           
/* 259 */           this.characteristics.clear();
/* 260 */           createConnect(gatt, gattCharacteristic);
/*     */           return;
/*     */         } 
/* 263 */         log(i + "号服务的第" + j + "个特征" + gattCharacteristic.getUuid().toString());
/*     */       } 
/*     */     } 
/*     */ 
/*     */     
/* 268 */     log("找不到目标特征值,采用备用连接", "w");
/* 269 */     createConnect(gatt);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
/* 277 */     super.onCharacteristicChanged(gatt, characteristic);
/*     */ 
/*     */     
/* 280 */     sendHandler(characteristic.getValue());
/* 281 */     accessRate(gatt, (characteristic.getValue()).length);
/*     */   }
/*     */ 
/*     */   
/*     */   public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
/* 286 */     super.onMtuChanged(gatt, mtu, status);
/*     */     
/* 288 */     if (gatt.getServices() == null || gatt.getServices().size() == 0)
/*     */       return; 
/* 290 */     if (status == 0) {
/* 291 */       this.mMTU = mtu - 3;
/* 292 */       log("mtu is " + mtu, "e");
/* 293 */       sendHandler(8, Integer.valueOf(mtu));
/*     */     } else {
/* 295 */       log("MTU设置失败: " + status);
/* 296 */       sendHandler(8, Integer.valueOf(-1));
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void isNotifyAndWrite(BluetoothGattCharacteristic gattCharacteristic) {
/* 306 */     int properties = gattCharacteristic.getProperties();
/* 307 */     boolean isWrite1 = ((properties & 0x8) > 0);
/* 308 */     boolean isWrite2 = ((properties & 0x4) > 0);
/* 309 */     boolean isNotify = ((properties & 0x10) > 0);
/* 310 */     if (isNotify && (isWrite1 || isWrite2)) this.characteristics.add(gattCharacteristic);
/*     */   
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void createConnect(BluetoothGatt gatt, BluetoothGattCharacteristic gattCharacteristic) {
/* 319 */     UUID serviceUUID = gattCharacteristic.getService().getUuid();
/* 320 */     String characteristicUUID = gattCharacteristic.getUuid().toString();
/* 321 */     this.mDeiceModule.setUUID(serviceUUID.toString(), characteristicUUID);
/* 322 */     this.mNeedCharacteristic = gattCharacteristic;
/* 323 */     log("可通信特征：" + characteristicUUID, "w");
/*     */ 
/*     */     
/* 326 */     if (ToolClass.checkPermission(this.context)) {
/* 327 */       gatt.setCharacteristicNotification(this.mNeedCharacteristic, true);
/*     */     }
/* 329 */     this.mTimeHandler.postDelayed(() -> { BluetoothGattDescriptor clientConfig = this.mNeedCharacteristic.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")); if (clientConfig != null) { clientConfig.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE); gatt.writeDescriptor(clientConfig); if (this.mDeiceModule.getReadWriteUUID() == null) { log("检测传递通信特征失败，重新设置", "e"); this.mDeiceModule.setUUID(serviceUUID.toString(), characteristicUUID); } else { log("检测没问题: " + this.mDeiceModule.getReadWriteUUID()); }  } else { log("备用方法测试", "w"); BluetoothGattService linkLossService = gatt.getService(serviceUUID); setNotification(gatt, linkLossService.getCharacteristic(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")), true); }  }200L);
/*     */   }
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
/*     */   private void createConnect(BluetoothGatt gatt) {
/* 357 */     if (this.characteristics.size() == 0) {
/* 358 */       log("没有收集到符合条件的特征值", "e");
/*     */       
/*     */       return;
/*     */     } 
/* 362 */     int num = 0;
/* 363 */     for (BluetoothGattCharacteristic characteristic : this.characteristics) {
/* 364 */       this.mHandler.postDelayed(() -> { if (this.mBluetoothGatt == null) { log("尝试特征值: " + characteristic.getUuid(), "w"); createConnect(gatt, characteristic); }  }num * 2000L);
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */       
/* 370 */       num++;
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   private void accessRate(final BluetoothGatt gatt, int length) {
/* 377 */     if (this.mIsStartHeightPriority && !this.isShowExtras)
/* 378 */       return;  if (this.mTimerTask == null) {
/* 379 */       this.mTimerTask = new TimerTask()
/*     */         {
/*     */           public void run()
/*     */           {
/* 383 */             if (BleGattCallbackRealize.this.isShowExtras) BleGattCallbackRealize.this.sendHandler(7, Integer.valueOf(BleGattCallbackRealize.this.mSectionNumber * 5)); 
/* 384 */             if (!BleGattCallbackRealize.this.mIsStartHeightPriority && BleGattCallbackRealize.this.mSectionNumber > 400) {
/* 385 */               if (Build.VERSION.SDK_INT >= 21 && 
/* 386 */                 ToolClass.checkPermission(BleGattCallbackRealize.this.context)) {
/* 387 */                 if (BleGattCallbackRealize.this.detectionGatt(gatt))
/* 388 */                   return;  BleGattCallbackRealize.this.log("设置高速传输模式: " + gatt.requestConnectionPriority(1), "w");
/*     */               } else {
/* 390 */                 Toast.makeText((Context)BleGattCallbackRealize.this.mService, "抱歉，Android6.0以下手机不支持蓝牙高速传输，可能出现会丢包现象", 1).show();
/*     */               } 
/* 392 */               BleGattCallbackRealize.this.mIsStartHeightPriority = true;
/*     */             } 
/* 394 */             BleGattCallbackRealize.this.mSectionNumber = 0;
/*     */           }
/*     */         };
/* 397 */       if (this.mTimer == null) this.mTimer = new Timer(); 
/* 398 */       this.mTimer.schedule(this.mTimerTask, 200L, 200L);
/*     */     } 
/* 400 */     this.mSectionNumber += length;
/*     */   }
/*     */ 
/*     */   
/*     */   private boolean detectionGatt(BluetoothGatt gatt) {
/* 405 */     if (gatt == null) {
/* 406 */       log("出现未知错误，服务关闭，GATT is null", "e");
/* 407 */       sendHandler(2, "未知错误");
/* 408 */       return true;
/*     */     } 
/* 410 */     return false;
/*     */   }
/*     */   
/*     */   public void setNotification(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, boolean enable) {
/* 414 */     if (gatt == null || characteristic == null) {
/* 415 */       log("gatt == null || characteristic == null");
/*     */       
/*     */       return;
/*     */     } 
/* 419 */     boolean success = (ToolClass.checkPermission(this.context) && gatt.setCharacteristicNotification(characteristic, enable));
/* 420 */     Log.e("TAG", "setNotification: " + success);
/* 421 */     if (success) {
/* 422 */       for (BluetoothGattDescriptor dp : characteristic.getDescriptors()) {
/* 423 */         if ((characteristic.getProperties() & 0x10) != 0) {
/* 424 */           dp.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
/* 425 */           log("路线1");
/* 426 */         } else if ((characteristic.getProperties() & 0x20) != 0) {
/* 427 */           dp.setValue(BluetoothGattDescriptor.ENABLE_INDICATION_VALUE);
/* 428 */           log("路线2");
/*     */         } else {
/* 430 */           log("没有走");
/*     */         } 
/* 432 */         this.mTimeHandler.postDelayed(() -> { gatt.writeDescriptor(dp); log("监听的特征是: " + dp.getUuid().toString()); }1000L);
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
/*     */   private void initThread() {
/* 454 */     this.mHandlerThread = new HandlerThread("HandlerThread");
/* 455 */     this.mHandlerThread.start();
/* 456 */     log("执行initThread...");
/* 457 */     this.mChildThreadHandler = new Handler(this.mHandlerThread.getLooper(), new Handler.Callback()
/*     */         {
/*     */           public boolean handleMessage(@NonNull Message msg) {
/*     */             try {
/* 461 */               synchronized (this) {
/* 462 */                 for (; BleGattCallbackRealize.this.mDataBuff.size() != 0 && BleGattCallbackRealize.this.mBluetoothGatt != null; BleGattCallbackRealize.this.permanentThreadSendData());
/*     */               } 
/* 464 */             } catch (Exception e) {
/* 465 */               e.printStackTrace();
/* 466 */               BleGattCallbackRealize.this.log("发生错误: " + e.getMessage());
/*     */             } 
/* 468 */             return false;
/*     */           }
/*     */         });
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private synchronized void permanentThreadSendData() throws Exception {
/* 479 */     if (this.mDataBuff.size() == 0 || this.mDataBuff.get(0) == null)
/* 480 */       return;  int interval = -3;
/*     */     
/* 482 */     this.mNeedCharacteristic.setValue(this.mDataBuff.get(0));
/* 483 */     this.sendDataSign = !this.mBluetoothGatt.writeCharacteristic(this.mNeedCharacteristic);
/*     */     
/* 485 */     if (this.sendDataSign) {
/* 486 */       Thread.sleep(400L);
/* 487 */       if (!ModuleParameters.isSendFile()) this.mDataBuff.remove(0);
/*     */ 
/*     */       
/*     */       return;
/*     */     } 
/* 492 */     if (ModuleParameters.isSendFile()) {
/* 493 */       while (interval < 0 && !this.sendDataSign) { Thread.sleep(3L); interval++; }
/* 494 */        Thread.sleep((3 + ModuleParameters.getSendFileDelayedTime()));
/*     */     } else {
/*     */       
/* 497 */       if (ModuleParameters.getLevel() != 0) Thread.sleep((ModuleParameters.getLevel() * 10)); 
/* 498 */       Thread.sleep((5 + 10 * ModuleParameters.getState()));
/*     */     } 
/*     */ 
/*     */     
/* 502 */     while (!this.sendDataSign) {
/* 503 */       Thread.sleep(5L);
/* 504 */       interval++;
/* 505 */       if (interval == 4) {
/* 506 */         this.mNeedCharacteristic.setValue(new byte[0]);
/* 507 */         this.sendDataSign = !this.mBluetoothGatt.writeCharacteristic(this.mNeedCharacteristic);
/* 508 */         log("额外发送一次," + this.sendDataSign, "w");
/*     */       } 
/* 510 */       if (interval == 50) {
/* 511 */         this.mNeedCharacteristic.setValue(new byte[0]);
/* 512 */         this.sendDataSign = !this.mBluetoothGatt.writeCharacteristic(this.mNeedCharacteristic);
/* 513 */         log("额外发送一次," + this.sendDataSign, "e");
/*     */       } 
/* 515 */       if (interval == 100) {
/* 516 */         this.sendDataSign = true;
/* 517 */         log("无法发送，跳过这个包的发送", "e");
/*     */       } 
/*     */     } 
/* 520 */     if (this.mDataBuff.size() != 0) this.mDataBuff.remove(0); 
/* 521 */     callbackStopSend();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void callbackStopSend() {
/* 528 */     if (this.mIsStopSend) {
/* 529 */       this.mIsStopSend = false;
/* 530 */       this.mDataBuff.clear();
/* 531 */       if (this.mIBluetoothStop != null) {
/* 532 */         this.mHandler.post(() -> this.mIBluetoothStop.completeStop());
/*     */       }
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   private void sendHandler(byte[] data) {
/* 539 */     if (this.mHandler == null) {
/* 540 */       log("错误，返回信息的handler为空", "e");
/*     */       
/*     */       return;
/*     */     } 
/* 544 */     Message message = this.mHandler.obtainMessage();
/* 545 */     message.what = 0;
/* 546 */     message.obj = data.clone();
/* 547 */     message.getData().putString("MODULE_MAC", this.mDeiceModule.getMac());
/* 548 */     message.getData().putBoolean("MODULE_FRONT_DESK", this.isShowExtras);
/* 549 */     this.mHandler.sendMessage(message);
/*     */   }
/*     */ 
/*     */   
/*     */   private void sendHandler(int type, Object data) {
/* 554 */     if (this.mHandler != null) {
/* 555 */       Message message = this.mHandler.obtainMessage();
/* 556 */       message.what = type;
/* 557 */       if (data != null) message.obj = data; 
/* 558 */       message.getData().putString("MODULE_MAC", this.mDeiceModule.getMac());
/* 559 */       this.mHandler.sendMessage(message);
/*     */     } 
/*     */   }
/*     */   
/*     */   private void sendLog(String data, String lv) {
/* 564 */     if (this.mHandler == null)
/* 565 */       return;  String str = "/**separator**/";
/* 566 */     Message message = this.mHandler.obtainMessage();
/* 567 */     message.what = 5;
/* 568 */     message.obj = getClass().getSimpleName() + str + data + str + lv + str;
/* 569 */     this.mHandler.sendMessage(message);
/*     */   }
/*     */   
/*     */   private void log(String str) {
/* 573 */     Log.d("AppRunService", str);
/* 574 */     sendLog(str, "d");
/*     */   }
/*     */   private void log(String str, String e) {
/* 577 */     if (e.equals("i")) {
/* 578 */       Log.e("AppRunService", str);
/*     */       return;
/*     */     } 
/* 581 */     if (e.equals("e")) {
/* 582 */       Log.e("AppRunService", str);
/*     */     } else {
/* 584 */       Log.w("AppRunService", str);
/*     */     } 
/* 586 */     sendLog(str, e);
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\BleGattCallbackRealize.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */