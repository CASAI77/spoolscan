package com.spoolscan.spoolscan

import android.content.Intent
import android.nfc.NfcAdapter
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        // Consume NFC intents silently — nfc_manager's enableReaderMode
        // handles all tag processing. Without this, Android would dispatch
        // the tag to other apps or show a system NFC picker.
        if (intent.action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
            intent.action == NfcAdapter.ACTION_TAG_DISCOVERED ||
            intent.action == NfcAdapter.ACTION_TECH_DISCOVERED) {
            return
        }
        super.onNewIntent(intent)
    }
}
