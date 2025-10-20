package com.hc.bluetoothlibrary;

public interface IBluetooth {
  void updateList(DeviceModule paramDeviceModule);
  
  void connectSucceed(DeviceModule paramDeviceModule);
  
  void updateEnd();
  
  void updateMessyCode(DeviceModule paramDeviceModule);
  
  void readData(String paramString, byte[] paramArrayOfbyte);
  
  void reading(boolean paramBoolean);
  
  void errorDisconnect(DeviceModule paramDeviceModule);
  
  void readNumber(int paramInt);
  
  void readLog(String paramString1, String paramString2, String paramString3);
  
  void readVelocity(int paramInt);
  
  void callbackMTU(int paramInt);
}


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\IBluetooth.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */