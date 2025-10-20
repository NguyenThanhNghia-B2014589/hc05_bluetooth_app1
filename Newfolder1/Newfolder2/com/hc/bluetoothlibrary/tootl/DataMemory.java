/*    */ package com.hc.bluetoothlibrary.tootl;
/*    */ 
/*    */ import android.annotation.SuppressLint;
/*    */ import android.content.Context;
/*    */ import android.content.SharedPreferences;
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ 
/*    */ public class DataMemory
/*    */ {
/*    */   private final SharedPreferences sp;
/* 14 */   private final String collect = "collect";
/* 15 */   private final String parameters = "parameters";
/* 16 */   private final String level = "ModuleLevel";
/*    */   @SuppressLint({"WrongConstant"})
/*    */   public DataMemory(Context context) {
/* 19 */     this.sp = context.getSharedPreferences("data", 33554432);
/*    */   }
/*    */ 
/*    */   
/*    */   public void saveData(String mac, String name) {
/* 24 */     SharedPreferences.Editor editor = this.sp.edit();
/* 25 */     editor.putString(mac, name);
/* 26 */     editor.apply();
/*    */   }
/*    */   
/*    */   public String getData(String mac) {
/* 30 */     return this.sp.getString(mac, null);
/*    */   }
/*    */   
/*    */   public void saveCollectData(String mac, String name) {
/* 34 */     SharedPreferences.Editor editor = this.sp.edit();
/* 35 */     editor.putString("collect" + mac, name);
/* 36 */     editor.apply();
/*    */   }
/*    */   
/*    */   public String getCollectData(String mac) {
/* 40 */     return this.sp.getString("collect" + mac, null);
/*    */   }
/*    */   
/*    */   public void saveParameters(String data) {
/* 44 */     SharedPreferences.Editor editor = this.sp.edit();
/* 45 */     editor.putString("parameters", data);
/* 46 */     editor.apply();
/*    */   }
/*    */   
/*    */   public void saveModuleLevel(int value) {
/* 50 */     SharedPreferences.Editor editor = this.sp.edit();
/* 51 */     editor.putInt("ModuleLevel", value);
/* 52 */     editor.apply();
/*    */   }
/*    */   
/*    */   public int getModuleLevel() {
/* 56 */     return this.sp.getInt("ModuleLevel", 0);
/*    */   }
/*    */   
/*    */   public String getParameters() {
/* 60 */     return this.sp.getString("parameters", null);
/*    */   }
/*    */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\tootl\DataMemory.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */