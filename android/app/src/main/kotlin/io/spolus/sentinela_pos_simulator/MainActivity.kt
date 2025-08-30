package io.spolus.sentinela_app_pos_simulator

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.provider.Settings

class MainActivity : FlutterActivity() {

    private val CHANNEL_BLUETOOTH = "bluetooth_pairing"
    private val CHANNEL_KIOSK = "sunmi.kiosk"
    private val CHANNEL_LAUNCHER = "launcher_channel"
    private val MAINTENANCE_CHANNEL = "maintenance_channel"
    private val TAG = "MainActivity"
    private var hasPromptedForLauncher = false


    fun promptLauncherSelection(context: Context) {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    // Handler para reforçar o modo imersivo
    private val immersiveHandler = Handler(Looper.getMainLooper())
    private val immersiveRunnable = object : Runnable {
        override fun run() {
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                )
            immersiveHandler.postDelayed(this, 1500)
        }
    }

    override fun onResume() {
        super.onResume()
        immersiveHandler.post(immersiveRunnable)
    }

    override fun onPause() {
        super.onPause()
        immersiveHandler.removeCallbacks(immersiveRunnable)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                )
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                )
        }
    }

    private fun isKioskModeActive(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            false
        }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == applicationContext.packageName
    }

    @SuppressLint("MissingPermission")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_BLUETOOTH).setMethodCallHandler { call, result ->
            when (call.method) {
                "pairDevice" -> {
                    val macAddress = call.argument<String>("mac") ?: ""
                    val success = pairDevice(macAddress)
                    result.success(success)
                }

                "isBluetoothEnabled" -> {
                    val enabled = BluetoothAdapter.getDefaultAdapter()?.isEnabled == true
                    result.success(enabled)
                }

                "enableBluetooth" -> {
                    try {
                        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                        startActivityForResult(intent, 1234)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BLUETOOTH_ERROR", "Não foi possível ativar o Bluetooth", null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_KIOSK).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableKioskMode" -> {
                    val intent = Intent("sunmi.intent.action.KIOSK_MODE")
                    intent.putExtra("kiosk_mode", true)
                    sendBroadcast(intent)
                    result.success(true)
                }
                "disableKioskMode" -> {
                    val intent = Intent("sunmi.intent.action.KIOSK_MODE")
                    intent.putExtra("kiosk_mode", false)
                    sendBroadcast(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAINTENANCE_CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "openSettings") {
                try {
                    val intent = Intent(Settings.ACTION_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SETTINGS_ERROR", "Erro ao abrir configurações: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LAUNCHER)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "promptLauncherSelection" -> {
                        if (!isDefaultLauncher() && !hasPromptedForLauncher) {
                            hasPromptedForLauncher = true
                            try {
                                val intent = Intent(Intent.ACTION_MAIN).apply {
                                    addCategory(Intent.CATEGORY_HOME)
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e("Launcher", "Erro ao abrir intent: ${e.message}")
                                result.error("ERROR", "Falha ao abrir HOME chooser", e.localizedMessage)
                            }
                        } else {
                            result.success("Já é launcher padrão ou já solicitado")
                        }
                    }

                    else -> result.notImplemented()
                }
        }

    }

    @SuppressLint("MissingPermission")
    private fun pairDevice(macAddress: String): Boolean {
        val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            Log.e("Android Bluetooth", "Bluetooth não está disponível")
            return false
        }

        val device: BluetoothDevice? = bluetoothAdapter.getRemoteDevice(macAddress)
        if (device == null) {
            Log.e("Android Bluetooth", "Dispositivo não encontrado")
            return false
        }

        return try {
            val method = device.javaClass.getMethod("createBond")
            method.invoke(device)
            Log.i("Android Bluetooth", "Pareamento iniciado para $macAddress")
            true
        } catch (e: Exception) {
            Log.e("Android Bluetooth", "Erro ao parear: ${e.message}")
            false
        }
    }
}
