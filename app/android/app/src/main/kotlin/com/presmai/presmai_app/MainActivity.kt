package com.presmai.presmai_app

import android.os.Bundle
import android.util.Log
import android.widget.Toast
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        FirebaseMessaging.getInstance().token.addOnCompleteListener(OnCompleteListener { task ->
            if (!task.isSuccessful) {
                Log.w(TAG, "Fetching FCM registration token failed", task.exception)
                return@OnCompleteListener
            }

            // Get new FCM registration token
            val token = task.result

            // Log and toast
            // val msg = getString(R.string.msg_token_fmt, token)
            // Note: R.string.msg_token_fmt might not exist, using a literal string for safety
            val msg = "FCM Token: $token"
            Log.d(TAG, msg)
            Toast.makeText(baseContext, msg, Toast.LENGTH_SHORT).show()
        })
    }
}
