package com.hc.bluetoothlibrary.tootl;

import com.hc.bluetoothlibrary.DeviceModule;

public interface IDataCallback {
  void readData(byte[] paramArrayOfbyte, String paramString);
  
  void connectionFail(String paramString1, String paramString2);
  
  void connectionSucceed(DeviceModule paramDeviceModule);
  
  void reading(boolean paramBoolean);
  
  void errorDisconnect(String paramString);
  
  void readNumber(int paramInt);
  
  void readLog(String paramString1, String paramString2, String paramString3);
  
  void readVelocity(int paramInt);
  
  void callbackMTU(int paramInt);
}


/* Location:              C:\TN\hcc\hc05_bluetooth_app\New folder\classes.jar!\com\hc\bluetoothlibrary\tootl\IDataCallback.class
 * Java compiler version: 8 (52.0)
 * JD-Core Version:       1.1.3
 */