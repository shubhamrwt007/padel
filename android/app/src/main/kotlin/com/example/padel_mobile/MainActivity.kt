package com.matchacha.app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.matchacha.app/deeplink"
        private const val TAG = "DeepLinkDebug"
    }

    private var initialLink: String? = null
    private var installReferrer: String? = null
    private var methodChannel: MethodChannel? = null
    private var referrerClient: InstallReferrerClient? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        val data = intent?.data
        if (data != null && Intent.ACTION_VIEW == intent?.action) {
            initialLink = data.toString()
            Log.d(TAG, "onCreate: captured cold-start link=$initialLink")
        } else {
            Log.d(TAG, "onCreate: no deep link (action=${intent?.action})")
        }
        super.onCreate(savedInstanceState)
        fetchInstallReferrer()
    }

    private fun fetchInstallReferrer() {
        referrerClient = InstallReferrerClient.newBuilder(this).build()
        referrerClient?.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
                    val referrer = referrerClient?.installReferrer?.installReferrer
                    Log.d(TAG, "installReferrer raw: $referrer")
                    // Only store if it looks like our paymentId (not organic/unknown)
                    if (!referrer.isNullOrEmpty() && referrer != "utm_source=google-play&utm_medium=organic") {
                        installReferrer = referrer
                    }
                }
                referrerClient?.endConnection()
            }
            override fun onInstallReferrerServiceDisconnected() {
                Log.d(TAG, "installReferrer: service disconnected")
            }
        })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = intent.data
        Log.d(TAG, "onNewIntent: action=${intent.action} data=$data")
        if (data != null && Intent.ACTION_VIEW == intent.action) {
            val link = data.toString()
            Log.d(TAG, "onNewIntent: forwarding link=$link")
            if (methodChannel != null) {
                methodChannel?.invokeMethod("onNewLink", link)
            } else {
                initialLink = link
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine: initialLink=$initialLink")
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    Log.d(TAG, "getInitialLink called, returning: $initialLink")
                    result.success(initialLink)
                    initialLink = null
                }
                "getInstallReferrer" -> {
                    Log.d(TAG, "getInstallReferrer called, returning: $installReferrer")
                    result.success(installReferrer)
                    installReferrer = null
                }
                else -> result.notImplemented()
            }
        }
        val linkToSend = initialLink
        if (linkToSend != null) {
            Log.d(TAG, "configureFlutterEngine: pushing initial link proactively=$linkToSend")
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                methodChannel?.invokeMethod("onNewLink", linkToSend)
            }, 500)
        }
        Log.d(TAG, "configureFlutterEngine: channel ready")
    }

    override fun onDestroy() {
        methodChannel = null
        referrerClient?.endConnection()
        super.onDestroy()
    }
}
