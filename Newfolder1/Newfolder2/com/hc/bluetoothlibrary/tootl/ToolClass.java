/*     */ package com.hc.bluetoothlibrary.tootl;
/*     */ 
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.content.Context;
/*     */ import android.location.LocationManager;
/*     */ import android.os.Build;
/*     */ import android.util.Log;
/*     */ import androidx.core.app.ActivityCompat;
/*     */ import java.util.ArrayList;
/*     */ import java.util.List;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class ToolClass
/*     */ {
/*     */   public static boolean pattern(String str) {
/*  19 */     if (str == null) return false; 
/*  20 */     if (str.contains("�")) return true; 
/*  21 */     int number = str.length();
/*  22 */     for (int i = 1; i < number; i++) {
/*  23 */       if (str.charAt(i - 1) == '�') {
/*  24 */         return true;
/*     */       }
/*     */     } 
/*  27 */     return false;
/*     */   }
/*     */ 
/*     */ 
/*     */   
/*     */   public static String analysis(String data, int number, String key) {
/*  33 */     if (number == 0)
/*  34 */       return data.substring(0, data.indexOf(key)); 
/*  35 */     if (number == 1) {
/*  36 */       String string = data.substring(data.indexOf(key) + key.length());
/*  37 */       return string.substring(0, string.indexOf(key));
/*     */     } 
/*  39 */     if (number == 2) {
/*  40 */       int length2 = analysis(data, 1, key).length();
/*  41 */       int length1 = analysis(data, 0, key).length();
/*  42 */       String string = data.substring(length1 + length2 + key.length() * 2);
/*  43 */       return string.substring(0, string.indexOf(key));
/*     */     } 
/*  45 */     int length = analysis(data, 0, key).length() + analysis(data, 1, key).length() + analysis(data, 2, key).length() + key.length() * 3;
/*  46 */     return data.substring(length);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static boolean isOpenGPS(Context context) {
/*  53 */     LocationManager locationManager = (LocationManager)context.getSystemService("location");
/*  54 */     boolean gps = true, network = true;
/*     */     
/*  56 */     if (locationManager != null) {
/*  57 */       gps = locationManager.isProviderEnabled("gps");
/*     */     }
/*  59 */     if (locationManager != null)
/*  60 */       network = locationManager.isProviderEnabled("network"); 
/*  61 */     return (gps || network);
/*     */   }
/*     */ 
/*     */   
/*     */   public static List<byte[]> getSendDataByte(byte[] buff, int mtu) {
/*  66 */     List<byte[]> listSendData = (List)new ArrayList<>();
/*  67 */     int[] sendDataLength = dataSeparate(buff.length, mtu);
/*  68 */     for (int i = 0; i < sendDataLength[0]; i++) {
/*  69 */       byte[] dataFor20 = new byte[mtu];
/*  70 */       System.arraycopy(buff, i * mtu, dataFor20, 0, mtu);
/*  71 */       listSendData.add(dataFor20);
/*     */     } 
/*     */     
/*  74 */     if (sendDataLength[1] > 0) {
/*  75 */       byte[] lastData = new byte[sendDataLength[1]];
/*  76 */       System.arraycopy(buff, sendDataLength[0] * mtu, lastData, 0, sendDataLength[1]);
/*  77 */       listSendData.add(lastData);
/*     */     } 
/*  79 */     return listSendData;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static boolean checkPermission(Context context) {
/*  88 */     if (Build.VERSION.SDK_INT < 31) return true; 
/*  89 */     if (context == null) return true;
/*     */     
/*  91 */     if (system()) return true; 
/*  92 */     return (ActivityCompat.checkSelfPermission(context, "android.permission.BLUETOOTH_SCAN") == 0);
/*     */   }
/*     */   
/*     */   public static String getDeviceName(Context context, BluetoothDevice device) {
/*  96 */     if (checkPermission(context)) return device.getName(); 
/*  97 */     return "N/A";
/*     */   }
/*     */ 
/*     */   
/*     */   private static int[] dataSeparate(int len, int mtu) {
/* 102 */     int[] lens = new int[2];
/* 103 */     lens[0] = len / mtu;
/* 104 */     lens[1] = len % mtu;
/* 105 */     return lens;
/*     */   }
/*     */ 
/*     */   
/*     */   public static boolean system() {
/* 110 */     String manufacturer = Build.MANUFACTURER;
/*     */     
/* 112 */     Log.w("AppRunTool", "机器名称: " + manufacturer);
/* 113 */     if ("huawei".equalsIgnoreCase(manufacturer)) {
/* 114 */       return true;
/*     */     }
/* 116 */     if ("honor".equalsIgnoreCase(manufacturer)) {
/* 117 */       return true;
/*     */     }
/* 119 */     return "hongmeng".equalsIgnoreCase(manufacturer);
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\tootl\ToolClass.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */