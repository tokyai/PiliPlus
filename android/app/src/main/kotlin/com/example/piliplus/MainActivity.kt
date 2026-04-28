package com.example.piliplus

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.SearchManager
import android.net.Uri
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
import android.util.Base64
import android.view.WindowManager.LayoutParams
import androidx.core.net.toUri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import dalvik.system.DexClassLoader
import kotlin.system.exitProcess
import java.io.File
import java.lang.reflect.Modifier
import java.util.Arrays
import java.util.jar.JarFile
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
                    result.success(sourceRuntimeProbe(call))
                }
                "sourceRuntimeExecute" -> {
                    result.success(sourceRuntimeExecute(call))
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
                "thunderIsSupported" -> {
                    result.success(
                        mapOf(
                            "success" to true,
                            "supported" to true,
                            "message" to "Thunder bridge fallback is available.",
                            "error" to ""
                        )
                    )
                }
                "thunderParseMagnet" -> {
                    result.success(thunderParseMagnet(call))
                }
                "thunderGetPlayUrl" -> {
                    result.success(thunderGetPlayUrl(call))
                }
                "thunderStopTask" -> {
                    result.success(thunderStopTask(call))
                }
                "thunderRelease" -> {
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "Thunder bridge released.",
                            "error" to ""
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun sourceRuntimeProbe(call: MethodCall): Map<String, Any?> {
        val engine = call.argument<String>("engine")?.trim()?.lowercase() ?: "unknown"
        val timeoutMs = (call.argument<Int>("timeoutMs") ?: 8000)
            .toLong()
            .coerceIn(500L, 120000L)
        val options = call.argument<Map<*, *>>("options") ?: emptyMap<Any?, Any?>()

        if (engine == "goproxy") {
            return mapOf(
                "success" to true,
                "stdout" to "",
                "stderr" to "",
                "elapsedMs" to 0,
                "exitCode" to 0,
                "isStub" to false,
                "message" to if (isGoProxyRunning()) {
                    "GoProxy process is running."
                } else {
                    "GoProxy process is not running."
                }
            )
        }

        if (engine == "jar") {
            val jarPath = options["jarPath"]?.toString()?.trim().orEmpty()
            if (jarPath.isEmpty()) {
                return sourceRuntimeFailure(
                    message = "Jar probe requires options.jarPath on Android.",
                    error = "empty_jar_path",
                    isStub = true
                )
            }
            val probe = probeJarFileInternal(jarPath)
            return mapOf(
                "success" to (probe["success"] == true),
                "stdout" to "path=${probe["path"]}",
                "stderr" to "",
                "elapsedMs" to 0,
                "exitCode" to if (probe["success"] == true) 0 else -1,
                "isStub" to false,
                "message" to (probe["message"]?.toString() ?: "Jar probe finished.")
            )
        }

        val command = resolveRuntimeCommand(engine, options)
            ?: return sourceRuntimeFailure(
                message = "No runtime command resolved for engine=$engine.",
                error = "command_not_found",
                isStub = false
            )

        val args = when (engine) {
            "python" -> listOf("--version")
            "nodejs", "catjs" -> listOf("--version")
            "php" -> listOf("--version")
            else -> {
                return sourceRuntimeFailure(
                    message = "Probe for engine=$engine is not supported in generic Android bridge.",
                    error = "unsupported_engine",
                    isStub = true
                )
            }
        }
        return runRuntimeCommand(
            command = command,
            args = args,
            timeoutMs = timeoutMs,
            options = options,
            engine = engine,
            action = "probe"
        )
    }

    private fun sourceRuntimeExecute(call: MethodCall): Map<String, Any?> {
        val engine = call.argument<String>("engine")?.trim()?.lowercase() ?: "unknown"
        val payload = call.argument<String>("payload") ?: ""
        val timeoutMs = (call.argument<Int>("timeoutMs") ?: 15000)
            .toLong()
            .coerceIn(500L, 120000L)
        val options = call.argument<Map<*, *>>("options") ?: emptyMap<Any?, Any?>()
        val useCodeMode = (options["executeAsCode"] as? Boolean) == true

        if (engine == "jar" || engine == "goproxy") {
            return sourceRuntimeFailure(
                message = "Engine=$engine uses dedicated bridge. Use /jarTest or /goProxyTest.",
                error = "dedicated_bridge_required",
                isStub = true
            )
        }

        val command = resolveRuntimeCommand(engine, options)
            ?: return sourceRuntimeFailure(
                message = "No runtime command resolved for engine=$engine.",
                error = "command_not_found",
                isStub = false
            )

        val payloadBase64 = Base64.encodeToString(
            payload.toByteArray(Charsets.UTF_8),
            Base64.NO_WRAP
        )
        val args = when (engine) {
            "python" -> if (useCodeMode) {
                listOf("-c", payload)
            } else {
                listOf(
                    "-c",
                    "import base64,sys;print(base64.b64decode(sys.argv[1]).decode('utf-8'))",
                    payloadBase64
                )
            }

            "nodejs", "catjs" -> if (useCodeMode) {
                listOf("-e", payload)
            } else {
                listOf(
                    "-e",
                    "console.log(Buffer.from(process.argv[1], 'base64').toString('utf8'))",
                    payloadBase64
                )
            }

            "php" -> if (useCodeMode) {
                listOf("-r", payload)
            } else {
                listOf(
                    "-r",
                    "echo base64_decode(\$argv[1]) . PHP_EOL;",
                    payloadBase64
                )
            }

            else -> {
                return sourceRuntimeFailure(
                    message = "Execute for engine=$engine is not supported in generic Android bridge.",
                    error = "unsupported_engine",
                    isStub = true
                )
            }
        }

        return runRuntimeCommand(
            command = command,
            args = args,
            timeoutMs = timeoutMs,
            options = options,
            engine = engine,
            action = "execute"
        )
    }

    private fun runRuntimeCommand(
        command: String,
        args: List<String>,
        timeoutMs: Long,
        options: Map<*, *>,
        engine: String,
        action: String
    ): Map<String, Any?> {
        val startedAt = System.currentTimeMillis()
        val workingDirectory = options["workingDirectory"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        val environment = parseStringMap(options["environment"])

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
            val process = processBuilder.start()
            val finished = process.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
            if (!finished) {
                process.destroy()
                process.waitFor(500, TimeUnit.MILLISECONDS)
                if (process.isAlive) {
                    process.destroyForcibly()
                }
            }
            val stdout = process.inputStream.bufferedReader().use { it.readText() }
            val stderr = process.errorStream.bufferedReader().use { it.readText() }
            val elapsedMs = System.currentTimeMillis() - startedAt
            val exitCode = if (finished) process.exitValue() else -1
            val success = finished && exitCode == 0
            mapOf(
                "success" to success,
                "stdout" to stdout,
                "stderr" to stderr,
                "elapsedMs" to elapsedMs,
                "exitCode" to exitCode,
                "isStub" to false,
                "message" to if (success) {
                    "Android $action success for $engine via $command."
                } else {
                    "Android $action failed for $engine via $command."
                }
            )
        } catch (e: Exception) {
            sourceRuntimeFailure(
                message = "Android $action exception for $engine via $command.",
                error = e.message ?: e.toString(),
                isStub = false,
                elapsedMs = System.currentTimeMillis() - startedAt
            )
        }
    }

    private fun resolveRuntimeCommand(engine: String, options: Map<*, *>): String? {
        val candidates = mutableListOf<String>()
        options["command"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }?.let { candidates.add(it) }
        candidates.addAll(parseStringList(options["commandCandidates"]))
        candidates.addAll(defaultRuntimeCommandCandidates(engine))

        var shellFallback: String? = null
        for (candidate in candidates.distinct()) {
            val trimmed = candidate.trim()
            if (trimmed.isEmpty()) continue
            if (trimmed.startsWith("/") || trimmed.contains("/")) {
                val resolved = if (trimmed.startsWith("/")) {
                    trimmed
                } else {
                    File(filesDir, trimmed).absolutePath
                }
                val file = File(resolved)
                if (file.exists() && file.canExecute()) {
                    return resolved
                }
            } else if (shellFallback == null) {
                shellFallback = trimmed
            }
        }
        return shellFallback
    }

    private fun defaultRuntimeCommandCandidates(engine: String): List<String> = when (engine) {
        "python" -> listOf(
            "tools/python/python",
            "tools/python",
            "/data/local/tmp/python3",
            "/data/local/tmp/python",
            "python3",
            "python"
        )

        "nodejs", "catjs" -> listOf(
            "tools/node/node",
            "tools/nodejs/node",
            "/data/local/tmp/node",
            "node"
        )

        "php" -> listOf(
            "tools/php/php",
            "tools/php",
            "/data/local/tmp/php",
            "php"
        )

        else -> emptyList()
    }

    private fun parseStringList(value: Any?): List<String> {
        val list = value as? List<*> ?: return emptyList()
        return list.mapNotNull { item ->
            item?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        }
    }

    private fun parseStringMap(value: Any?): Map<String, String> {
        val map = value as? Map<*, *> ?: return emptyMap()
        return map.mapNotNull { (key, item) ->
            val k = key as? String ?: return@mapNotNull null
            val v = item as? String ?: return@mapNotNull null
            k to v
        }.toMap()
    }

    private fun sourceRuntimeFailure(
        message: String,
        error: String,
        isStub: Boolean,
        elapsedMs: Long = 0
    ): Map<String, Any?> = mapOf(
        "success" to false,
        "stdout" to "",
        "stderr" to error,
        "elapsedMs" to elapsedMs,
        "exitCode" to -1,
        "isStub" to isStub,
        "message" to message
    )

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
        val resolvedJarFile = resolveRuntimePath(jarPath)
        val probe = probeJarFileInternal(resolvedJarFile.absolutePath)
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

        val options = call.argument<Map<*, *>>("options") ?: emptyMap<Any?, Any?>()
        val optionMainClass = options["mainClass"]?.toString()?.trim().orEmpty()
        val inferredMainClass = if (optionMainClass.isNotEmpty()) {
            optionMainClass
        } else {
            resolveJarMainClass(resolvedJarFile).orEmpty()
        }
        val resolvedEntryClass = when {
            entryClass.isNotEmpty() -> entryClass
            inferredMainClass.isNotEmpty() -> inferredMainClass
            else -> ""
        }

        if (resolvedEntryClass.isEmpty()) {
            return mapOf(
                "success" to false,
                "stdout" to "",
                "stderr" to "",
                "exitCode" to -1,
                "message" to "entryClass is required, or jar MANIFEST must provide Main-Class.",
                "error" to "empty_entry_class",
                "isStub" to false
            )
        }

        val invoke = invokeJarMethod(
            jarFile = resolvedJarFile,
            entryClass = resolvedEntryClass,
            methodName = if (methodName.isEmpty()) "main" else methodName,
            args = args,
            staticOnly = (options["staticOnly"] as? Boolean) == true
        )
        return mapOf(
            "success" to invoke.success,
            "stdout" to invoke.stdout,
            "stderr" to invoke.stderr,
            "exitCode" to invoke.exitCode,
            "message" to invoke.message,
            "error" to invoke.error,
            "isStub" to false
        )
    }

    private fun resolveJarMainClass(jarFile: File): String? {
        return try {
            JarFile(jarFile).use { jar ->
                jar.manifest?.mainAttributes?.getValue("Main-Class")?.trim()?.takeIf { it.isNotEmpty() }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun invokeJarMethod(
        jarFile: File,
        entryClass: String,
        methodName: String,
        args: List<String>,
        staticOnly: Boolean
    ): JarInvokeExecution {
        return try {
            val optimizedDir = File(codeCacheDir, "jar_opt").apply { mkdirs() }
            val loader = DexClassLoader(
                jarFile.absolutePath,
                optimizedDir.absolutePath,
                null,
                classLoader
            )
            val clazz = loader.loadClass(entryClass)
            val methods = clazz.methods.filter { it.name == methodName }
            if (methods.isEmpty()) {
                return JarInvokeExecution(
                    success = false,
                    stdout = "",
                    stderr = "",
                    exitCode = -1,
                    message = "Method not found: $entryClass#$methodName",
                    error = "method_not_found"
                )
            }

            var lastError = ""
            for (method in methods) {
                if (staticOnly && !Modifier.isStatic(method.modifiers)) {
                    continue
                }
                val bind = bindMethodArguments(method.parameterTypes, args) ?: run {
                    lastError = "unsupported_signature:${method.parameterTypes.joinToString(",") { it.name }}"
                    continue
                }
                val target = if (Modifier.isStatic(method.modifiers)) {
                    null
                } else {
                    clazz.getDeclaredConstructor().newInstance()
                }
                method.isAccessible = true
                val returnValue = method.invoke(target, *bind)
                return JarInvokeExecution(
                    success = true,
                    stdout = buildString {
                        appendLine("jarPath=${jarFile.absolutePath}")
                        appendLine("entryClass=$entryClass")
                        appendLine("method=$methodName")
                        appendLine("signature=${method.parameterTypes.joinToString(",") { it.simpleName }}")
                        append("result=${formatJarReturnValue(returnValue)}")
                    },
                    stderr = "",
                    exitCode = 0,
                    message = "Jar method invoked successfully.",
                    error = ""
                )
            }

            JarInvokeExecution(
                success = false,
                stdout = "",
                stderr = "",
                exitCode = -1,
                message = "No compatible method signature for $entryClass#$methodName",
                error = if (lastError.isNotEmpty()) lastError else "signature_not_supported"
            )
        } catch (e: Exception) {
            JarInvokeExecution(
                success = false,
                stdout = "",
                stderr = "",
                exitCode = -1,
                message = "Jar invoke failed.",
                error = e.message ?: e.toString()
            )
        }
    }

    private fun bindMethodArguments(
        parameterTypes: Array<Class<*>>,
        args: List<String>
    ): Array<Any?>? {
        if (parameterTypes.isEmpty()) {
            return if (args.isEmpty()) emptyArray() else null
        }
        if (parameterTypes.size == 1) {
            val type = parameterTypes[0]
            return when {
                type == String::class.java -> arrayOf(args.joinToString(","))
                type.isArray && type.componentType == String::class.java -> arrayOf(args.toTypedArray())
                List::class.java.isAssignableFrom(type) -> arrayOf(args)
                type == Int::class.java || type == Integer.TYPE -> {
                    if (args.size != 1) return null
                    arrayOf(args[0].toIntOrNull() ?: return null)
                }

                type == Long::class.java || type == java.lang.Long.TYPE -> {
                    if (args.size != 1) return null
                    arrayOf(args[0].toLongOrNull() ?: return null)
                }

                type == Boolean::class.java || type == java.lang.Boolean.TYPE -> {
                    if (args.size != 1) return null
                    arrayOf(args[0].toBooleanStrictOrNull() ?: return null)
                }

                else -> null
            }
        }
        if (parameterTypes.size == args.size && parameterTypes.all { it == String::class.java }) {
            return args.toTypedArray<Any?>()
        }
        return null
    }

    private fun formatJarReturnValue(value: Any?): String = when (value) {
        null -> "null"
        is Array<*> -> Arrays.toString(value)
        is IntArray -> Arrays.toString(value)
        is LongArray -> Arrays.toString(value)
        is FloatArray -> Arrays.toString(value)
        is DoubleArray -> Arrays.toString(value)
        is BooleanArray -> Arrays.toString(value)
        is ByteArray -> Arrays.toString(value)
        is ShortArray -> Arrays.toString(value)
        is CharArray -> Arrays.toString(value)
        else -> value.toString()
    }

    private fun String.toBooleanStrictOrNull(): Boolean? = when (this.lowercase()) {
        "true" -> true
        "false" -> false
        else -> null
    }

    private fun resolveRuntimePath(inputPath: String): File {
        val raw = inputPath.trim()
        if (raw.isEmpty()) {
            return File(raw)
        }
        return if (raw.startsWith("/")) {
            File(raw)
        } else {
            File(filesDir, raw)
        }
    }

    private data class JarInvokeExecution(
        val success: Boolean,
        val stdout: String,
        val stderr: String,
        val exitCode: Int,
        val message: String,
        val error: String
    )

    private fun thunderParseMagnet(call: MethodCall): Map<String, Any?> {
        val url = call.argument<String>("url")?.trim().orEmpty()
        if (url.isEmpty()) {
            return mapOf(
                "success" to false,
                "message" to "url is required.",
                "error" to "empty_url"
            )
        }
        val parsed = parseThunderLikeUrl(url)
            ?: return mapOf(
                "success" to false,
                "message" to "Unsupported url protocol.",
                "error" to "unsupported_protocol"
            )

        return mapOf(
            "success" to true,
            "protocol" to parsed.protocol,
            "originalUrl" to parsed.originalUrl,
            "normalizedUrl" to parsed.normalizedUrl,
            "infoHash" to parsed.infoHash,
            "message" to "Parsed successfully.",
            "error" to ""
        )
    }

    private fun thunderGetPlayUrl(call: MethodCall): Map<String, Any?> {
        val url = call.argument<String>("url")?.trim().orEmpty()
        if (url.isEmpty()) {
            return mapOf(
                "success" to false,
                "playUrl" to "",
                "message" to "url is required.",
                "error" to "empty_url"
            )
        }
        val parsed = parseThunderLikeUrl(url)
            ?: return mapOf(
                "success" to false,
                "playUrl" to "",
                "message" to "Unsupported url protocol.",
                "error" to "unsupported_protocol"
            )
        return mapOf(
            "success" to true,
            "playUrl" to parsed.normalizedUrl,
            "protocol" to parsed.protocol,
            "infoHash" to parsed.infoHash,
            "message" to "Play url resolved.",
            "error" to ""
        )
    }

    private fun thunderStopTask(call: MethodCall): Map<String, Any?> {
        val taskId = call.argument<String>("taskId")?.trim().orEmpty()
        return mapOf(
            "success" to true,
            "taskId" to taskId,
            "message" to "No active thunder task in fallback bridge.",
            "error" to ""
        )
    }

    private fun parseThunderLikeUrl(raw: String): ThunderParsedResult? {
        val input = raw.trim()
        if (input.isEmpty()) return null

        if (input.startsWith("thunder://", ignoreCase = true)) {
            val encoded = input.substringAfter("://", "")
            if (encoded.isEmpty()) return null
            return try {
                val decoded = String(Base64.decode(encoded, Base64.DEFAULT), Charsets.UTF_8)
                val unwrapped = decoded
                    .removePrefix("AA")
                    .removeSuffix("ZZ")
                    .trim()
                val nested = parseThunderLikeUrl(unwrapped) ?: ThunderParsedResult(
                    protocol = "thunder",
                    originalUrl = input,
                    normalizedUrl = unwrapped,
                    infoHash = ""
                )
                nested.copy(originalUrl = input)
            } catch (_: Exception) {
                null
            }
        }

        if (
            input.startsWith("magnet:", ignoreCase = true) ||
            input.startsWith("ed2k://", ignoreCase = true) ||
            input.startsWith("ftp://", ignoreCase = true) ||
            input.startsWith("http://", ignoreCase = true) ||
            input.startsWith("https://", ignoreCase = true)
        ) {
            val protocol = input.substringBefore(':').lowercase()
            val infoHash = if (protocol == "magnet") {
                extractMagnetInfoHash(input)
            } else {
                ""
            }
            return ThunderParsedResult(
                protocol = protocol,
                originalUrl = input,
                normalizedUrl = input,
                infoHash = infoHash
            )
        }
        return null
    }

    private fun extractMagnetInfoHash(url: String): String {
        return try {
            val uri = Uri.parse(url)
            val xt = uri.getQueryParameter("xt").orEmpty()
            if (xt.startsWith("urn:btih:", ignoreCase = true)) {
                xt.removePrefix("urn:btih:").trim()
            } else {
                ""
            }
        } catch (_: Exception) {
            ""
        }
    }

    private data class ThunderParsedResult(
        val protocol: String,
        val originalUrl: String,
        val normalizedUrl: String,
        val infoHash: String
    )

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
