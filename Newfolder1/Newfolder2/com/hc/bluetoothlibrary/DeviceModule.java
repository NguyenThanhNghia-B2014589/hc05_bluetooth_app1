/*     */ package com.hc.bluetoothlibrary;
/*     */ 
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.bluetooth.le.ScanRecord;
/*     */ import android.bluetooth.le.ScanResult;
/*     */ import android.content.Context;
/*     */ import android.os.Build;
/*     */ import android.util.Log;
/*     */ import com.hc.bluetoothlibrary.bleBluetooth.IBeaconClass;
/*     */ import com.hc.bluetoothlibrary.bleBluetooth.ParseLeAdvData;
/*     */ import com.hc.bluetoothlibrary.tootl.DataMemory;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.util.Objects;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class DeviceModule
/*     */ {
/*     */   private String mName;
/*     */   private final BluetoothDevice mDevice;
/*     */   private boolean isBLE = false;
/*     */   private int mRssi;
/*     */   private final boolean mBeenConnected;
/*     */   private ScanResult result;
/*     */   private DataMemory mDataMemory;
/*     */   private boolean isCollect = false;
/*     */   private boolean isConnected = false;
/*     */   private String mServiceUUID;
/*     */   private String mReadWriteUUID;
/*     */   private IBeaconClass.iBeacon mIBeacon;
/*  33 */   private int sendDataNumber = 0;
/*  34 */   private int acceptDataNumber = 0;
/*     */   
/*     */   private Context context;
/*     */ 
/*     */   
/*     */   public DeviceModule(BluetoothDevice device, int rssi, String name, Context context, ScanResult result) {
/*  40 */     this(name, device, false, context, rssi);
/*  41 */     this.result = result;
/*  42 */     this.context = context;
/*  43 */     if (Build.VERSION.SDK_INT >= 21 && result != null && result
/*  44 */       .getScanRecord() != null) {
/*  45 */       this.mIBeacon = IBeaconClass.fromScanData(context, device, rssi, result.getScanRecord().getBytes());
/*  46 */       if (this.mIBeacon != null) {
/*  47 */         this.mName = (this.mIBeacon.beaconName == null) ? "N/A" : this.mIBeacon.beaconName;
/*  48 */         this.isBLE = true;
/*     */       } 
/*     */     } 
/*  51 */     if (ToolClass.pattern(ToolClass.getDeviceName(context, device)) && context != null && 
/*  52 */       !ToolClass.pattern(name)) {
/*  53 */       this.mDataMemory = new DataMemory(context);
/*  54 */       this.mDataMemory.saveData(device.getAddress(), name);
/*  55 */       Log.d("AppRun" + getClass().getSimpleName(), "修正保存乱码文字..");
/*     */     } 
/*     */   }
/*     */ 
/*     */   
/*     */   public DeviceModule(String name, BluetoothDevice device) {
/*  61 */     this(name, device, false, (Context)null, 10);
/*     */   }
/*     */ 
/*     */   
/*     */   public DeviceModule(String name, BluetoothDevice device, boolean beenConnected, Context context, int rssi) {
/*  66 */     this.mName = name;
/*  67 */     this.mDevice = device;
/*  68 */     this.mBeenConnected = beenConnected;
/*  69 */     this.mRssi = rssi;
/*     */     
/*  71 */     if (device == null)
/*     */       return; 
/*  73 */     if (context != null) this.context = context;
/*     */     
/*  75 */     switch (getDeviceType(device)) {
/*     */       case 1:
/*     */       case 3:
/*  78 */         this.isBLE = false;
/*     */         break;
/*     */       case 2:
/*  81 */         this.isBLE = true;
/*     */         break;
/*     */     } 
/*     */     
/*  85 */     if (this.isBLE && context != null && (
/*  86 */       ToolClass.pattern(name) || ToolClass.pattern(ToolClass.getDeviceName(context, device)))) {
/*  87 */       String tempName = (new DataMemory(context)).getData(device.getAddress());
/*  88 */       if (tempName != null) {
/*  89 */         this.mName = tempName;
/*     */       }
/*     */     } 
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public String getName() {
/*  97 */     if (this.mName != null)
/*  98 */       return this.mName; 
/*  99 */     if (ToolClass.getDeviceName(this.context, this.mDevice) != null) {
/* 100 */       this.mName = ToolClass.getDeviceName(this.context, this.mDevice);
/*     */     } else {
/* 102 */       this.mName = "N/A";
/*     */     } 
/* 104 */     return this.mName;
/*     */   }
/*     */   
/*     */   public String getOriginalName(Context context) {
/* 108 */     this.mName = ToolClass.getDeviceName(context, getDevice());
/* 109 */     if (this.isBLE && context != null && 
/* 110 */       ToolClass.pattern(this.mName)) {
/* 111 */       String tempName = (new DataMemory(context)).getData(getMac());
/* 112 */       if (tempName != null) {
/* 113 */         this.mName = tempName;
/*     */       }
/*     */     } 
/*     */     
/* 117 */     if (this.mName == null) this.mName = "N/A"; 
/* 118 */     return this.mName;
/*     */   }
/*     */   
/*     */   public BluetoothDevice getDevice() {
/* 122 */     return this.mDevice;
/*     */   }
/*     */   
/*     */   public String getMac() {
/* 126 */     if (this.mDevice != null) {
/* 127 */       return this.mDevice.getAddress();
/*     */     }
/* 129 */     return "出错了";
/*     */   }
/*     */ 
/*     */   
/*     */   public void setMessyCode(Context context) {
/* 134 */     if (context != null) {
/* 135 */       String tempName = (new DataMemory(context)).getData(getMac());
/* 136 */       if (tempName != null) {
/* 137 */         Log.d("AppRun" + getClass().getSimpleName(), "修正成功..");
/* 138 */         this.mName = tempName;
/*     */       } 
/*     */     } 
/*     */   }
/*     */   
/*     */   public void setRssi(int rssi) {
/* 144 */     this.mRssi = rssi;
/*     */   }
/*     */   
/*     */   public void updateIBeacon(BluetoothDevice device) {
/* 148 */     if (this.mIBeacon != null && Build.VERSION.SDK_INT >= 21) {
/*     */       try {
/* 150 */         this.mIBeacon = IBeaconClass.fromScanData(this.context, device, this.mRssi, (
/* 151 */             (ScanRecord)Objects.<ScanRecord>requireNonNull(this.result.getScanRecord())).getBytes());
/* 152 */       } catch (Exception e) {
/* 153 */         e.printStackTrace();
/*     */       } 
/*     */     }
/*     */   }
/*     */   
/*     */   public void setUUID(String service, String readWrite) {
/* 159 */     Log.w("AppRunDeviceModule", "设置服务: " + service + "  读写特征: " + readWrite);
/* 160 */     if (service != null) this.mServiceUUID = service; 
/* 161 */     if (readWrite != null) this.mReadWriteUUID = readWrite; 
/*     */   }
/*     */   
/*     */   public void setCollectModule(Context context, String name) {
/* 165 */     if (this.mDataMemory != null) {
/* 166 */       this.mDataMemory.saveCollectData(getMac(), name);
/*     */     } else {
/* 168 */       this.mDataMemory = new DataMemory(context);
/* 169 */       this.mDataMemory.saveCollectData(getMac(), name);
/*     */     } 
/*     */     
/* 172 */     if (name == null) {
/* 173 */       getOriginalName(context);
/* 174 */       this.isCollect = false;
/*     */     } 
/*     */   }
/*     */   
/*     */   public void isCollectName(Context context) {
/*     */     String s;
/* 180 */     if (this.mDataMemory != null) {
/* 181 */       s = this.mDataMemory.getCollectData(getMac());
/*     */     } else {
/* 183 */       this.mDataMemory = new DataMemory(context);
/* 184 */       s = this.mDataMemory.getCollectData(getMac());
/*     */     } 
/* 186 */     if (s != null) {
/* 187 */       this.isCollect = true;
/* 188 */       this.mName = s;
/*     */     } 
/*     */   }
/*     */   
/*     */   public int getRssi() {
/* 193 */     return this.mRssi;
/*     */   }
/*     */   
/*     */   public boolean isBLE() {
/* 197 */     return this.isBLE;
/*     */   }
/*     */   
/*     */   public boolean isBeenConnected() {
/* 201 */     return this.mBeenConnected;
/*     */   }
/*     */   
/*     */   public String bluetoothType() {
/* 205 */     if (this.isBLE) {
/* 206 */       return "Ble蓝牙";
/*     */     }
/* 208 */     if (this.mBeenConnected) {
/* 209 */       return "已配对";
/*     */     }
/* 211 */     return "未配对";
/*     */   }
/*     */ 
/*     */   
/*     */   public boolean isCollect() {
/* 216 */     return this.isCollect;
/*     */   }
/*     */   
/*     */   public boolean isHcModule(boolean isCheck, String dataFilter) {
/* 220 */     String data = null;
/*     */     try {
/* 222 */       if (this.result != null && Build.VERSION.SDK_INT >= 21) {
/* 223 */         data = ParseLeAdvData.getShort16(this.result.getScanRecord().getBytes());
/*     */       }
/* 225 */     } catch (Exception e) {
/* 226 */       e.printStackTrace();
/*     */     } 
/*     */     
/* 229 */     if (data != null) {
/* 230 */       if (!isCheck) {
/* 231 */         return (data.equals("0xFFE0") || data.equals("0xFFF0"));
/*     */       }
/* 233 */       if (dataFilter != null) {
/* 234 */         return data.equals("0x" + dataFilter.toUpperCase());
/*     */       }
/* 236 */       return true;
/*     */     } 
/*     */     
/* 239 */     return false;
/*     */   }
/*     */ 
/*     */   
/*     */   public String getReadWriteUUID() {
/* 244 */     if (this.mReadWriteUUID != null)
/* 245 */       return this.mReadWriteUUID; 
/* 246 */     if (!this.isBLE) {
/* 247 */       return "没有读写特征";
/*     */     }
/* 249 */     return null;
/*     */   }
/*     */   
/*     */   public String getServiceUUID() {
/* 253 */     if (this.mServiceUUID != null) {
/* 254 */       return this.mServiceUUID;
/*     */     }
/* 256 */     return "00001101-0000-1000-8000-00805F9B34FB";
/*     */   }
/*     */ 
/*     */   
/*     */   public boolean equals(DeviceModule deviceModule) {
/* 261 */     if (deviceModule == null) return false; 
/* 262 */     if (getMac() == null) return false; 
/* 263 */     return getMac().equals(deviceModule.getMac());
/*     */   }
/*     */   
/*     */   public IBeaconClass.iBeacon getIBeacon() {
/* 267 */     return this.mIBeacon;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public boolean isConnected() {
/* 274 */     return this.isConnected;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public void setConnected(boolean connected) {
/* 281 */     this.isConnected = connected;
/*     */   }
/*     */ 
/*     */   
/*     */   public void saveDataNumber(int sendDataNumber, int acceptDataNumber) {
/* 286 */     this.sendDataNumber = sendDataNumber;
/* 287 */     this.acceptDataNumber = acceptDataNumber;
/*     */   }
/*     */   
/*     */   public int getSendDataNumber() {
/* 291 */     return this.sendDataNumber;
/*     */   }
/*     */   
/*     */   public int getAcceptDataNumber() {
/* 295 */     return this.acceptDataNumber;
/*     */   }
/*     */   
/*     */   public void addAcceptDataNumber(int acceptDataNumber) {
/* 299 */     this.acceptDataNumber += acceptDataNumber;
/*     */   }
/*     */   
/*     */   private int getDeviceType(BluetoothDevice device) {
/* 303 */     if (ToolClass.checkPermission(this.context)) return device.getType(); 
/* 304 */     return 1;
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\DeviceModule.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */