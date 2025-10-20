/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import android.app.Activity;
/*     */ import android.bluetooth.BluetoothAdapter;
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.bluetooth.BluetoothManager;
/*     */ import android.bluetooth.le.BluetoothLeScanner;
/*     */ import android.bluetooth.le.ScanCallback;
/*     */ import android.bluetooth.le.ScanResult;
/*     */ import android.bluetooth.le.ScanSettings;
/*     */ import android.content.Context;
/*     */ import android.os.Build;
/*     */ import android.os.Handler;
/*     */ import android.util.Log;
/*     */ import android.widget.Toast;
/*     */ import androidx.annotation.RequiresApi;
/*     */ import com.hc.bluetoothlibrary.DeviceModule;
/*     */ import com.hc.bluetoothlibrary.tootl.IDataCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.IScanCallback;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.io.UnsupportedEncodingException;
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
/*     */ public class BleScanManage
/*     */ {
/*     */   private IScanCallback mIScanCallback;
/*     */   private final IDataCallback mIDataCallback;
/*     */   private BluetoothAdapter bluetoothAdapter;
/*     */   private final Context context;
/*  38 */   private final List<DeviceModule> mListDevices = new ArrayList<>();
/*     */   
/*     */   private BluetoothLeScanner mBluetoothLeScanner;
/*     */   
/*     */   private ScanCallback mScanCallback;
/*     */   private ScanCallback mScanCallbackMessyCode;
/*     */   private static final long SCAN_PERIOD = 20000L;
/*  45 */   private final Handler mTimeHandler = new Handler();
/*     */ 
/*     */ 
/*     */   
/*     */   private boolean isOffScan = true;
/*     */ 
/*     */   
/*     */   private boolean isTimeScan = true;
/*     */ 
/*     */   
/*     */   private final BluetoothAdapter.LeScanCallback mLeScanCallback;
/*     */ 
/*     */ 
/*     */   
/*     */   public void scanBluetooth(IScanCallback iScanCallback) {
/*  60 */     this.mIScanCallback = iScanCallback;
/*     */     
/*  62 */     if (this.bluetoothAdapter == null) {
/*  63 */       if (Build.VERSION.SDK_INT >= 21) {
/*  64 */         this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
/*     */       } else {
/*  66 */         BluetoothManager bluetoothManager = (BluetoothManager)this.context.getSystemService("bluetooth");
/*  67 */         this.bluetoothAdapter = bluetoothManager.getAdapter();
/*     */       } 
/*     */     }
/*  70 */     if (this.mBluetoothLeScanner == null && 
/*  71 */       Build.VERSION.SDK_INT >= 21) {
/*  72 */       this.mBluetoothLeScanner = this.bluetoothAdapter.getBluetoothLeScanner();
/*     */     }
/*     */ 
/*     */     
/*  76 */     if (this.isOffScan) {
/*  77 */       this.isOffScan = false;
/*  78 */       this.isTimeScan = true;
/*  79 */       this.mTimeHandler.postDelayed(() -> { if (!this.isTimeScan) { log("时间到，已提前停止扫描"); return; }  this.isOffScan = true; log("自动停止扫描"); this.mIScanCallback.stopScan(); if (Build.VERSION.SDK_INT >= 21) { if (ToolClass.checkPermission(this.context)) this.mBluetoothLeScanner.stopScan(this.mScanCallback);  } else { this.bluetoothAdapter.stopLeScan(this.mLeScanCallback); }  log("搜索到个数: " + this.mListDevices.size()); }20000L);
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
/*  97 */       log("开始扫描...");
/*  98 */       this.mListDevices.clear();
/*  99 */       if (Build.VERSION.SDK_INT >= 21) {
/* 100 */         if (Build.VERSION.SDK_INT >= 23) {
/* 101 */           log("高功耗扫描模式..");
/*     */           
/* 103 */           ScanSettings.Builder builder = (new ScanSettings.Builder()).setScanMode(2);
/* 104 */           this.mBluetoothLeScanner.startScan(null, builder.build(), this.mScanCallback);
/*     */         } else {
/* 106 */           this.mBluetoothLeScanner.startScan(this.mScanCallback);
/*     */         } 
/*     */       } else {
/* 109 */         this.bluetoothAdapter.startLeScan(this.mLeScanCallback);
/*     */       } 
/*     */     } 
/*     */   }
/*     */   
/*     */   public void stopScan() {
/* 115 */     if (!this.isOffScan) {
/* 116 */       this.isOffScan = true;
/* 117 */       this.isTimeScan = false;
/* 118 */       log("手动停止扫描");
/* 119 */       if (Build.VERSION.SDK_INT >= 21) {
/* 120 */         if (ToolClass.checkPermission(this.context)) {
/* 121 */           this.mBluetoothLeScanner.stopScan(this.mScanCallback);
/*     */         }
/*     */       } else {
/* 124 */         this.bluetoothAdapter.stopLeScan(this.mLeScanCallback);
/*     */       } 
/* 126 */       this.mTimeHandler.removeMessages(0);
/* 127 */       log("搜索到个数: " + this.mListDevices.size());
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public void scanBluetooth(List<DeviceModule> list, boolean isStart, IScanCallback iScanCallback) {
/* 134 */     if (Build.VERSION.SDK_INT < 21 || ((list == null || list.size() == 0) && isStart)) {
/* 135 */       log("不需要修正或是手机版本过低..");
/* 136 */       if (iScanCallback != null) iScanCallback.stopScan();
/*     */       
/*     */       return;
/*     */     } 
/* 140 */     if (this.bluetoothAdapter == null) {
/* 141 */       this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
/*     */     }
/* 143 */     if (this.mBluetoothLeScanner == null) {
/* 144 */       this.mBluetoothLeScanner = this.bluetoothAdapter.getBluetoothLeScanner();
/*     */     }
/*     */ 
/*     */     
/* 148 */     if (isStart && ToolClass.checkPermission(this.context)) {
/* 149 */       setScanCallBackMessyCode(list);
/* 150 */       this.mTimeHandler.postDelayed(() -> { log("自动停止扫描"); iScanCallback.stopScan(); this.mBluetoothLeScanner.stopScan(this.mScanCallbackMessyCode); }10000L);
/*     */     } 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */     
/* 157 */     if (isStart) {
/* 158 */       ScanSettings.Builder builder = (new ScanSettings.Builder()).setScanMode(2);
/* 159 */       this.mBluetoothLeScanner.startScan(null, builder.build(), this.mScanCallbackMessyCode);
/*     */     } else {
/* 161 */       log("停止扫描");
/* 162 */       this.mTimeHandler.removeMessages(0);
/* 163 */       this.mBluetoothLeScanner.stopScan(this.mScanCallbackMessyCode);
/* 164 */       if (iScanCallback != null) iScanCallback.stopScan();
/*     */     
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private void initBluetoothAdapter() {
/* 173 */     BluetoothManager bluetoothManager = (BluetoothManager)this.context.getSystemService("bluetooth");
/* 174 */     if (Build.VERSION.SDK_INT >= 21) {
/* 175 */       this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
/* 176 */       this.mBluetoothLeScanner = this.bluetoothAdapter.getBluetoothLeScanner();
/*     */     } else {
/* 178 */       this.bluetoothAdapter = bluetoothManager.getAdapter();
/*     */     } 
/*     */     
/* 181 */     if (Build.VERSION.SDK_INT >= 21) setScanCallBack();
/*     */   
/*     */   }
/*     */ 
/*     */   
/*     */   public BleScanManage(Context context, IDataCallback iDataCallback) {
/* 187 */     this.mLeScanCallback = new BluetoothAdapter.LeScanCallback()
/*     */       {
/*     */         
/*     */         public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord)
/*     */         {
/* 192 */           ((Activity)BleScanManage.this.context).runOnUiThread(() -> BleScanManage.this.addDeviceModel(device, rssi, null, null));
/*     */         }
/*     */       };
/*     */     this.context = context;
/*     */     this.mIDataCallback = iDataCallback;
/*     */     initBluetoothAdapter();
/*     */   } @RequiresApi(api = 21)
/*     */   private void setScanCallBack() {
/* 200 */     this.mScanCallback = new ScanCallback()
/*     */       {
/*     */         public void onScanResult(int callbackType, ScanResult result)
/*     */         {
/* 204 */           BluetoothDevice device = result.getDevice();
/*     */           
/* 206 */           String moduleName = null;
/* 207 */           if (null != device && null != result.getScanRecord() && ToolClass.pattern(ToolClass.getDeviceName(BleScanManage.this.context, device))) {
/*     */             try {
/* 209 */               if (ToolClass.getDeviceName(BleScanManage.this.context, device) != null) {
/* 210 */                 byte[] name = ParseLeAdvData.adv_report_parse((short)9, result.getScanRecord().getBytes());
/* 211 */                 if (name != null) {
/* 212 */                   moduleName = new String(name, "GBK");
/*     */                 }
/*     */               } 
/* 215 */             } catch (UnsupportedEncodingException e) {
/* 216 */               e.printStackTrace();
/*     */             } 
/*     */           }
/* 219 */           if (moduleName == null && device != null) {
/* 220 */             moduleName = ToolClass.getDeviceName(BleScanManage.this.context, device);
/*     */           }
/*     */ 
/*     */           
/* 224 */           String finalModuleName = moduleName;
/* 225 */           ((Activity)BleScanManage.this.context).runOnUiThread(() -> BleScanManage.this.addDeviceModel(device, result.getRssi(), finalModuleName, result));
/*     */         }
/*     */         
/*     */         public void onScanFailed(int errorCode) {
/* 229 */           super.onScanFailed(errorCode);
/* 230 */           ((Activity)BleScanManage.this.context).runOnUiThread(() -> Toast.makeText(BleScanManage.this.context, "扫描出错:" + errorCode, 0).show());
/*     */         }
/*     */       };
/*     */   }
/*     */   
/*     */   @RequiresApi(api = 21)
/*     */   private void setScanCallBackMessyCode(final List<DeviceModule> list) {
/* 237 */     this.mScanCallbackMessyCode = new ScanCallback()
/*     */       {
/*     */         public void onScanResult(int callbackType, ScanResult result) {
/* 240 */           BluetoothDevice device = result.getDevice();
/* 241 */           if (device == null)
/* 242 */             return;  boolean isEquals = false;
/* 243 */           int listNumber = 0;
/* 244 */           for (; listNumber < list.size(); listNumber++) {
/*     */             
/* 246 */             if (((DeviceModule)list.get(listNumber)).getMac().equals(device.getAddress()) && 
/* 247 */               ToolClass.pattern(((DeviceModule)list.get(listNumber)).getName())) {
/* 248 */               isEquals = true;
/*     */               
/*     */               break;
/*     */             } 
/*     */           } 
/* 253 */           if (!isEquals) {
/*     */             return;
/*     */           }
/* 256 */           String moduleName = null;
/* 257 */           if (null != result.getScanRecord() && ToolClass.pattern(ToolClass.getDeviceName(BleScanManage.this.context, device))) {
/*     */             try {
/* 259 */               byte[] name = ParseLeAdvData.adv_report_parse((short)9, result.getScanRecord().getBytes());
/* 260 */               if (name != null) {
/* 261 */                 moduleName = new String(name, "GBK");
/*     */               }
/* 263 */             } catch (UnsupportedEncodingException e) {
/* 264 */               e.printStackTrace();
/*     */             } 
/*     */           }
/* 267 */           if (moduleName == null) {
/* 268 */             moduleName = ToolClass.getDeviceName(BleScanManage.this.context, device);
/*     */           }
/* 270 */           list.remove(listNumber);
/* 271 */           list.add(listNumber, new DeviceModule(device, result.getRssi(), moduleName, BleScanManage.this.context, result));
/*     */         }
/*     */         
/*     */         public void onScanFailed(int errorCode) {
/* 275 */           super.onScanFailed(errorCode);
/* 276 */           ((Activity)BleScanManage.this.context).runOnUiThread(() -> Toast.makeText(BleScanManage.this.context, "扫描出错:" + errorCode, 0).show());
/*     */         }
/*     */       };
/*     */   }
/*     */ 
/*     */   
/*     */   private void addDeviceModel(BluetoothDevice device, int rssi, String name, ScanResult result) {
/* 283 */     if (this.mListDevices.size() == 0) {
/* 284 */       this.mListDevices.add(new DeviceModule(device, rssi, name, this.context, result));
/* 285 */       this.mIScanCallback.updateRecycler(this.mListDevices.get(0));
/*     */       
/*     */       return;
/*     */     } 
/* 289 */     for (DeviceModule mListDevice : this.mListDevices) {
/* 290 */       if (mListDevice.getDevice().toString().equals(device.toString())) {
/* 291 */         mListDevice.setRssi(rssi);
/* 292 */         mListDevice.updateIBeacon(device);
/* 293 */         this.mIScanCallback.updateRecycler(null);
/*     */         return;
/*     */       } 
/*     */     } 
/* 297 */     DeviceModule deviceModule = new DeviceModule(device, rssi, name, this.context, result);
/* 298 */     this.mListDevices.add(deviceModule);
/* 299 */     this.mIScanCallback.updateRecycler(deviceModule);
/*     */   }
/*     */   
/*     */   private void log(String str) {
/* 303 */     Log.d("AppRun" + getClass().getSimpleName(), str);
/* 304 */     if (this.mIDataCallback != null)
/* 305 */       this.mIDataCallback.readLog(getClass().getSimpleName(), str, "d"); 
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\BleScanManage.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */