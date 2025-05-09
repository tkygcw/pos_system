package com.example.pos_system.channels

import android.app.Activity
import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import com.example.pos_system.BuildConfig
import com.example.pos_system.channels.NfcPaymentUtils.isNfcEnabled
import com.example.pos_system.channels.NfcPaymentUtils.mapStatusCode
import com.google.gson.Gson
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.firebase.messaging.ContextHolder.getApplicationContext
import my.com.softspace.SSMobileAndroidUtilEngine.common.SharedHandler.runOnUiThread
import my.com.softspace.ssmpossdk.Environment
import my.com.softspace.ssmpossdk.SSMPOSSDK
import my.com.softspace.ssmpossdk.SSMPOSSDKConfiguration
import my.com.softspace.ssmpossdk.transaction.MPOSTransaction
import my.com.softspace.ssmpossdk.transaction.MPOSTransactionOutcome
import my.com.softspace.ssmpossdk.transaction.MPOSTransactionParams
import org.json.JSONObject

data class PaymentData(
    val amount: String? = null,
    val ref_no: String? = null,
    val transaction_id: String? = null
)


class NfcPaymentHandler(private val context: Context, flutterEngine: FlutterEngine) {
    private val CHANNEL_NAME = "optimy.com.my/nfcPayment"
    private val TRANSACTION_UI_EVENT_CHANNEL = "optimy.com.my/transactionUIEvent"
    private val TRANSACTION_EVENT_CHANNEL = "optimy.com.my/transactionEvent"
    private val INVALID_TOKEN = "Invalid token"

    private var channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    private var transactionUIEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, TRANSACTION_UI_EVENT_CHANNEL)
    private var transactionEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, TRANSACTION_EVENT_CHANNEL)
    private var trxUIEventSink: EventChannel.EventSink? = null
    private var trxEventSink: EventChannel.EventSink? = null
    private val activity = context as Activity
    private var _transactionOutcome: MPOSTransactionOutcome? = null

    @Volatile
    private var isTrxRunning = false
    private var isTokenValid = false

    init {
        transactionEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if(events == null) return
                    trxEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    trxEventSink = null
                }
            }
        )

        transactionUIEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if(events == null) return
                    trxUIEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    trxUIEventSink = null
                }
            }
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initPayment" -> {
                    initFasstapMPOSSDK(result)
                }
                "refreshToken" -> {
                    val uniqueID = call.arguments.toString()
                    refreshToken(uniqueID, result)
                }
                "startTrx" -> {
                    val value = call.arguments.toString()
                    val paymentData = Gson().fromJson(value, PaymentData::class.java)
                    if(paymentData.amount != null && paymentData.ref_no != null){
                        startTrx(paymentData.amount, paymentData.ref_no)
                    }
                    result.success(true)
                }
                "voidTrx" -> {
                    val value = call.arguments.toString()
                    val paymentData = Gson().fromJson(value, PaymentData::class.java)
                    if(paymentData.transaction_id != null){
                        voidTransaction(paymentData.transaction_id, result)
                    }
//                    result.success(true)
                }
                "cancelTrx" -> {
                    cancelTrx()
                    result.success(true)
                }
                "trxStatus" -> {
                    val value = call.arguments.toString()
                    val paymentData = Gson().fromJson(value, PaymentData::class.java)
                    if(paymentData.transaction_id != null || paymentData.ref_no != null){
                        getTransactionStatus(paymentData.transaction_id, paymentData.ref_no)
                    }
                    result.success(true)
                }
                "settlement" -> {
                    performSettlement(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun performSettlement(methodChannelResult: MethodChannel.Result) {
        Log.i("performSettlement", "performSettlement start")
        try {
            //check is token valid
            if(!isTokenValid) {
                methodChannelResult.error("performSettlement failed", INVALID_TOKEN, null)
                return
            }

            val transactionalParams = MPOSTransactionParams.Builder.create().build()

            SSMPOSSDK.getInstance().transaction.performSettlement(
                activity,
                transactionalParams,
                object : MPOSTransaction.TransactionEvents {
                    override fun onTransactionResult(
                        result: Int,
                        transactionOutcome: MPOSTransactionOutcome?
                    ) {
                        runOnUiThread {
                            Log.i("performSettlement", "onTransactionResult :: $result")
                            if (result != MPOSTransaction.TransactionEvents.TransactionResult.TransactionSuccessful && transactionOutcome != null) {
                                val outcome = "Status :: " + transactionOutcome.statusCode + " - " + transactionOutcome.statusMessage
                                methodChannelResult.success(outcome)
                            } else {
                                methodChannelResult.success(result)
                            }
                        }
                    }

                    override fun onTransactionUIEvent(event: Int) {
                        runOnUiThread {
//                            writeLog("onTransactionUIEvent :: $event")
//                            sendTrxUIEventSink(response(event, "onTransactionUIEvent :: $event"))
                        }
                    }
                })
        } catch (e: Exception) {
            methodChannelResult.error("performSettlement failed", e.message, e)
        }
    }

    private fun getTransactionStatus(transactionID: String?, referenceNo: String?) {
//        writeLog("getTransactionStatus()")
        Log.i("getTransactionStatus", "transactionID: ${transactionID}")
        try {
            var transactionalParams = MPOSTransactionParams.Builder.create().build()

            if (!transactionID.isNullOrEmpty()) {
                transactionalParams = MPOSTransactionParams.Builder.create()
                    .setMPOSTransactionID(transactionID)
                    .build()
            } else if (!referenceNo.isNullOrEmpty()) {
                transactionalParams = MPOSTransactionParams.Builder.create()
                    .setReferenceNumber(referenceNo)
                    .build()
            }

            SSMPOSSDK.getInstance().transaction.getTransactionStatus(
                activity,
                transactionalParams, object : MPOSTransaction.TransactionEvents {
                    override fun onTransactionResult(
                        result: Int,
                        transactionOutcome: MPOSTransactionOutcome?
                    ) {
                        runOnUiThread {
                            Log.i("getTransactionStatus", "onTransactionResult :: $result")
                            if (result == MPOSTransaction.TransactionEvents.TransactionResult.TransactionSuccessful) {
                                //Pending used
//                                if (transactionOutcome.statusCode == MainActivity.TRX_STATUS_APPROVED) {
//                                    btnVoidTrx.setEnabled(true)
//                                } else if (transactionOutcome.statusCode == MainActivity.TRX_STATUS_SETTLED) {
//                                    btnRefundTrx.setEnabled(true)
//                                }
                                if(transactionOutcome != null){
                                    var outcome =
                                        "Status :: " + transactionOutcome.statusCode + " - " + (if (mapStatusCode(
                                                transactionOutcome.statusCode
                                            ).isNotEmpty()
                                        ) mapStatusCode(transactionOutcome.statusCode) else transactionOutcome.statusMessage) + "\n"
                                    outcome += "Reference no :: " + transactionOutcome.referenceNo + "\n"
                                    outcome += "Amount auth :: " + transactionOutcome.amountAuthorized + "\n"
                                    outcome += "Transaction ID :: " + transactionOutcome.transactionID + "\n"
                                    outcome += "Transaction date :: " + transactionOutcome.transactionDate + "\n"
                                    outcome += "Batch no :: " + transactionOutcome.batchNo + "\n"
                                    outcome += "Approval code :: " + transactionOutcome.approvalCode + "\n"
                                    outcome += "Invoice no :: " + transactionOutcome.invoiceNo + "\n"
                                    outcome += "AID :: " + transactionOutcome.aid + "\n"
                                    outcome += "Card type :: " + transactionOutcome.cardType + "\n"
                                    outcome += "Application label :: " + transactionOutcome.applicationLabel + "\n"
                                    outcome += "Card number :: " + transactionOutcome.cardNo + "\n"
                                    outcome += "Cardholder name :: " + transactionOutcome.cardHolderName + "\n"
                                    outcome += "Trace no :: " + transactionOutcome.traceNo + "\n"
                                    outcome += "RRN :: " + transactionOutcome.rrefNo + "\n"
                                    outcome += "Transaction Date Time UTC :: " + transactionOutcome.transactionDateTime

                                    val jsonData = JSONObject().apply {
                                        put("trx_status_code", transactionOutcome.statusCode + " - " + (if (mapStatusCode(
                                                transactionOutcome.statusCode
                                            ).isNotEmpty()
                                        ) mapStatusCode(transactionOutcome.statusCode) else transactionOutcome.statusMessage))
                                        if (transactionOutcome.transactionID != null && transactionOutcome.transactionID.isNotEmpty()) {
                                            put("ref_no", transactionOutcome.referenceNo)
                                            put("amount_auth", transactionOutcome.amountAuthorized)
                                            put("transaction_id", transactionOutcome.transactionID)
                                            put("transaction_date", transactionOutcome.transactionDate)
                                            put("batch_no", transactionOutcome.batchNo)
                                            put("approval_code", transactionOutcome.approvalCode)
                                            put("invoice_no", transactionOutcome.invoiceNo)
                                            put("aid", transactionOutcome.aid)
                                            put("card_type", transactionOutcome.cardType)
                                            put("application_label", transactionOutcome.applicationLabel)
                                            put("card_number", transactionOutcome.cardNo)
                                            put("card_holder_name", transactionOutcome.cardHolderName)
                                            put("trace_no", transactionOutcome.traceNo)
                                            put("rrn", transactionOutcome.rrefNo)
                                            put("transaction_datetime", transactionOutcome.transactionDateTime)
                                        }
                                    }.toString()
                                    sendTrxEventSink(response(result, jsonData))

//                                    writeLog(outcome)
                                    Log.i("getTransactionStatus", outcome)

                                }
                            } else {
                                if (transactionOutcome != null) {
//                                    writeLog(transactionOutcome.statusCode + " - " + transactionOutcome.statusMessage)
                                    Log.i("getTransactionStatus failed", transactionOutcome.statusCode + " - " + transactionOutcome.statusMessage)
                                } else {
//                                    writeLog("Error ::$result")
                                    Log.i("getTransactionStatus failed", "transactionOutcome null: $result")
                                }
                            }
                        }
                    }

                    override fun onTransactionUIEvent(event: Int) {
                        runOnUiThread {
                            Log.i("getTransactionStatus", "onTransactionUIEvent :: $event")
//                            writeLog("onTransactionUIEvent :: $event")
                        }
                    }
                })
        } catch (e: Exception) {
//            Log.e(MainActivity.TAG, e.message, e)
            Log.e("getTransactionStatus", e.message, e)
        }
    }

    private fun voidTransaction(transactionID: String, methodChannelResult: MethodChannel.Result) {
        Log.i("voidTransaction", "transactionID: ${transactionID}")
        try {
            if(!isTokenValid) {
                methodChannelResult.error("voidTransaction", INVALID_TOKEN, null)
                return
            }
            var jsonData: String? = null
            val transactionalParams = MPOSTransactionParams.Builder.create()
                .setMPOSTransactionID(transactionID)
                .build()

            SSMPOSSDK.getInstance().transaction.voidTransaction(
                activity,
                transactionalParams,
                object : MPOSTransaction.TransactionEvents {
                    override fun onTransactionResult(
                        result: Int,
                        transactionOutcome: MPOSTransactionOutcome?
                    ) {
                        runOnUiThread {
                            Log.i("voidTransaction", "onTransactionResult :: $result")
                            Log.i("voidTransaction", "transactionOutcome :: ${transactionOutcome?.transactionID}")
                            if (result == MPOSTransaction.TransactionEvents.TransactionResult.TransactionSuccessful) {
                                if (transactionOutcome?.transactionID != null && transactionOutcome.transactionID.isNotEmpty()) {
                                    var outcome =
                                        "Status :: " + transactionOutcome.statusCode + " - " + (if (mapStatusCode(
                                                transactionOutcome.statusCode
                                            ).isNotEmpty()
                                        ) mapStatusCode(transactionOutcome.statusCode) else transactionOutcome.statusMessage) + "\n"
                                    outcome += "Transaction ID :: " + transactionOutcome.transactionID + "\n"
                                    outcome += "Reference no :: " + transactionOutcome.referenceNo + "\n"
                                    outcome += "Approval code :: " + transactionOutcome.approvalCode + "\n"
                                    outcome += "Invoice no :: " + transactionOutcome.invoiceNo + "\n"
                                    outcome += "AID :: " + transactionOutcome.aid + "\n"
                                    outcome += "Card type :: " + transactionOutcome.cardType + "\n"
                                    outcome += "Application label :: " + transactionOutcome.applicationLabel + "\n"
                                    outcome += "Card number :: " + transactionOutcome.cardNo + "\n"
                                    outcome += "Cardholder name :: " + transactionOutcome.cardHolderName + "\n"
                                    outcome += "RRN :: " + transactionOutcome.rrefNo + "\n"
                                    outcome += "Trace No :: " + transactionOutcome.traceNo + "\n"
                                    outcome += "Transaction Date Time UTC :: " + transactionOutcome.transactionDateTime
//                                    writeLog(outcome)
                                    jsonData = JSONObject().apply {
                                        put("trx_status_code", transactionOutcome.statusCode)
                                        if (mapStatusCode(transactionOutcome.statusCode).isNotEmpty()) {
                                            put("trx_status_msg", mapStatusCode(transactionOutcome.statusCode))
                                        } else {
                                            put("trx_status_msg", transactionOutcome.statusMessage)
                                        }
                                        if (transactionOutcome.transactionID != null && transactionOutcome.transactionID.isNotEmpty()) {
                                            put("transaction_id", transactionOutcome.transactionID)
                                            put("ref_no", transactionOutcome.referenceNo)
                                            put("approval_code", transactionOutcome.approvalCode)
                                            put("card_number", transactionOutcome.cardNo)
                                            put("card_holder_name", transactionOutcome.cardHolderName)
                                            put("acquirer_id", transactionOutcome.acquirerID)
                                            put("contactless_CVM_type", transactionOutcome.contactlessCVMType)
                                            put("rrn", transactionOutcome.rrefNo)
                                            put("transaction_datetime", transactionOutcome.transactionDateTime)
                                            put("trace_no", transactionOutcome.traceNo)
                                        }
                                    }.toString()
                                }
                            } else {
                                if (transactionOutcome != null) {
                                    jsonData = JSONObject().apply {
                                        put("trx_status_code", transactionOutcome.statusCode)
                                        put("trx_status_msg", transactionOutcome.statusMessage)
                                    }.toString()
                                    Log.i("voidTransaction", transactionOutcome.statusCode + " - " + transactionOutcome.statusMessage)
                                }
                            }
                            methodChannelResult.success(response(result, jsonData))
                        }
                    }

                    override fun onTransactionUIEvent(event: Int) {
                        runOnUiThread {
                            Log.i("voidTransaction", "onTransactionUIEvent :: $event")
                        }
                    }
                })
        } catch (e: Exception) {
            methodChannelResult.error("voidTransaction error", e.message, e)
            Log.e("voidTransaction", e.message, e)
        }
    }


    private fun startTrx(amount: String, referenceNo: String) {
        //check is token valid
        if(!isTokenValid) {
            sendTrxEventSink(response(3))
            return
        }
        //check is transaction running
        if(isTrxRunning){
            cancelTrx()
            return
        }
        //check nfc enable
        if (!isNfcEnabled(context)) {
            sendTrxEventSink(response(2))
            return
        }
        Log.i("startTrx", "nfc enable: " + isNfcEnabled(context))

        //toggle transaction running
        toggleTransactionRunning(true)

        if (SSMPOSSDK.requestPermissionIfRequired(activity, 10009)) {
            object : Thread() {
                override fun run() {
                    startEMVProcessing(amount, referenceNo)
                }
            }.start()
        } else {
            //toggle transaction not running
            toggleTransactionRunning(false)
        }
    }

    private fun cancelTrx() {
        toggleTransactionRunning(false, sendEvent = false)
        SSMPOSSDK.getInstance().transaction.abortTransaction()
        Log.i("startTrx", "transaction successfully cancelled")
    }

    private fun toggleTransactionRunning(isRunning: Boolean, sendEvent: Boolean? = true) {
        isTrxRunning = isRunning
        if(sendEvent == true){
            if(isTrxRunning){
                //send cancel trx event code
                sendTrxUIEventSink(response(1, "Cancel"))
            } else {
                //send payment event code
                sendTrxUIEventSink(response(0, "Start scan"))
            }
        }

    }

    private fun startEMVProcessing(amount: String, referenceNo: String) {
        try {
            _transactionOutcome = null

            val transactionalParams = MPOSTransactionParams.Builder.create()
                .setReferenceNumber(referenceNo)
                .setAmount(amount)
                .build()

            SSMPOSSDK.getInstance().transaction.startTransaction(
                activity,
                transactionalParams,
                object : MPOSTransaction.TransactionEvents {
                    override fun onTransactionResult(
                        result: Int,
                        transactionOutcome: MPOSTransactionOutcome?
                    ) {
                        _transactionOutcome = transactionOutcome
                        runOnUiThread {
                            Log.i("startEMVProcessing", "Ref no:: " + referenceNo)
                            Log.i("startEMVProcessing", "onTransactionResult :: $result")
                            if (result == MPOSTransaction.TransactionEvents.TransactionResult.TransactionSuccessful) {
                                if (transactionOutcome != null) {
                                    var outcome =
                                        "Transaction ID :: " + transactionOutcome.transactionID + "\n"
                                    outcome += "Reference No :: " + transactionOutcome.referenceNo + "\n"
                                    outcome += "Approval code :: " + transactionOutcome.approvalCode + "\n"
                                    outcome += "Card number :: " + transactionOutcome.cardNo + "\n"
                                    outcome += "Cardholder name :: " + transactionOutcome.cardHolderName + "\n"
                                    outcome += "Acquirer ID :: " + transactionOutcome.acquirerID + "\n"
                                    outcome += "Contactless CVM Type :: " + transactionOutcome.contactlessCVMType + "\n"
                                    outcome += "RRN :: " + transactionOutcome.rrefNo + "\n"
                                    outcome += "Trace No :: " + transactionOutcome.traceNo + "\n"
                                    outcome += "Transaction Date Time UTC :: " + transactionOutcome.transactionDateTime
                                    Log.i("startEMVProcessing", outcome)
                                    val jsonData = JSONObject().apply {
                                        put("transaction_id", transactionOutcome.transactionID)
                                        put("ref_no", transactionOutcome.referenceNo)
                                        put("approval_code", transactionOutcome.approvalCode)
                                        put("card_number", transactionOutcome.cardNo)
                                        put("card_holder_name", transactionOutcome.cardHolderName)
                                        put("acquirer_id", transactionOutcome.acquirerID)
                                        put("contactless_CVM_type", transactionOutcome.contactlessCVMType)
                                        put("rrn", transactionOutcome.rrefNo)
                                        put("transaction_datetime", transactionOutcome.transactionDateTime)
                                        put("trace_no", transactionOutcome.traceNo)
                                    }.toString()
                                    sendTrxEventSink(response(result, jsonData))

//                                    if (MainActivity.CARD_TYPE_VISA == transactionOutcome.cardType) {
//                                        animateVisaSensoryBranding()
//                                    } else if (MainActivity.CARD_TYPE_MASTERCARD == transactionOutcome.cardType) {
//                                        animateMastercardSensoryTransaction()
//                                    } else if (MainActivity.CARD_TYPE_AMEX == transactionOutcome.cardType) {
//                                        animateAmexSensoryTransaction()
//                                    } else if (MainActivity.CARD_TYPE_JCB == transactionOutcome.cardType) {
//                                        animateJCBSensoryTransaction()
//                                    } else if (MainActivity.CARD_TYPE_DISCOVER == transactionOutcome.cardType) {
//                                        animateDiscoverSensoryTransaction()
//                                    }
                                }
                            } else if (result == MPOSTransaction.TransactionEvents.TransactionResult.TransactionFailed) {
                                if (transactionOutcome != null) {
                                    var outcome = transactionOutcome.statusCode + " - " + transactionOutcome.statusMessage
                                    if (transactionOutcome.transactionID != null && transactionOutcome.transactionID.isNotEmpty()) {
                                        outcome += """

                                    Transaction ID :: ${transactionOutcome.transactionID}

                                    """.trimIndent()
                                        outcome += "Reference No :: " + transactionOutcome.referenceNo + "\n"
                                        outcome += "Approval code :: " + transactionOutcome.approvalCode + "\n"
                                        outcome += "Card number :: " + transactionOutcome.cardNo + "\n"
                                        outcome += "Cardholder name :: " + transactionOutcome.cardHolderName + "\n"
                                        outcome += "Acquirer ID :: " + transactionOutcome.acquirerID + "\n"
                                        outcome += "RRN :: " + transactionOutcome.rrefNo + "\n"
                                        outcome += "Trace No :: " + transactionOutcome.traceNo + "\n"
                                        outcome += "Transaction Date Time UTC :: " + transactionOutcome.transactionDateTime
                                    }
                                    val jsonData = JSONObject().apply {
                                        put("trx_status_code", transactionOutcome.statusCode)
                                        put("trx_status_msg", transactionOutcome.statusMessage)
                                        if (transactionOutcome.transactionID != null && transactionOutcome.transactionID.isNotEmpty()) {
                                            put("transaction_id", transactionOutcome.transactionID)
                                            put("ref_no", transactionOutcome.referenceNo)
                                            put("approval_code", transactionOutcome.approvalCode)
                                            put("card_number", transactionOutcome.cardNo)
                                            put("card_holder_name", transactionOutcome.cardHolderName)
                                            put("acquirer_id", transactionOutcome.acquirerID)
                                            put("contactless_CVM_type", transactionOutcome.contactlessCVMType)
                                            put("rrn", transactionOutcome.rrefNo)
                                            put("transaction_datetime", transactionOutcome.transactionDateTime)
                                            put("trace_no", transactionOutcome.traceNo)
                                        }
                                    }.toString()
                                    sendTrxEventSink(response(result, jsonData))
                                    Log.e("startEMVProcessing failed", outcome)
                                } else {
                                    sendTrxEventSink(response(result, "Error ::$result"))
                                    Log.e("startEMVProcessing failed", "Error ::$result")
                                }
                            }
                            toggleTransactionRunning(false)
                        }
                    }

                    override fun onTransactionUIEvent(event: Int) {
//                        writeLog("Event here $event")
                        Log.i("onTransactionUIEvent", "Event here $event")

                        runOnUiThread(object : Runnable {
                            override fun run() {
                                if (event == MPOSTransaction.TransactionEvents.TransactionUIEvent.CardReadOk) {
                                    // you may customize card reads OK sound & vibration, below is some example
                                    val toneGenerator = ToneGenerator(
                                        AudioManager.STREAM_MUSIC,
                                        ToneGenerator.MAX_VOLUME
                                    )
                                    toneGenerator.startTone(ToneGenerator.TONE_DTMF_P, 500)

                                    val v =
                                        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                                    if (v.hasVibrator()) {
                                        v.vibrate(
                                            VibrationEffect.createOneShot(
                                                200,
                                                VibrationEffect.DEFAULT_AMPLITUDE
                                            )
                                        )
                                    }

//                                    writeLog("Card read completed")
                                    sendTrxUIEventSink(response(event, "Card read completed"))
                                    Log.i("onTransactionUIEvent", "Card read completed")
                                } else if (event == MPOSTransaction.TransactionEvents.TransactionUIEvent.RequestSignature) {
//                                    writeLog("Signature is required")
                                    sendTrxUIEventSink(response(event, "Signature is required"))
                                    Log.i("onTransactionUIEvent", "Signature is required")
//                                    btnUploadSignature.setEnabled(true)
                                } else {
                                    when (event) {
                                        MPOSTransaction.TransactionEvents.TransactionUIEvent.PresentCard -> {
//                                            writeLog("Present your card")
                                            sendTrxUIEventSink(response(event, "Present your card"))
                                            Log.i("onTransactionUIEvent", "Present your card")
                                        }

                                        MPOSTransaction.TransactionEvents.TransactionUIEvent.Authorising -> {
//                                            writeLog("Authorising...")
                                            sendTrxUIEventSink(response(event, "Authorising"))
                                            Log.i("onTransactionUIEvent", "Authorising...")

                                        }

                                        MPOSTransaction.TransactionEvents.TransactionUIEvent.CardPresented -> {
//                                            writeLog("Card detected")
                                            sendTrxUIEventSink(response(event, "Card detected"))
                                            Log.i("onTransactionUIEvent", "Card detected")
                                        }

                                        MPOSTransaction.TransactionEvents.TransactionUIEvent.CardReadError -> {
                                            run {
//                                                writeLog("Card read failed")
                                                sendTrxUIEventSink(response(event, "Card read failed"))
                                                Log.i("onTransactionUIEvent", "Card read failed")
                                            }
                                            run {
//                                                writeLog("Card read retry")
                                                sendTrxUIEventSink(response(event, "Card read retry"))
                                                Log.i("onTransactionUIEvent", "Card read retry")
                                            }
                                        }

                                        MPOSTransaction.TransactionEvents.TransactionUIEvent.CardReadRetry -> {
//                                            writeLog("Card read retry")
                                            sendTrxUIEventSink(response(event, "Card read retry"))
                                            Log.i("onTransactionUIEvent", "Card read retry")
                                        }

                                        else -> {
//                                            writeLog("onTransactionUIEvent :: $event")
                                            sendTrxUIEventSink(response(event, "onTransactionUIEvent"))
                                            Log.i("onTransactionUIEvent", "onTransactionUIEvent :: $event")
                                        }
                                    }
                                }
                            }
                        })
                    }
                })
        } catch (e: Exception) {
            toggleTransactionRunning(false)
            Log.e("startTrx", e.message.toString())
            runOnUiThread {
                trxEventSink?.error("transactionError", e.message, e)
            }
        }
    }

    fun sendTrxEventSink(response: String){
        trxEventSink?.success(response)
    }

    fun sendTrxUIEventSink(response: String){
        trxUIEventSink?.success(response)
    }

    fun response(statusCode: Int, message: String? = null): String {
        val jsonData =  JSONObject().apply {
            put("status", statusCode)
            if(message != null){
                put("data", message)
            }
        }.toString()
        return jsonData
    }

    private fun refreshToken(uniqueID: String, methodChannelResult: MethodChannel.Result) {
        try{
            Log.i("refreshToken", "start refresh token")
            SSMPOSSDK.getInstance().ssmpossdkConfiguration.uniqueID = uniqueID
            SSMPOSSDK.getInstance().ssmpossdkConfiguration.developerID = "ZCh9mzZXqHzezf4"
            SSMPOSSDK.getInstance().transaction.refreshToken(
                activity,
                object : MPOSTransaction.TransactionEvents {
                    override fun onTransactionResult(
                        result: Int,
                        transactionOutcome: MPOSTransactionOutcome?
                    ) {
                        Log.i("refreshToken", "onTransactionResult :: $result")

                        if (result == MPOSTransaction.TransactionEvents.TransactionResult.TransactionSuccessful) {
                            isTokenValid = true
                            methodChannelResult.success(result)
                        } else {
                            isTokenValid = false
                            if (transactionOutcome != null) {
                                val outcome = transactionOutcome.statusCode + " - " + transactionOutcome.statusMessage
                                methodChannelResult.error(
                                    "Refresh token result: $result", outcome,
                                    "uniqueID: ${SSMPOSSDK.getInstance().ssmpossdkConfiguration.uniqueID}")
                            }
                        }
                    }

                    override fun onTransactionUIEvent(event: Int) {
                        //writeLog("onTransactionUIEvent :: $event")
                    }
                })
        }catch (e: Exception){
            trxEventSink?.error("refreshToken error", e.message.toString(), e)
            methodChannelResult.error("refreshToken error", e.message, e)
        }
    }

    private fun initFasstapMPOSSDK(methodChannelResult: MethodChannel.Result) {
        try {
            Log.i("init", "Init...")

            val config = SSMPOSSDKConfiguration.Builder.create()
                .setAttestationHost(BuildConfig.ATTESTATION_HOST)
                .setAttestationHostCertPinning(BuildConfig.ATTESTATION_CERT_PINNING)
                .setAttestationHostReadTimeout(10000L)
                .setAttestationRefreshInterval(300000L)
                .setAttestationStrictHttp(true)
                .setAttestationConnectionTimeout(30000L)
                .setLibGooglePlayProjNum("837940125447") // use own google play project number
                .setLibAccessKey(BuildConfig.ACCESS_KEY)
                .setLibSecretKey(BuildConfig.SECRET_KEY)
                .setUniqueID("") // please set the userID shared by Soft Space
                .setDeveloperID("")
                .setEnvironment(if (BuildConfig.FLAVOR_environment == "uat") Environment.UAT else Environment.PROD)
                .build()

            // SDK initialization require activity context
            SSMPOSSDK.init(context, config)
            var outcome = "SDK Version: " + SSMPOSSDK.getInstance().sdkVersion + "\n"
            outcome += "COTS ID: " + SSMPOSSDK.getInstance().cotsId
            methodChannelResult.success(outcome)

            Log.i("init", "SDK Version: " + SSMPOSSDK.getInstance().sdkVersion)
            Log.i("init", "COTS ID: " + SSMPOSSDK.getInstance().cotsId)

            Log.i("init", "has permission: " + SSMPOSSDK.hasRequiredPermission(getApplicationContext()))

            if (!SSMPOSSDK.hasRequiredPermission(getApplicationContext())) {
                SSMPOSSDK.requestPermissionIfRequired(activity, 1000)
            }
        } catch (e: Exception){
            methodChannelResult.error("initFasstapMPOSSDK error", e.message, null)
        }
    }



}