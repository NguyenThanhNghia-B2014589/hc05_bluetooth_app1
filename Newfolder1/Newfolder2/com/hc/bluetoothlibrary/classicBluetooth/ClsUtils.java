/*     */ package com.hc.bluetoothlibrary.classicBluetooth;
/*     */ 
/*     */ import android.bluetooth.BluetoothDevice;
/*     */ import android.util.Log;
/*     */ import java.lang.reflect.Field;
/*     */ import java.lang.reflect.Method;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class ClsUtils
/*     */ {
/*     */   public static boolean createBond(Class<?> btClass, BluetoothDevice btDevice) throws Exception {
/*  19 */     Method createBondMethod = btClass.getMethod("createBond", new Class[0]);
/*  20 */     Boolean returnValue = (Boolean)createBondMethod.invoke(btDevice, new Object[0]);
/*  21 */     return returnValue.booleanValue();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static boolean removeBond(Class<?> btClass, BluetoothDevice btDevice) throws Exception {
/*  31 */     Method removeBondMethod = btClass.getMethod("removeBond", new Class[0]);
/*  32 */     return ((Boolean)removeBondMethod.invoke(btDevice, new Object[0])).booleanValue();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static boolean setPin(Class<? extends BluetoothDevice> btClass, BluetoothDevice btDevice, String str) throws Exception {
/*     */     try {
/*  40 */       Method removeBondMethod = btClass.getDeclaredMethod("setPin", new Class[] { byte[].class });
/*     */ 
/*     */       
/*  43 */       Boolean returnValue = (Boolean)removeBondMethod.invoke(btDevice, new Object[] { str
/*     */             
/*  45 */             .getBytes() });
/*  46 */       Log.e("returnValue", "" + returnValue);
/*     */     }
/*  48 */     catch (SecurityException e) {
/*     */ 
/*     */       
/*  51 */       e.printStackTrace();
/*     */     }
/*  53 */     catch (IllegalArgumentException e) {
/*     */ 
/*     */       
/*  56 */       e.printStackTrace();
/*     */     }
/*  58 */     catch (Exception e) {
/*     */ 
/*     */       
/*  61 */       e.printStackTrace();
/*     */     } 
/*  63 */     return true;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static boolean cancelPairingUserInput(Class<?> btClass, BluetoothDevice device) throws Exception {
/*  71 */     Method createBondMethod = btClass.getMethod("cancelPairingUserInput", new Class[0]);
/*     */     
/*  73 */     return ((Boolean)createBondMethod.invoke(device, new Object[0])).booleanValue();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static boolean cancelBondProcess(Class<?> btClass, BluetoothDevice device) throws Exception {
/*  82 */     Method createBondMethod = btClass.getMethod("cancelBondProcess", new Class[0]);
/*  83 */     return ((Boolean)createBondMethod.invoke(device, new Object[0])).booleanValue();
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static void setPairingConfirmation(Class<?> btClass, BluetoothDevice device, boolean isConfirm) throws Exception {
/*  90 */     Method setPairingConfirmation = btClass.getDeclaredMethod("setPairingConfirmation", new Class[] { boolean.class });
/*  91 */     setPairingConfirmation.invoke(device, new Object[] { Boolean.valueOf(isConfirm) });
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
/*     */   public static void printAllInform(Class<?> clsShow) {
/*     */     try {
/* 104 */       Method[] hideMethod = clsShow.getMethods();
/* 105 */       int i = 0;
/* 106 */       for (; i < hideMethod.length; i++)
/*     */       {
/* 108 */         Log.e("method name", hideMethod[i].getName() + ";and the i is:" + i);
/*     */       }
/*     */ 
/*     */       
/* 112 */       Field[] allFields = clsShow.getFields();
/* 113 */       for (i = 0; i < allFields.length; i++)
/*     */       {
/* 115 */         Log.e("Field name", allFields[i].getName());
/*     */       }
/*     */     }
/* 118 */     catch (SecurityException e) {
/*     */ 
/*     */       
/* 121 */       e.printStackTrace();
/*     */     }
/* 123 */     catch (IllegalArgumentException e) {
/*     */ 
/*     */       
/* 126 */       e.printStackTrace();
/*     */     }
/* 128 */     catch (Exception e) {
/*     */ 
/*     */       
/* 131 */       e.printStackTrace();
/*     */     } 
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\classicBluetooth\ClsUtils.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */