package com.example.pos_system.channels

import android.content.Context
import android.nfc.NfcAdapter

object NfcPaymentUtils {
    private const val TRX_STATUS_APPROVED: String = "100"
    private const val TRX_STATUS_REVERSED: String = "101"
    private const val TRX_STATUS_VOIDED: String = "102"
    private const val TRX_STATUS_PENDING_SIGNATURE: String = "103"
    private const val TRX_STATUS_SETTLED: String = "104"
    private const val TRX_STATUS_PENDING_TC: String = "105"
    private const val TRX_STATUS_REFUNDED: String = "106"

     fun mapStatusCode(code: String): String {
        when (code) {
            TRX_STATUS_APPROVED -> return "Approved"

            TRX_STATUS_REVERSED -> return "Reversed"

            TRX_STATUS_VOIDED -> return "Voided"

            TRX_STATUS_PENDING_SIGNATURE -> return "Pending Signature"

            TRX_STATUS_SETTLED -> return "Settled"

            TRX_STATUS_PENDING_TC -> return "Pending TC"

            TRX_STATUS_REFUNDED -> return "Refunded"
        }
        return code
    }

    fun isNfcEnabled(context: Context): Boolean {
        val adapter = NfcAdapter.getDefaultAdapter(context)
        if (adapter != null) {
            if (adapter.isEnabled) {
                return true
            } else {
                return false
            }
        }

        // NFC not supported
        return false
    }
}