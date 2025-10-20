/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.content.Context;
/*     */ import android.util.Log;
/*     */ import com.hc.bluetoothlibrary.tootl.ToolClass;
/*     */ import java.io.Serializable;
/*     */ 
/*     */ public class IBeaconClass
/*     */ {
/*     */   public static class iBeacon
/*     */     implements Serializable
/*     */   {
/*     */     public String beaconName;
/*     */     int major;
/*     */     int minor;
/*     */     String uuid;
/*     */     String bluetoothAddress;
/*     */     int txPower;
/*     */     int rssi;
/*     */     public double distance;
/*     */   }
/*     */   
/*     */   public static iBeacon fromScanData(Context context, BluetoothDevice device, int rssi, byte[] scanData) {
/*  25 */     if (scanData == null) {
/*  26 */       Log.e("AppRun", "scanData is null");
/*  27 */       return null;
/*     */     } 
/*     */     
/*  30 */     int startByte = 5;
/*  31 */     boolean patternFound = ((scanData[startByte + 2] & 0xFF) == 2 && (scanData[startByte + 3] & 0xFF) == 21);
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
/*     */ 
/*     */ 
/*     */     
/*  64 */     if (!patternFound)
/*     */     {
/*  66 */       return null;
/*     */     }
/*     */     
/*  69 */     iBeacon iBeacon = new iBeacon();
/*     */     
/*  71 */     iBeacon.major = (scanData[startByte + 20] & 0xFF) * 256 + (scanData[startByte + 21] & 0xFF);
/*  72 */     iBeacon.minor = (scanData[startByte + 22] & 0xFF) * 256 + (scanData[startByte + 23] & 0xFF);
/*  73 */     iBeacon.txPower = scanData[startByte + 24];
/*  74 */     iBeacon.rssi = rssi;
/*     */     
/*  76 */     iBeacon.distance = calculateAccuracy(iBeacon.txPower, iBeacon.rssi);
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
/*  89 */     byte[] proximityUuidBytes = new byte[16];
/*  90 */     System.arraycopy(scanData, startByte + 4, proximityUuidBytes, 0, 16);
/*  91 */     String hexString = bytesToHexString(proximityUuidBytes);
/*  92 */     if (hexString != null) {
/*  93 */       iBeacon
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */         
/* 101 */         .uuid = hexString.substring(0, 8) + "-" + hexString.substring(8, 12) + "-" + hexString.substring(12, 16) + "-" + hexString.substring(16, 20) + "-" + hexString.substring(20, 32);
/*     */     }
/*     */     
/* 104 */     if (device != null) {
/* 105 */       iBeacon.bluetoothAddress = device.getAddress();
/* 106 */       iBeacon.beaconName = ToolClass.getDeviceName(context, device);
/*     */     } 
/* 108 */     return iBeacon;
/*     */   }
/*     */   
/*     */   private static String bytesToHexString(byte[] src) {
/* 112 */     StringBuilder stringBuilder = new StringBuilder();
/* 113 */     if (src == null || src.length <= 0) {
/* 114 */       return null;
/*     */     }
/* 116 */     for (byte b : src) {
/* 117 */       int v = b & 0xFF;
/* 118 */       String hv = Integer.toHexString(v);
/* 119 */       if (hv.length() < 2) {
/* 120 */         stringBuilder.append(0);
/*     */       }
/* 122 */       stringBuilder.append(hv);
/*     */     } 
/* 124 */     return stringBuilder.toString();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private static double calculateAccuracy(int txPower, double rssi) {
/* 132 */     if (rssi == 0.0D) {
/* 133 */       return -1.0D;
/*     */     }
/*     */     
/* 136 */     double ratio = rssi / txPower;
/* 137 */     if (ratio < 1.0D) {
/* 138 */       return Math.pow(ratio, 10.0D);
/*     */     }
/* 140 */     return 0.89976D * Math.pow(ratio, 7.7095D) + 0.111D;
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\IBeaconClass.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */