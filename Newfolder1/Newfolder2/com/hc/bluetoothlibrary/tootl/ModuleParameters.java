/*     */ package com.hc.bluetoothlibrary.tootl;
/*     */ 
/*     */ import android.content.Context;
/*     */ import android.os.Build;
/*     */ 
/*     */ public class ModuleParameters
/*     */ {
/*   8 */   private static int state = 1;
/*     */   
/*  10 */   private static int bleReadBuff = 1000;
/*     */   
/*  12 */   private static int classicReadBuff = 1500;
/*     */   
/*     */   private static boolean isCheckNewline = true;
/*     */   
/*  16 */   private static int time = 100;
/*     */   
/*  18 */   private static int level = 0;
/*     */   
/*     */   private static final String partition = "/%partition%/";
/*     */   
/*     */   private static boolean isSendFile = false;
/*     */   
/*  24 */   private static int sendFileDelayedTime = 0;
/*     */   
/*     */   public static void setParameters(int state, int bleReadBuff, int classicReadBuff, int bleTime, Context context) {
/*  27 */     if (ModuleParameters.state != state || ModuleParameters.bleReadBuff != bleReadBuff || ModuleParameters.classicReadBuff != classicReadBuff || time != bleTime) {
/*  28 */       ModuleParameters.state = state;
/*  29 */       if (bleReadBuff < 0) bleReadBuff = 1; 
/*  30 */       ModuleParameters.bleReadBuff = bleReadBuff;
/*  31 */       if (classicReadBuff < 0) classicReadBuff = 1; 
/*  32 */       ModuleParameters.classicReadBuff = classicReadBuff;
/*  33 */       if (bleTime < 0) bleTime = 1; 
/*  34 */       time = bleTime;
/*  35 */       (new DataMemory(context)).saveParameters(state + "/%partition%/" + bleReadBuff + "/%partition%/" + classicReadBuff + "/%partition%/" + bleTime);
/*     */     } 
/*     */   }
/*     */   
/*     */   public static void setNewline(boolean isNewline) {
/*  40 */     isCheckNewline = isNewline;
/*     */   }
/*     */   
/*     */   public static void saveLevel(int moduleLevel, Context context) {
/*  44 */     if (level != moduleLevel) {
/*  45 */       level = moduleLevel;
/*  46 */       (new DataMemory(context)).saveModuleLevel(level);
/*     */     } 
/*     */   }
/*     */   
/*     */   public static void init(Context context) {
/*  51 */     DataMemory dataMemory = new DataMemory(context);
/*  52 */     String data = dataMemory.getParameters();
/*  53 */     level = dataMemory.getModuleLevel();
/*  54 */     if (data != null) {
/*  55 */       state = Integer.parseInt(ToolClass.analysis(data, 0, "/%partition%/"));
/*  56 */       bleReadBuff = Integer.parseInt(ToolClass.analysis(data, 1, "/%partition%/"));
/*  57 */       classicReadBuff = Integer.parseInt(ToolClass.analysis(data, 2, "/%partition%/"));
/*  58 */       time = Integer.parseInt(ToolClass.analysis(data, 3, "/%partition%/"));
/*     */     } 
/*     */   }
/*     */   
/*     */   public static int addLevel() {
/*  63 */     level++;
/*  64 */     if (level > 10) level = 10; 
/*  65 */     return level;
/*     */   }
/*     */   
/*     */   public static int minusLevel() {
/*  69 */     level--;
/*  70 */     if (level < 0) level = 0; 
/*  71 */     return level;
/*     */   }
/*     */   
/*     */   public static void setSendFile(boolean isSendFile) {
/*  75 */     ModuleParameters.isSendFile = isSendFile;
/*     */   }
/*     */   
/*     */   public static int getTime() {
/*  79 */     return time;
/*     */   }
/*     */   
/*     */   public static void setTime(int time) {
/*  83 */     ModuleParameters.time = time;
/*     */   }
/*     */   
/*     */   public static int getState() {
/*  87 */     if (system()) {
/*  88 */       return state + 2;
/*     */     }
/*  90 */     return state;
/*     */   }
/*     */   
/*     */   public static int getBleReadBuff() {
/*  94 */     return bleReadBuff;
/*     */   }
/*     */   
/*     */   public static int getClassicReadBuff() {
/*  98 */     return classicReadBuff;
/*     */   }
/*     */   public static boolean isCheckNewline() {
/* 101 */     return isCheckNewline;
/*     */   }
/*     */   public static int getLevel() {
/* 104 */     return level;
/*     */   }
/*     */   
/*     */   public static int getSendFileDelayedTime() {
/* 108 */     return sendFileDelayedTime;
/*     */   }
/*     */   
/*     */   public static void setSendFileDelayedTime(int delayedTime) {
/* 112 */     sendFileDelayedTime = delayedTime;
/*     */   }
/*     */   
/*     */   public static void addSendFileDelayedTime(int delayedTime) {
/* 116 */     sendFileDelayedTime += delayedTime;
/*     */   }
/*     */   
/*     */   public static boolean isSendFile() {
/* 120 */     return isSendFile;
/*     */   }
/*     */   
/*     */   public static boolean system() {
/* 124 */     String manufacturer = Build.MANUFACTURER;
/*     */     
/* 126 */     if ("huawei".equalsIgnoreCase(manufacturer)) {
/* 127 */       return true;
/*     */     }
/* 129 */     if ("honor".equalsIgnoreCase(manufacturer)) {
/* 130 */       return true;
/*     */     }
/* 132 */     return "rongyao".equalsIgnoreCase(manufacturer);
/*     */   }
/*     */ }


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\tootl\ModuleParameters.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */