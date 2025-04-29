package com.example.pos_system

import android.graphics.*
import com.example.pos_system.channels.NfcPaymentHandler
import com.imin.image.ILcdManager
import com.imin.library.IminSDKManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val LCD_CHANNEL = "com.example.pos_system/lcdDisplay"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        NfcPaymentHandler(this, flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LCD_CHANNEL)

        channel.setMethodCallHandler { call, result ->
            if(call.method == "sdkInit") {
                try{
                    val value = ILcdManager.getInstance(this)
                    result.success(value)
                    //ILcdManager.getInstance(this).sendLCDCommand(1)
                    //result.success(true)
                }catch (e: Exception){
                    result.error("404", "Can't find display", null)
                }

            } else if (call.method == "sendString"){
                ILcdManager.getInstance(this).sendLCDString("OPTIMY")
                result.success(true)

            } else if (call.method == "multi string"){
                val strings3 = arrayOf("سعيد بلقائك", "Des", "嗨嗨")
                val colsAlign3 = intArrayOf(0, 1, 2)
                ILcdManager.getInstance(this).sendLCDMultiString(strings3,colsAlign3)
                result.success(true)

            } else if (call.method == "sendImg"){
                val imageBytes = call.arguments as ByteArray
                val imgBit = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ILcdManager.getInstance(this).sendLCDBitmap(imgBit)
                result.success(true)

            } else if(call.method == "clear"){
                ILcdManager.getInstance(this).sendLCDCommand(4)
                result.success(true)

            } else if(call.method == "cashBox"){
                IminSDKManager.opencashBox(this)
                result.success(true)

            } else {
                result.notImplemented()
            }
        }
    }
}
