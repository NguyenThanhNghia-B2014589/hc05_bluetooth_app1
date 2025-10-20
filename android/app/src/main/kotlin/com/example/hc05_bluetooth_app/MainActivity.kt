package com.example.hc05_bluetooth_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.hc.bluetoothlibrary.AllBluetoothManage
import com.hc.bluetoothlibrary.DeviceModule
import com.hc.bluetoothlibrary.IBluetooth

class MainActivity: FlutterActivity(), IBluetooth {
    private val METHOD_CHANNEL = "com.hc.bluetooth.method_channel"
    private val EVENT_CHANNEL = "com.hc.bluetooth.event_channel"

    private lateinit var bluetoothManage: AllBluetoothManage
    private var eventSink: EventChannel.EventSink? = null
    private val scannedDevices = mutableMapOf<String, DeviceModule>()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bluetoothManage = AllBluetoothManage(this, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            val device = scannedDevices[call.argument<String>("address")]
            when (call.method) {
                "startScan" -> {
                    scannedDevices.clear()
                    bluetoothManage.mixScan()
                    result.success("Đã bắt đầu quét hỗn hợp")
                }
                "stopScan" -> {
                    bluetoothManage.stopScan()
                    result.success("Đã dừng quét")
                }
                "connect" -> {
                    if (device != null) {
                        bluetoothManage.connect(device)
                        result.success("Đang yêu cầu kết nối...")
                    } else {
                        result.error("NOT_FOUND", "Thiết bị không có trong danh sách đã quét.", null)
                    }
                }
                "disconnect" -> {
                    if (device != null) {
                        bluetoothManage.disconnect(device)
                        result.success("Đã ngắt kết nối")
                    } else {
                        result.error("NOT_FOUND", "Thiết bị không tồn tại", null)
                    }
                }
                "sendData" -> {
                    val data = call.argument<ByteArray>("data")
                    if (device != null && data != null) {
                        val dataString = String(data, Charsets.UTF_8).trim()
                        android.util.Log.i("BluetoothDebug", "📤 GỬI: $dataString (${data.size} bytes)")
                        bluetoothManage.sendData(device, data)
                        result.success("Đã gửi dữ liệu")
                    } else {
                        result.error("ERROR", "Thiết bị hoặc dữ liệu không hợp lệ.", null)
                    }
                }
                "setVelocity" -> {
                    val level = call.argument<Int>("level")
                    if (level != null) {
                        try {
                            // Dùng Reflection để truy cập ModuleParameters
                            val moduleParamsClass = Class.forName("com.hc.bluetoothlibrary.tootl.ModuleParameters")
                            val setLevelMethod = moduleParamsClass.getMethod("setLevel", Int::class.javaPrimitiveType)
                            setLevelMethod.invoke(null, level)
                            
                            android.util.Log.i("BluetoothDebug", "⚙️ Đặt level: $level (delay = ${level * 10}ms)")
                            result.success("Đã đặt tốc độ thành công (delay = ${level * 10}ms)")
                        } catch (e: Exception) {
                            android.util.Log.e("BluetoothDebug", "❌ Lỗi setLevel: ${e.message}")
                            e.printStackTrace()
                            result.error("ERROR", "Lỗi khi đặt tốc độ: ${e.message}", null)
                        }
                    } else {
                        result.error("ERROR", "Level không hợp lệ", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }
    
    private fun sendEvent(event: Map<String, Any?>) { runOnUiThread { eventSink?.success(event) } }
    override fun updateList(device: DeviceModule?) {
        if (device != null) {
            scannedDevices[device.mac] = device
            android.util.Log.d("BluetoothDebug", "📡 Tìm thấy thiết bị: ${device.name} (${device.mac})")
            sendEvent(mapOf("type" to "scanResult", "name" to device.name, "address" to device.mac, "rssi" to device.rssi.toString()))
        }
    }
    override fun connectSucceed(module: DeviceModule?) {
        android.util.Log.d("BluetoothDebug", "✅ Kết nối thành công: ${module?.name} (${module?.mac})")
        sendEvent(mapOf("type" to "status", "status" to "connected", "message" to "Kết nối thành công tới ${module?.name}", "address" to module?.mac))
    }
    override fun errorDisconnect(device: DeviceModule?) {
        android.util.Log.e("BluetoothDebug", "❌ Mất kết nối: ${device?.name} (${device?.mac})")
        if (device != null) { bluetoothManage.disconnect(device) }
        sendEvent(mapOf("type" to "status", "status" to "disconnected", "message" to "Đã mất kết nối với ${device?.name ?: "thiết bị"}", "address" to device?.mac))
    }
    override fun readData(mac: String?, data: ByteArray?) {
        if (data != null) {
            val dataString = String(data, Charsets.UTF_8).trim()
            //android.util.Log.i("BluetoothDebug", "📥 NHẬN: $dataString (${data.size} bytes)")
            sendEvent(mapOf("type" to "dataReceived", "data" to data))
        }
    }
    override fun updateEnd() { sendEvent(mapOf("type" to "status", "status" to "scanFinished", "message" to "Quét hoàn tất")) }
    override fun updateMessyCode(p0: DeviceModule?) {}
    override fun reading(p0: Boolean) {}
    override fun readNumber(p0: Int) {}
    override fun readLog(p0: String?, p1: String?, p2: String?) {}
    override fun readVelocity(p0: Int) {}
    override fun callbackMTU(p0: Int) {}
}