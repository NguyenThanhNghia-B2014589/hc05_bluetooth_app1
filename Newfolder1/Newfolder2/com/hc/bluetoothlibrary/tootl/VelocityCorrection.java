/*     */ package com.hc.bluetoothlibrary.tootl;
/*     */ 
/*     */ import android.util.Log;
/*     */ import java.util.ArrayList;
/*     */ import java.util.List;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ public class VelocityCorrection
/*     */ {
/*  14 */   private static final List<Integer> velocityArray = new ArrayList<>();
/*     */   
/*     */   private static boolean isGather = true;
/*     */   
/*  18 */   private static int differenceValue = 0;
/*     */   
/*  20 */   private static int headData = 0;
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static synchronized boolean getVelocity(int velocity, int standardVelocity) {
/*  29 */     if (headData < 2) {
/*  30 */       headData++;
/*  31 */       return false;
/*     */     } 
/*     */     
/*  34 */     if (isGather) {
/*  35 */       if (velocity == 0) return false; 
/*  36 */       velocityArray.add(Integer.valueOf(velocity));
/*     */     } 
/*     */     
/*  39 */     if (isGather && velocityArray.size() >= 12) {
/*  40 */       isGather = false;
/*  41 */       return handlerData(standardVelocity);
/*     */     } 
/*  43 */     return false;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static int getDifferenceValue(int standardVelocity, int time) {
/*  53 */     if (time == 0) {
/*  54 */       differenceValue = 0;
/*  55 */       return 0;
/*     */     } 
/*  57 */     float value = differenceValue / standardVelocity;
/*  58 */     int temp = (int)(time + time * value * 5.0F);
/*  59 */     if (time > 12 && Math.abs(temp - time) <= 3) temp = time - 5; 
/*  60 */     if (time <= 12 && Math.abs(temp - time) <= 3) temp = time - 3; 
/*  61 */     differenceValue = 0;
/*  62 */     Log.w("AppRunService", "修正一次速率,延时为: " + temp + " time is " + time);
/*  63 */     return Math.max(temp, 0);
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   public static void setGather() {
/*  70 */     isGather = true;
/*  71 */     headData = 0;
/*     */   }
/*     */ 
/*     */ 
/*     */ 
/*     */ 
/*     */   
/*     */   private static boolean handlerData(int standardVelocity) {
/*  79 */     int maxPosition = 0, minPosition = 0, max = ((Integer)velocityArray.get(0)).intValue(), min = ((Integer)velocityArray.get(0)).intValue();
/*  80 */     int averageVelocity = 0;
/*  81 */     for (int i = 0; i < velocityArray.size(); i++) {
/*  82 */       if (((Integer)velocityArray.get(i)).intValue() > max) { max = ((Integer)velocityArray.get(i)).intValue(); maxPosition = i; }
/*  83 */        if (((Integer)velocityArray.get(i)).intValue() < min) { min = ((Integer)velocityArray.get(i)).intValue(); minPosition = i; }
/*     */     
/*  85 */     }  velocityArray.remove(maxPosition);
/*  86 */     velocityArray.remove(minPosition);
/*  87 */     for (Integer integer : velocityArray) {
/*  88 */       averageVelocity += integer.intValue();
/*     */     }
/*  90 */     averageVelocity /= 10;
/*  91 */     if (averageVelocity > standardVelocity * 1024 - 1024) {
/*  92 */       Log.w("AppRunService", "不需要修正...");
/*  93 */       return false;
/*     */     } 
/*     */     
/*  96 */     if (averageVelocity < standardVelocity * 1024 - 512) {
/*     */       
/*  98 */       differenceValue = (-(standardVelocity * 1024 + 512 - averageVelocity) / 1024 - (standardVelocity * 1024 + 512 - averageVelocity) % 1024 > 512) ? 1 : 0;
/*  99 */       Log.w("AppRunService", "提高速率: " + differenceValue);
/*     */     } 
/* 101 */     return true;
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\tootl\VelocityCorrection.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */