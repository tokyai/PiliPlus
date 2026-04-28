package com.example.piliplus

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.SearchManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager.LayoutParams
import androidx.core.net.toUri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess
import java.io.File
import java.util.concurrent.TimeUnit

class MainActivity : AudioServiceActivity() {
    private lateinit var methodChannel: MethodChannel
    private var goProxyProcess: Process? = null
    private var goProxyUrl: String = "http://127.0.0.1:9978"
    private var goProxyLastError: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "PiliPlus")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "back" -> back();
                "biliSendCommAntifraud" -> {
                    try {
                        val action = call.argument<Int>("action") ?: 0
                        val oid = call.argument<Number>("oid") ?: 0L
                        val type = call.argument<Int>("type") ?: 0
                        val rpid = call.argument<Number>("rpid") ?: 0L
                        val root = call.argument<Number>("root") ?: 0L
                        val parent = call.argument<Number>("parent") ?: 0L
                        val ctime = call.argument<Number>("ctime") ?: 0L
                        val commentText = call.argument<String>("comment_text") ?: ""
                        val pictures = call.argument<String?>("pictures")
                        val sourceId = call.argument<String>("source_id") ?: ""
                        val uid = call.argument<Number>("uid") ?: 0L
                        val cookies = call.argument<List<String>>("cookies") ?: emptyList<String>()

                        val intent = Intent().apply {
                            component = ComponentName(
                                "icu.freedomIntrovert.biliSendCommAntifraud",
                                "icu.freedomIntrovert.biliSendCommAntifraud.ByXposedLaunchedActivity"
                            )
                            putExtra("action", action)
                            putExtra("oid", oid.toLong())
                            putExtra("type", type)
                            putExtra("rpid", rpid.toLong())
                            putExtra("root", root.toLong())
                            putExtra("parent", parent.toLong())
                            putExtra("ctime", ctime.toLong())
                            putExtra("comment_text", commentText)
                            if (pictures != null)
                                putExtra("pictures", pictures)
                            putExtra("source_id", sourceId)
                            putExtra("uid", uid.toLong())
                            putStringArrayListExtra("cookies", ArrayList(cookies))
                        }
                        startActivity(intent)
                    } catch (_: Exception) {
                    }
                }

                "linkVerifySettings" -> {
                    val uri = ("package:" + context.packageName).toUri()
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, uri)
                        } else {
                            Intent("android.intent.action.MAIN", uri).setClassName(
                                "com.android.settings",
                                "com.android.settings.applications.InstalledAppOpenByDefaultActivity"
                            )
                        }
                        context.startActivity(intent)
                    } catch (_: Throwable) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
                        context.startActivity(intent)
                    }
                }

                "music" -> {
                    val title = call.argument<String>("title")
                    val intent = Intent(MediaStore.INTENT_ACTION_MEDIA_SEARCH).apply {
                        putExtra(SearchManager.QUERY, title)
                        putExtra(MediaStore.EXTRA_MEDIA_TITLE, title)
                        call.argument<String?>("artist")
                            ?.let { putExtra(MediaStore.EXTRA_MEDIA_ARTIST, it) }
                        call.argument<String?>("album")
                            ?.let { putExtra(MediaStore.EXTRA_MEDIA_ALBUM, it) }

                        addCategory(Intent.CATEGORY_DEFAULT)
                    }
                    try {
                        if (packageManager.resolveActivity(
                                intent,
                                PackageManager.MATCH_DEFAULT_ONLY
                            ) != null
                        ) {
                            startActivity(intent)
                            result.success(true)
                            return@setMethodCallHandler
                        }
                    } catch (_: Throwable) {
                    }
                    try {
                        intent.action = MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH
                        if (packageManager.resolveActivity(
                                intent,
                                PackageManager.MATCH_DEFAULT_ONLY
                            ) != null
                        ) {
                            startActivity(intent)
                            result.success(true)
                            return@setMethodCallHandler
                        }
                    } catch (_: Throwable) {
                    }
                    result.success(false)
                }

                "setPipAutoEnterEnabled" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val params = PictureInPictureParams.Builder()
                            .setAutoEnterEnabled(call.argument<Boolean>("autoEnable") ?: false)
                            .build()
                        setPictureInPictureParams(params)
                    }
                }

                "createShortcut" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val shortcutManager =
                                context.getSystemService(ShortcutManager::class.java)
                            if (shortcutManager.isRequestPinShortcutSupported) {
                                val id = call.argument<String>("id")!!
                                val uri = call.argument<String>("uri")!!
                                val label = call.argument<String>("label")!!
                                val icon = call.argument<String>("icon")!!
                                val bitmap = BitmapFactory.decodeFile(icon)
                                val shortcut =
                                    ShortcutInfo.Builder(context, id)
                                        .setShortLabel(label)
                                        .setIcon(Icon.createWithAdaptiveBitmap(bitmap))
                                        .setIntent(Intent(Intent.ACTION_VIEW, uri.toUri()))
                                        .build()
                                val pinIntent =
                                    shortcutManager.createShortcutResultIntent(shortcut)
                                val pendingIntent = PendingIntent.getBroadcast(
                                    context, 0, pinIntent, PendingIntent.FLAG_IMMUTABLE
                                )
                                shortcutManager.requestPinShortcut(
                                    shortcut,
                                    pendingIntent.intentSender
                                )
                            }
                        } catch (e: Exception) {
                        }
                    }
                }
                "sourceRuntimeProbe" -> {
                    val engine = call.argument<String>("engine") ?: "unknown"
                    result.success(
                        mapOf(
                            "success" to false,
                            "stdout" to "",
                            "stderr" to "",
                            "elapsedMs" to 0,
                            "exitCode" to -1,
                            "isStub" to true,
                            "message" to "Android source runtime probe placeholder for engine=$engine. " +
                                    "Wire native bridge implementation here."
                        )
                    )
                }
                "sourceRuntimeExecute" -> {
                    val engine = call.argument<String>("engine") ?: "unknown"
                    val payload = call.argument<String>("payload") ?: ""
                    result.success(
                        mapOf(
                            "success" to false,
                            "stdout" to "engine=$engine\npayload=$payload",
                            "stderr" to "",
                            "elapsedMs" to 0,
                            "exitCode" to -1,
                            "isStub" to true,
                            "message" to "Android source runtime execute placeholder. " +
                                    "Replace with jar/php/proxy/thunder bridge implementation."
                        )
                    )
                }
                "startGoProxy" -> {
                    result.success(startGoProxy(call))
                }
                "stopGoProxy" -> {
                    result.success(stopGoProxy())
                }
                "isGoProxyRunning" -> {
                    result.success(isGoProxyRunning())
                }
                "getProxyUrl" -> {
                    result.success(goProxyUrl)
                }
                "detectGoProxyCommand" -> {
                    result.success(detectGoProxyCommand(call))
                }
                "prepareGoProxyBinary" -> {
                    result.success(prepareGoProxyBinary(call))
                }
                "probeJarFile" -> {
                    result.success(probeJarFile(call))
                }
                "loadJar" -> {
                    result.success(loadJar(call))
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun back() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun isGoProxyRunning(): Boolean = goProxyProcess?.isAlive == true

    private fun startGoProxy(call: MethodCall): Map<String, Any?> {
        if (isGoProxyRunning()) {
            return mapOf(
                "success" to true,
                "running" to true,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy is already running.",
                "error" to ""
            )
        }

        val commandInput = call.argument<String>("command")?.trim().orEmpty()
        val command = if (commandInput.isNotEmpty()) {
            commandInput
        } else {
            resolveGoProxyCommand(emptyList())
        }
        if (command.isNullOrEmpty()) {
            goProxyLastError = "Empty command and auto-detect failed."
            return mapOf(
                "success" to false,
                "running" to false,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy start failed.",
                "error" to goProxyLastError,
                "command" to ""
            )
        }

        val args = call.argument<List<String>>("args") ?: emptyList()
        val port = call.argument<Int>("port") ?: 9978
        val proxyUrl = call.argument<String>("proxyUrl")?.trim()
        val workingDirectory = call.argument<String>("workingDirectory")?.trim()
        val environment = (call.argument<Map<*, *>>("environment") ?: emptyMap<Any?, Any?>())
            .mapNotNull { (key, value) ->
                if (key is String && value is String) {
                    key to value
                } else {
                    null
                }
            }.toMap()

        return try {
            val commandLine = mutableListOf(command).apply { addAll(args) }
            val processBuilder = ProcessBuilder(commandLine).apply {
                if (!workingDirectory.isNullOrEmpty()) {
                    directory(File(workingDirectory))
                }
                if (environment.isNotEmpty()) {
                    environment().putAll(environment)
                }
                redirectErrorStream(false)
            }
            goProxyProcess = processBuilder.start()
            goProxyUrl = if (!proxyUrl.isNullOrEmpty()) proxyUrl else "http://127.0.0.1:$port"
            goProxyLastError = ""
            mapOf(
                "success" to true,
                "running" to true,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy process started.",
                "error" to "",
                "command" to command
            )
        } catch (e: Exception) {
            goProxyProcess = null
            goProxyLastError = e.message ?: e.toString()
            mapOf(
                "success" to false,
                "running" to false,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy start failed.",
                "error" to goProxyLastError,
                "command" to command
            )
        }
    }

    private fun stopGoProxy(): Map<String, Any?> {
        val process = goProxyProcess
        if (process == null) {
            return mapOf(
                "success" to true,
                "running" to false,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy is not running.",
                "error" to ""
            )
        }
        return try {
            process.destroy()
            process.waitFor(1500, TimeUnit.MILLISECONDS)
            if (process.isAlive) {
                process.destroyForcibly()
            }
            goProxyProcess = null
            mapOf(
                "success" to true,
                "running" to false,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy process stopped.",
                "error" to ""
            )
        } catch (e: Exception) {
            goProxyLastError = e.message ?: e.toString()
            mapOf(
                "success" to false,
                "running" to isGoProxyRunning(),
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy stop failed.",
                "error" to goProxyLastError
            )
        }
    }

    private fun detectGoProxyCommand(call: MethodCall): Map<String, Any?> {
        val candidates = call.argument<List<String>>("candidates") ?: emptyList()
        val command = resolveGoProxyCommand(candidates)
        return if (!command.isNullOrEmpty()) {
            mapOf(
                "success" to true,
                "command" to command,
                "message" to "GoProxy command detected.",
                "error" to "",
                "preparedFromAsset" to false
            )
        } else {
            mapOf(
                "success" to false,
                "command" to "",
                "message" to "No executable GoProxy command detected.",
                "error" to "not_found",
                "preparedFromAsset" to false
            )
        }
    }

    private fun prepareGoProxyBinary(call: MethodCall): Map<String, Any?> {
        val targetRelativePath = call.argument<String>("targetRelativePath")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "tools/goproxy"
        val appRoot = filesDir.canonicalFile
        val targetFile = File(appRoot, targetRelativePath).canonicalFile
        if (!targetFile.absolutePath.startsWith(appRoot.absolutePath)) {
            return mapOf(
                "success" to false,
                "command" to "",
                "message" to "Invalid targetRelativePath.",
                "error" to "invalid_target_path",
                "preparedFromAsset" to false
            )
        }

        try {
            targetFile.parentFile?.mkdirs()
            if (targetFile.exists() && targetFile.length() > 0) {
                targetFile.setExecutable(true, false)
                return mapOf(
                    "success" to true,
                    "command" to targetFile.absolutePath,
                    "message" to "GoProxy binary already prepared.",
                    "error" to "",
                    "preparedFromAsset" to false
                )
            }
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "command" to "",
                "message" to "Prepare target path failed.",
                "error" to (e.message ?: e.toString()),
                "preparedFromAsset" to false
            )
        }

        val assetCandidates = call.argument<List<String>>("assetCandidates")
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            ?: listOf("assets/runtime/goproxy", "assets/goproxy", "goproxy")
        val errors = mutableListOf<String>()
        for (candidate in assetCandidates) {
            val assetPath = candidate.removePrefix("/")
            try {
                assets.open(assetPath).use { input ->
                    targetFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                targetFile.setExecutable(true, false)
                return mapOf(
                    "success" to true,
                    "command" to targetFile.absolutePath,
                    "message" to "GoProxy binary prepared from asset: $assetPath",
                    "error" to "",
                    "preparedFromAsset" to true
                )
            } catch (e: Exception) {
                errors.add("$assetPath: ${e.message ?: e.toString()}")
            }
        }

        return mapOf(
            "success" to false,
            "command" to "",
            "message" to "Failed to prepare GoProxy binary from assets.",
            "error" to errors.joinToString(" | "),
            "preparedFromAsset" to false
        )
    }

    private fun resolveGoProxyCommand(rawCandidates: List<String>): String? {
        val candidates = rawCandidates
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toMutableList()
        candidates.add(File(filesDir, "tools/goproxy").absolutePath)
        candidates.add(File(filesDir, "goproxy").absolutePath)
        candidates.add("/data/local/tmp/goproxy")
        candidates.add("/system/bin/goproxy")
        candidates.add("/system/xbin/goproxy")
        for (candidate in candidates.distinct()) {
            val resolved = if (candidate.startsWith("/")) {
                candidate
            } else {
                File(filesDir, candidate).absolutePath
            }
            val file = File(resolved)
            if (file.exists() && file.canExecute()) {
                return resolved
            }
        }
        return null
    }

    private fun probeJarFile(call: MethodCall): Map<String, Any?> {
        val jarPath = call.argument<String>("jarPath")?.trim().orEmpty()
        if (jarPath.isEmpty()) {
            return mapOf(
                "success" to false,
                "exists" to false,
                "readable" to false,
                "size" to 0,
                "path" to "",
                "message" to "Jar path is empty.",
                "error" to "empty_jar_path"
            )
        }
        return probeJarFileInternal(jarPath)
    }

    private fun probeJarFileInternal(jarPath: String): Map<String, Any?> {
        return try {
            val file = File(jarPath)
            val exists = file.exists()
            val readable = exists && file.canRead()
            val size = if (exists) file.length() else 0L
            val success = exists && readable && size > 0
            mapOf(
                "success" to success,
                "exists" to exists,
                "readable" to readable,
                "size" to size,
                "path" to file.absolutePath,
                "message" to if (success) "Jar file is available." else "Jar file check failed.",
                "error" to if (success) "" else "jar_unavailable"
            )
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "exists" to false,
                "readable" to false,
                "size" to 0,
                "path" to jarPath,
                "message" to "Jar file check failed.",
                "error" to (e.message ?: e.toString())
            )
        }
    }

    private fun loadJar(call: MethodCall): Map<String, Any?> {
        val jarPath = call.argument<String>("jarPath")?.trim().orEmpty()
        val entryClass = call.argument<String>("entryClass")?.trim().orEmpty()
        val methodName = call.argument<String>("methodName")?.trim().orEmpty()
        val args = call.argument<List<String>>("args") ?: emptyList()
        if (jarPath.isEmpty()) {
            return mapOf(
                "success" to false,
                "stdout" to "",
                "stderr" to "",
                "exitCode" to -1,
                "message" to "Jar path is empty.",
                "error" to "empty_jar_path",
                "isStub" to true
            )
        }
        val probe = probeJarFileInternal(jarPath)
        val probeSuccess = probe["success"] == true
        if (!probeSuccess) {
            return mapOf(
                "success" to false,
                "stdout" to "",
                "stderr" to "",
                "exitCode" to -1,
                "message" to "Jar file check failed.",
                "error" to (probe["error"]?.toString() ?: "jar_unavailable"),
                "isStub" to true
            )
        }

        val stdout = buildString {
            appendLine("jarPath=$jarPath")
            appendLine("entryClass=$entryClass")
            appendLine("methodName=$methodName")
            appendLine("args=${args.joinToString(",")}")
        }.trim()
        return mapOf(
            "success" to true,
            "stdout" to stdout,
            "stderr" to "",
            "exitCode" to 0,
            "message" to "Jar loader bridge placeholder. File validated, execution not wired yet.",
            "error" to "",
            "isStub" to true
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun onDestroy() {
        stopGoProxy()
        stopService(Intent(this, com.ryanheise.audioservice.AudioService::class.java))
        super.onDestroy()
        android.os.Process.killProcess(android.os.Process.myPid())
        exitProcess(0)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        methodChannel.invokeMethod("onUserLeaveHint", null)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            "floating"
        ).invokeMethod("onPipChanged", isInPictureInPictureMode)
    }
}
