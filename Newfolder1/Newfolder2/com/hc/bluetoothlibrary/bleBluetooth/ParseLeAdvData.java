/*     */ package com.hc.bluetoothlibrary.bleBluetooth;
/*     */ 
/*     */ import java.io.UnsupportedEncodingException;
/*     */ import java.util.ArrayList;
/*     */ import java.util.List;
/*     */ import java.util.UUID;
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
/*     */ 
/*     */ 
/*     */ 
/*     */ public class ParseLeAdvData
/*     */ {
/*     */   private static final String TAG = "ParseLeAdvData";
/*     */   public static final short BLE_GAP_AD_TYPE_FLAGS = 1;
/*     */   public static final short BLE_GAP_AD_TYPE_16BIT_SERVICE_UUID_MORE_AVAILABLE = 2;
/*     */   public static final short BLE_GAP_AD_TYPE_16BIT_SERVICE_UUID_COMPLETE = 3;
/*     */   public static final short BLE_GAP_AD_TYPE_32BIT_SERVICE_UUID_MORE_AVAILABLE = 4;
/*     */   public static final short BLE_GAP_AD_TYPE_32BIT_SERVICE_UUID_COMPLETE = 5;
/*     */   public static final short BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_MORE_AVAILABLE = 6;
/*     */   public static final short BLE_GAP_AD_TYPE_128BIT_SERVICE_UUID_COMPLETE = 7;
/*     */   public static final short BLE_GAP_AD_TYPE_SHORT_LOCAL_NAME = 8;
/*     */   public static final short BLE_GAP_AD_TYPE_COMPLETE_LOCAL_NAME = 9;
/*     */   public static final short BLE_GAP_AD_TYPE_TX_POWER_LEVEL = 10;
/*     */   public static final short BLE_GAP_AD_TYPE_CLASS_OF_DEVICE = 13;
/*     */   public static final short BLE_GAP_AD_TYPE_SIMPLE_PAIRING_HASH_C = 14;
/*     */   public static final short BLE_GAP_AD_TYPE_SIMPLE_PAIRING_RANDOMIZER_R = 15;
/*     */   public static final short BLE_GAP_AD_TYPE_SECURITY_MANAGER_TK_VALUE = 16;
/*     */   public static final short BLE_GAP_AD_TYPE_SECURITY_MANAGER_OOB_FLAGS = 17;
/*     */   public static final short BLE_GAP_AD_TYPE_SLAVE_CONNECTION_INTERVAL_RANGE = 18;
/*     */   public static final short BLE_GAP_AD_TYPE_SOLICITED_SERVICE_UUIDS_16BIT = 20;
/*     */   public static final short BLE_GAP_AD_TYPE_SOLICITED_SERVICE_UUIDS_128BIT = 21;
/*     */   public static final short BLE_GAP_AD_TYPE_SERVICE_DATA = 22;
/*     */   public static final short BLE_GAP_AD_TYPE_PUBLIC_TARGET_ADDRESS = 23;
/*     */   public static final short BLE_GAP_AD_TYPE_RANDOM_TARGET_ADDRESS = 24;
/*     */   public static final short BLE_GAP_AD_TYPE_APPEARANCE = 25;
/*     */   public static final short BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA = 255;
/*     */   
/*     */   public static byte[] adv_report_parse(short type, byte[] adv_data) {
/*  70 */     int index = 0;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */     
/*  76 */     byte field_type = 0;
/*     */     
/*  78 */     byte field_length = 0;
/*     */     
/*  80 */     int length = adv_data.length;
/*     */     
/*  82 */     while (index < length) {
/*     */ 
/*     */       
/*     */       try {
/*     */ 
/*     */ 
/*     */ 
/*     */         
/*  90 */         field_length = adv_data[index];
/*     */         
/*  92 */         field_type = adv_data[index + 1];
/*     */ 
/*     */       
/*     */       }
/*  96 */       catch (Exception e) {
/*     */ 
/*     */ 
/*     */ 
/*     */         
/* 101 */         return null;
/*     */       } 
/*     */ 
/*     */       
/* 105 */       if (field_type == (byte)type) {
/*     */ 
/*     */ 
/*     */         
/* 109 */         byte[] data = new byte[field_length - 1];
/*     */         
/*     */         byte i;
/*     */         
/* 113 */         for (i = 0; i < field_length - 1; i = (byte)(i + 1))
/*     */         {
/*     */ 
/*     */           
/* 117 */           data[i] = adv_data[index + 2 + i];
/*     */         }
/*     */ 
/*     */         
/* 121 */         return data;
/*     */       } 
/*     */ 
/*     */       
/* 125 */       index += field_length + 1;
/*     */       
/* 127 */       if (index >= adv_data.length)
/*     */       {
/*     */ 
/*     */         
/* 131 */         return null;
/*     */       }
/*     */     } 
/*     */ 
/*     */ 
/*     */     
/* 137 */     return null;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static String getLocalName(byte[] adv_data) {
/* 147 */     byte[] data = adv_report_parse((short)9, adv_data);
/* 148 */     if (data != null) {
/* 149 */       return byteArrayToGbkString(data, 0, data.length);
/*     */     }
/* 151 */     return null;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static List<String> get16BitServiceUuids(byte[] adv_data) {
/* 160 */     List<String> list = new ArrayList<>();
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
/* 171 */     byte[] data = adv_report_parse((short)3, adv_data);
/* 172 */     if (data != null) {
/* 173 */       for (int i = 0; i < data.length / 2; i++) {
/* 174 */         byte[] by = { data[i * 2 + 1], data[i * 2] };
/* 175 */         String str = bytesToHexString(by, true);
/* 176 */         list.add(str);
/*     */       } 
/* 178 */       return list;
/*     */     } 
/* 180 */     return list;
/*     */   }
/*     */   
/*     */   public static String getShort16(byte[] adv_data) {
/* 184 */     byte[] data = adv_report_parse((short)3, adv_data);
/* 185 */     String dataStr = "";
/* 186 */     if (data != null) {
/* 187 */       for (int i = 0; i < data.length / 2; i++) {
/* 188 */         byte[] by = { data[i * 2 + 1], data[i * 2] };
/* 189 */         dataStr = dataStr + bytesToHexString(by, true);
/*     */       } 
/*     */     } else {
/* 192 */       data = adv_report_parse((short)2, adv_data);
/* 193 */       if (data != null) {
/* 194 */         for (int i = 0; i < data.length / 2; i++) {
/* 195 */           byte[] by = { data[i * 2 + 1], data[i * 2] };
/* 196 */           dataStr = dataStr + bytesToHexString(by, true);
/*     */         } 
/*     */       }
/*     */     } 
/*     */ 
/*     */     
/* 202 */     if (dataStr.equals("")) {
/* 203 */       return null;
/*     */     }
/* 205 */     return dataStr;
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
/*     */   private static String bytesToHexString(byte[] barray, boolean flag) {
/* 217 */     if (barray == null) {
/* 218 */       return "";
/*     */     }
/* 220 */     StringBuffer sb = new StringBuffer();
/*     */     
/* 222 */     for (int i = 0; i < barray.length; i++) {
/* 223 */       String stemp = Integer.toHexString(0xFF & barray[i]);
/* 224 */       if (stemp.length() < 2) {
/* 225 */         sb.append(0);
/*     */       }
/* 227 */       sb.append(stemp.toUpperCase());
/*     */     } 
/*     */     
/* 230 */     if (flag) {
/* 231 */       return "0x" + sb.toString();
/*     */     }
/* 233 */     return sb.toString();
/*     */   }
/*     */ 
/*     */   
/*     */   public static UUID decodeUuid128(byte[] adv_data, int i) {
/* 238 */     int j = decodeUuid32(adv_data, i + 12);
/* 239 */     int k = decodeUuid32(adv_data, i + 8);
/* 240 */     int l = decodeUuid32(adv_data, i + 4);
/* 241 */     int il = decodeUuid32(adv_data, i + 0);
/* 242 */     return new UUID((j << 32L) + (0xFFFFFFFFL & k), (l << 32L) + (0xFFFFFFFFL & il));
/*     */   }
/*     */   
/*     */   public static int decodeUuid32(byte[] adv_data, int i) {
/* 246 */     int j = 0xFF & adv_data[i];
/* 247 */     int k = 0xFF & adv_data[i + 1];
/* 248 */     int l = 0xFF & adv_data[i + 2];
/* 249 */     return j | (0xFF & adv_data[i + 3]) << 24 | l << 16 | k << 8;
/*     */   }
/*     */   
/*     */   private static String byteArrayToGbkString(byte[] inarray, int offset, int len) {
/* 253 */     String gbkstr = "";
/* 254 */     int idx = 0;
/* 255 */     if (inarray != null) {
/* 256 */       for (idx = 0; idx < len && 
/* 257 */         inarray[idx + offset] != 0; idx++);
/*     */ 
/*     */ 
/*     */       
/*     */       try {
/* 262 */         gbkstr = new String(inarray, offset, idx, "UTF-8");
/* 263 */       } catch (UnsupportedEncodingException unsupportedEncodingException) {}
/*     */     } 
/*     */ 
/*     */     
/* 267 */     return gbkstr;
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\bleBluetooth\ParseLeAdvData.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */