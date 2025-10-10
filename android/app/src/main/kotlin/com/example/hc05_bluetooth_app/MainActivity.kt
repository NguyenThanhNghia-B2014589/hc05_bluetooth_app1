//android/app/src/main/kotlin/com/example/hc05_bluetooth_app/MainActivity.kt
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
                    scannedDevices.clear(); bluetoothManage.mixScan()
                    result.success("Đã bắt đầu quét hỗn hợp")
                }
                "stopScan" -> {
                    bluetoothManage.stopScan(); result.success("Đã dừng quét")
                }
                "connect" -> {
                    if (device != null) {
                        bluetoothManage.connect(device)
                        result.success("Đang yêu cầu kết nối...")
                    } else {
                        result.error("NOT_FOUND", "Thiết bị không có trong danh sách đã quét.", null)
                    }
                }
                "sendData" -> {
                    val data = call.argument<ByteArray>("data")
                    if (device != null && data != null) {
                        bluetoothManage.sendData(device, data)
                        result.success("Đã gửi dữ liệu")
                    } else {
                        result.error("ERROR", "Thiết bị hoặc dữ liệu không hợp lệ.", null)
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
    
    private fun sendEvent(event: Map<String, Any?>) {
        runOnUiThread { eventSink?.success(event) }
    }

    override fun updateList(device: DeviceModule?) {
        if (device != null) {
            scannedDevices[device.mac] = device
            sendEvent(mapOf("type" to "scanResult", "name" to device.name, "address" to device.mac, "rssi" to device.rssi.toString()))
        }
    }

    override fun connectSucceed(module: DeviceModule?) {
        sendEvent(mapOf("type" to "status", "status" to "connected", "message" to "Kết nối thành công tới ${module?.name}", "address" to module?.mac))
    }

    override fun errorDisconnect(device: DeviceModule?) {
        sendEvent(mapOf("type" to "status", "status" to "error", "message" to "Kết nối tới ${device?.name ?: "thiết bị"} thất bại.", "address" to device?.mac))
    }

    override fun readData(mac: String?, data: ByteArray?) {
        if (data != null) { sendEvent(mapOf("type" to "dataReceived", "data" to data)) }
    }

    override fun updateEnd() {
        sendEvent(mapOf("type" to "status", "status" to "scanFinished", "message" to "Quét hoàn tất"))
    }
    
    override fun updateMessyCode(p0: DeviceModule?) {}
    override fun reading(p0: Boolean) {}
    override fun readNumber(p0: Int) {}
    override fun readLog(p0: String?, p1: String?, p2: String?) {}
    override fun readVelocity(p0: Int) {}
    override fun callbackMTU(p0: Int) {}
}