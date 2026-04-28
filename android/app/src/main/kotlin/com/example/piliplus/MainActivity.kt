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
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.lang.reflect.Modifier
import java.net.HttpURLConnection
import java.net.URL
import java.util.Arrays
import java.util.jar.JarFile
import java.util.concurrent.TimeUnit
import java.util.zip.GZIPInputStream
import java.util.zip.ZipInputStream

class MainActivity : AudioServiceActivity() {
    private lateinit var methodChannel: MethodChannel
    private var goProxyProcess: Process? = null
    private var goProxyUrl: String = "http://127.0.0.1:9978"
    private var goProxyLastError: String = ""
    private var goProxyLastCommand: String = ""
    private var goProxyLastArgs: List<String> = emptyList()
    private var goProxyLastWorkingDirectory: String = ""
    private var goProxyStartedAtMs: Long = 0L
    private var goProxyLastPort: Int = 9978
    private var goProxyLastDanmuDir: String = ""
    private var goProxyForegroundLastError: String = ""
    private var goProxyLastExitCode: Int? = null
    private var goProxyLastExitedAtMs: Long = 0L
    private val phpServerProcesses = mutableListOf<Process>()
    private val phpServerPorts = mutableListOf<Int>()
    private var phpServerRunning: Boolean = false
    private var phpServerPort: Int = 9980
    private var phpServerDocumentRoot: String = ""
    private var phpServerStartedAtMs: Long = 0L
    private val jarRuntimeLock = Any()
    private val loadedJarSpiders = linkedMapOf<String, JarSpiderRuntime>()
    private val crashedJarSpiders = linkedSetOf<String>()
    private val recentJarSpiders = linkedMapOf<String, String?>()
    private val jarSpiderContexts = linkedMapOf<String, JarSpiderExecutionContext>()
    private val thunderRuntimeLock = Any()
    private val thunderActiveTasks = linkedMapOf<String, ThunderTaskState>()
    private var thunderTaskSequence = 0L

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
                "getGoProxyRuntimeState" -> {
                    result.success(getGoProxyRuntimeState())
                }
                "detectGoProxyCommand" -> {
                    result.success(detectGoProxyCommand(call))
                }
                "prepareGoProxyBinary" -> {
                    result.success(prepareGoProxyBinary(call))
                }
                "startServer" -> {
                    result.success(phpStartServer(call))
                }
                "stopServer" -> {
                    result.success(phpStopServer())
                }
                "isServerRunning" -> {
                    result.success(phpIsServerRunning())
                }
                "getServerPort" -> {
                    result.success(phpServerPort)
                }
                "installPhp" -> {
                    result.success(phpInstall(call))
                }
                "isInstalled" -> {
                    result.success(phpIsInstalled())
                }
                "getVersion" -> {
                    result.success(phpGetVersion())
                }
                "getExtensions" -> {
                    result.success(phpGetExtensions())
                }
                "getScriptsDir" -> {
                    result.success(phpGetScriptsDir())
                }
                "executeCode" -> {
                    result.success(phpExecuteCode(call))
                }
                "getPhpDir" -> {
                    result.success(phpGetPhpDir())
                }
                "getDefaultDownloadUrl" -> {
                    result.success(phpDefaultDownloadUrl())
                }
                "getPhpRuntimeState" -> {
                    result.success(getPhpRuntimeState())
                }
                "probeJarFile" -> {
                    result.success(probeJarFile(call))
                }
                "loadJar" -> {
                    result.success(loadJar(call))
                }
                "destroySpider" -> {
                    result.success(destroySpider(call))
                }
                "markSpiderCrashed" -> {
                    result.success(markSpiderCrashed(call))
                }
                "isSpiderCrashed" -> {
                    result.success(isSpiderCrashed(call))
                }
                "getCrashedSpiderCount" -> {
                    result.success(getCrashedSpiderCount())
                }
                "clearCrashedSpiders" -> {
                    result.success(clearCrashedSpiders())
                }
                "clearAll" -> {
                    result.success(clearAllJarSpiders())
                }
                "getJarRuntimeState" -> {
                    result.success(getJarRuntimeState())
                }
                "homeContent" -> {
                    result.success(homeContent(call))
                }
                "homeVideoContent" -> {
                    result.success(homeVideoContent(call))
                }
                "categoryContent" -> {
                    result.success(categoryContent(call))
                }
                "searchContent" -> {
                    result.success(searchContent(call))
                }
                "detailContent" -> {
                    result.success(detailContent(call))
                }
                "playerContent" -> {
                    result.success(playerContent(call))
                }
                "action" -> {
                    result.success(action(call))
                }
                "setRecent" -> {
                    result.success(setRecent(call))
                }
                "thunderIsSupported" -> {
                    result.success(
                        mapOf(
                            "success" to true,
                            "supported" to true,
                            "message" to "Thunder bridge fallback is available.",
                            "activeTaskCount" to thunderActiveTaskCount(),
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
                    result.success(thunderRelease())
                }
                "getThunderRuntimeState" -> {
                    result.success(getThunderRuntimeState())
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
        val optionsRaw = call.argument<Map<*, *>>("options") ?: emptyMap<Any?, Any?>()
        val options = withEngineRuntimeOptions(engine, optionsRaw)

        if (engine == "goproxy") {
            val state = getGoProxyRuntimeState()
            return mapOf(
                "success" to (state["success"] == true),
                "stdout" to formatGoProxyRuntimeStateSnapshot(state),
                "stderr" to "",
                "elapsedMs" to 0,
                "exitCode" to 0,
                "isStub" to false,
                "message" to (state["message"]?.toString() ?: "GoProxy runtime probe finished.")
            )
        }

        if (engine == "php") {
            val state = getPhpRuntimeState()
            val success = state["success"] == true
            return mapOf(
                "success" to success,
                "stdout" to formatPhpRuntimeStateSnapshot(state),
                "stderr" to if (success) "" else (state["error"]?.toString().orEmpty()),
                "elapsedMs" to 0,
                "exitCode" to if (success) 0 else -1,
                "isStub" to false,
                "message" to (state["message"]?.toString() ?: "PHP runtime probe finished.")
            )
        }

        if (engine == "thunder") {
            val state = getThunderRuntimeState()
            val success = state["success"] == true
            return mapOf(
                "success" to success,
                "stdout" to formatThunderRuntimeStateSnapshot(state),
                "stderr" to if (success) "" else (state["error"]?.toString().orEmpty()),
                "elapsedMs" to 0,
                "exitCode" to if (success) 0 else -1,
                "isStub" to false,
                "message" to (state["message"]?.toString() ?: "Thunder runtime probe finished.")
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
        val optionsRaw = call.argument<Map<*, *>>("options") ?: emptyMap<Any?, Any?>()
        val options = withEngineRuntimeOptions(engine, optionsRaw)
        val useCodeMode = (options["executeAsCode"] as? Boolean) == true

        if (engine == "jar") {
            return sourceRuntimeFailure(
                message = "Engine=$engine uses dedicated bridge. Use /jarTest or /goProxyTest.",
                error = "dedicated_bridge_required",
                isStub = true
            )
        }

        if (engine == "goproxy") {
            val action = options["action"]?.toString()?.trim()?.lowercase().orEmpty().ifEmpty { "status" }
            return when (action) {
                "status", "state", "runtime", "probe" -> {
                    val state = getGoProxyRuntimeState()
                    mapOf(
                        "success" to (state["success"] == true),
                        "stdout" to formatGoProxyRuntimeStateSnapshot(state),
                        "stderr" to "",
                        "elapsedMs" to 0,
                        "exitCode" to 0,
                        "isStub" to false,
                        "message" to (state["message"]?.toString()
                            ?: "GoProxy runtime state collected.")
                    )
                }

                "stop" -> {
                    val result = stopGoProxy()
                    val success = result["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatGoProxyOperationResult(result),
                        "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (result["message"]?.toString() ?: "GoProxy stop finished.")
                    )
                }

                "start" -> {
                    val result = startGoProxyInternal(
                        commandInput = options["command"]?.toString(),
                        rawArgs = parseStringList(options["args"]),
                        port = parseIntValue(options["port"], 9978).coerceAtLeast(1),
                        proxyUrl = options["proxyUrl"]?.toString(),
                        workingDirectory = options["workingDirectory"]?.toString(),
                        danmuDirInput = options["danmuDir"]?.toString().orEmpty(),
                        environment = parseStringMap(options["environment"])
                    )
                    val success = result["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatGoProxyOperationResult(result),
                        "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (result["message"]?.toString() ?: "GoProxy start finished.")
                    )
                }

                else -> sourceRuntimeFailure(
                    message = "Unsupported goproxy action=$action. Supported: status, start, stop.",
                    error = "unsupported_action",
                    isStub = true
                )
            }
        }

        if (engine == "php") {
            val action = options["action"]?.toString()?.trim()?.lowercase().orEmpty()
            if (action.isNotEmpty() && action !in setOf("execute", "code", "run")) {
                return when (action) {
                    "status", "state", "runtime", "probe" -> {
                        val state = getPhpRuntimeState()
                        val success = state["success"] == true
                        mapOf(
                            "success" to success,
                            "stdout" to formatPhpRuntimeStateSnapshot(state),
                            "stderr" to if (success) "" else (state["error"]?.toString().orEmpty()),
                            "elapsedMs" to 0,
                            "exitCode" to if (success) 0 else -1,
                            "isStub" to false,
                            "message" to (state["message"]?.toString()
                                ?: "PHP runtime state collected.")
                        )
                    }

                    "start", "start_server", "server_start" -> {
                        val result = phpStartServerWithOptions(options)
                        val success = result["success"] == true
                        mapOf(
                            "success" to success,
                            "stdout" to formatPhpServerOperationResult(result),
                            "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                            "elapsedMs" to 0,
                            "exitCode" to if (success) 0 else -1,
                            "isStub" to false,
                            "message" to (result["message"]?.toString() ?: "PHP server start finished.")
                        )
                    }

                    "stop", "stop_server", "server_stop" -> {
                        val result = phpStopServer()
                        val success = result["success"] == true
                        mapOf(
                            "success" to success,
                            "stdout" to formatPhpServerOperationResult(result),
                            "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                            "elapsedMs" to 0,
                            "exitCode" to if (success) 0 else -1,
                            "isStub" to false,
                            "message" to (result["message"]?.toString() ?: "PHP server stop finished.")
                        )
                    }

                    else -> sourceRuntimeFailure(
                        message = "Unsupported php action=$action. Supported: status, start, stop, execute.",
                        error = "unsupported_action",
                        isStub = true
                    )
                }
            }
        }

        if (engine == "thunder") {
            val action = options["action"]?.toString()?.trim()?.lowercase().orEmpty()
            val resolvedAction = if (action.isNotEmpty()) {
                action
            } else if (payload.isNotBlank()) {
                "parse"
            } else {
                "status"
            }
            return when (resolvedAction) {
                "status", "state", "runtime", "probe" -> {
                    val state = getThunderRuntimeState()
                    val success = state["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatThunderRuntimeStateSnapshot(state),
                        "stderr" to if (success) "" else (state["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (state["message"]?.toString()
                            ?: "Thunder runtime state collected.")
                    )
                }

                "parse", "parse_url" -> {
                    val url = options["url"]?.toString()?.trim().orEmpty()
                        .ifEmpty { payload.trim() }
                    val result = thunderParseUrl(url)
                    val success = result["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatThunderOperationResult(result),
                        "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (result["message"]?.toString() ?: "Thunder parse finished.")
                    )
                }

                "play", "play_url", "resolve_play_url" -> {
                    val url = options["url"]?.toString()?.trim().orEmpty()
                        .ifEmpty { payload.trim() }
                    val taskId = options["taskId"]?.toString()
                    val index = parseIntValue(options["index"], 0).coerceAtLeast(0)
                    val result = thunderResolvePlayUrl(
                        urlInput = url,
                        taskIdInput = taskId,
                        index = index
                    )
                    val success = result["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatThunderOperationResult(result),
                        "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (result["message"]?.toString() ?: "Thunder play-url resolve finished.")
                    )
                }

                "stop", "stop_task" -> {
                    val result = thunderStopTaskById(options["taskId"]?.toString())
                    val success = result["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatThunderOperationResult(result),
                        "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (result["message"]?.toString() ?: "Thunder stop finished.")
                    )
                }

                "release", "reset" -> {
                    val result = thunderRelease()
                    val success = result["success"] == true
                    mapOf(
                        "success" to success,
                        "stdout" to formatThunderOperationResult(result),
                        "stderr" to if (success) "" else (result["error"]?.toString().orEmpty()),
                        "elapsedMs" to 0,
                        "exitCode" to if (success) 0 else -1,
                        "isStub" to false,
                        "message" to (result["message"]?.toString() ?: "Thunder release finished.")
                    )
                }

                else -> sourceRuntimeFailure(
                    message = "Unsupported thunder action=$resolvedAction. Supported: status, parse, play, stop, release, execute.",
                    error = "unsupported_action",
                    isStub = true
                )
            }
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

    private fun formatGoProxyRuntimeStateSnapshot(state: Map<String, Any?>): String {
        val lines = mutableListOf<String>()
        lines += "running=${state["running"]}"
        lines += "proxyUrl=${state["proxyUrl"]}"
        lines += "port=${state["port"]}"
        lines += "pid=${state["pid"]}"
        lines += "startedAtMs=${state["startedAtMs"]}"
        lines += "uptimeMs=${state["uptimeMs"]}"
        lines += "foregroundServiceRunning=${state["foregroundServiceRunning"]}"
        lines += "foregroundWakeLockHeld=${state["foregroundWakeLockHeld"]}"
        lines += "foregroundWifiLockHeld=${state["foregroundWifiLockHeld"]}"
        lines += "foregroundTrackedPid=${state["foregroundTrackedPid"]}"
        lines += "lastExitCode=${state["lastExitCode"]}"
        lines += "lastExitedAtMs=${state["lastExitedAtMs"]}"
        lines += "lastCommand=${state["lastCommand"]}"
        lines += "lastArgs=${state["lastArgs"]}"
        lines += "lastWorkingDirectory=${state["lastWorkingDirectory"]}"
        lines += "danmuDir=${state["danmuDir"]}"
        lines += "lastError=${state["lastError"]}"
        lines += "foregroundServiceError=${state["foregroundServiceError"]}"
        return lines.joinToString("\n")
    }

    private fun formatGoProxyOperationResult(result: Map<String, Any?>): String {
        val lines = mutableListOf<String>()
        lines += "success=${result["success"]}"
        lines += "running=${result["running"]}"
        lines += "proxyUrl=${result["proxyUrl"]}"
        lines += "message=${result["message"]}"
        lines += "error=${result["error"]}"
        lines += "foregroundServiceRunning=${result["foregroundServiceRunning"]}"
        lines += "foregroundWakeLockHeld=${result["foregroundWakeLockHeld"]}"
        lines += "foregroundWifiLockHeld=${result["foregroundWifiLockHeld"]}"
        lines += "foregroundTrackedPid=${result["foregroundTrackedPid"]}"
        lines += "foregroundServiceError=${result["foregroundServiceError"]}"
        return lines.joinToString("\n")
    }

    private fun formatPhpRuntimeStateSnapshot(state: Map<String, Any?>): String {
        val lines = mutableListOf<String>()
        lines += "success=${state["success"]}"
        lines += "running=${state["running"]}"
        lines += "installed=${state["installed"]}"
        lines += "port=${state["port"]}"
        lines += "ports=${state["ports"]}"
        lines += "documentRoot=${state["documentRoot"]}"
        lines += "startedAtMs=${state["startedAtMs"]}"
        lines += "uptimeMs=${state["uptimeMs"]}"
        lines += "processCount=${state["processCount"]}"
        lines += "aliveProcessCount=${state["aliveProcessCount"]}"
        lines += "phpDir=${state["phpDir"]}"
        lines += "phpBinary=${state["phpBinary"]}"
        lines += "phpBinaryExists=${state["phpBinaryExists"]}"
        lines += "phpBinaryExecutable=${state["phpBinaryExecutable"]}"
        lines += "scriptsDir=${state["scriptsDir"]}"
        lines += "command=${state["command"]}"
        lines += "version=${state["version"]}"
        lines += "runningFlag=${state["runningFlag"]}"
        lines += "message=${state["message"]}"
        lines += "error=${state["error"]}"
        return lines.joinToString("\n")
    }

    private fun formatPhpServerOperationResult(result: Map<String, Any?>): String {
        val lines = mutableListOf<String>()
        lines += "success=${result["success"]}"
        lines += "running=${result["running"]}"
        lines += "port=${result["port"]}"
        lines += "ports=${result["ports"]}"
        lines += "documentRoot=${result["documentRoot"]}"
        lines += "message=${result["message"]}"
        lines += "error=${result["error"]}"
        return lines.joinToString("\n")
    }

    private fun formatThunderRuntimeStateSnapshot(state: Map<String, Any?>): String {
        val lines = mutableListOf<String>()
        lines += "success=${state["success"]}"
        lines += "activeTaskCount=${state["activeTaskCount"]}"
        lines += "taskSequence=${state["taskSequence"]}"
        lines += "tasks=${state["tasks"]}"
        lines += "message=${state["message"]}"
        lines += "error=${state["error"]}"
        return lines.joinToString("\n")
    }

    private fun formatThunderOperationResult(result: Map<String, Any?>): String {
        val lines = mutableListOf<String>()
        lines += "success=${result["success"]}"
        lines += "taskId=${result["taskId"]}"
        lines += "protocol=${result["protocol"]}"
        lines += "playUrl=${result["playUrl"]}"
        lines += "infoHash=${result["infoHash"]}"
        lines += "activeTaskCount=${result["activeTaskCount"]}"
        lines += "mediaCount=${result["mediaCount"]}"
        lines += "medias=${result["medias"]}"
        lines += "message=${result["message"]}"
        lines += "error=${result["error"]}"
        return lines.joinToString("\n")
    }

    private fun withEngineRuntimeOptions(engine: String, options: Map<*, *>): Map<Any?, Any?> {
        if (engine != "php") {
            return options.entries.associate { entry -> entry.key to entry.value }
        }
        val normalized = options.toMutableMap()
        normalized["environment"] = buildPhpRuntimeEnvironment(parseStringMap(options["environment"]))
        val workingDirectory = options["workingDirectory"]?.toString()?.trim().orEmpty()
        if (workingDirectory.isEmpty()) {
            normalized["workingDirectory"] = phpGetScriptsDir()
        }
        return normalized
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
            "php/php",
            "php/bin/php",
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

    private fun parseIntValue(value: Any?, fallback: Int = 0): Int {
        return when (value) {
            is Int -> value
            is Number -> value.toInt()
            is String -> value.trim().toIntOrNull() ?: fallback
            else -> fallback
        }
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

    private fun isGoProxyRunning(): Boolean = reconcileGoProxyRuntimeState()

    private fun startGoProxy(call: MethodCall): Map<String, Any?> {
        if (isGoProxyRunning()) {
            return mapOf(
                "success" to true,
                "running" to true,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy is already running.",
                "error" to "",
                "foregroundServiceRunning" to GoProxyForegroundService.isRunning(),
                "foregroundWakeLockHeld" to GoProxyForegroundService.isWakeLockHeld(),
                "foregroundWifiLockHeld" to GoProxyForegroundService.isWifiLockHeld(),
                "foregroundTrackedPid" to GoProxyForegroundService.getTrackedProcessPid()
            )
        }

        val commandInput = call.argument<String>("command")
        val rawArgs = call.argument<List<String>>("args") ?: emptyList()
        val port = call.argument<Int>("port") ?: 9978
        val proxyUrl = call.argument<String>("proxyUrl")
        val workingDirectory = call.argument<String>("workingDirectory")
        val danmuDirInput = call.argument<String>("danmuDir").orEmpty()
        val environment = (call.argument<Map<*, *>>("environment") ?: emptyMap<Any?, Any?>())
            .mapNotNull { (key, value) ->
                if (key is String && value is String) {
                    key to value
                } else {
                    null
                }
            }.toMap()
        return startGoProxyInternal(
            commandInput = commandInput,
            rawArgs = rawArgs,
            port = port,
            proxyUrl = proxyUrl,
            workingDirectory = workingDirectory,
            danmuDirInput = danmuDirInput,
            environment = environment
        )
    }

    private fun startGoProxyInternal(
        commandInput: String?,
        rawArgs: List<String>,
        port: Int,
        proxyUrl: String?,
        workingDirectory: String?,
        danmuDirInput: String,
        environment: Map<String, String>
    ): Map<String, Any?> {
        val commandValue = commandInput?.trim().orEmpty()
        val command = if (commandValue.isNotEmpty()) {
            commandValue
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

        val resolvedProxyUrl = proxyUrl?.trim()
        val resolvedWorkingDirectory = workingDirectory?.trim()
        val fallbackDanmuDir = resolveGoProxyDanmuDir(danmuDirInput.trim())
        val argResolution = normalizeGoProxyArgs(rawArgs, port, fallbackDanmuDir)
        val args = argResolution.args
        goProxyLastCommand = command
        goProxyLastArgs = args.toList()
        goProxyLastWorkingDirectory = resolvedWorkingDirectory.orEmpty()
        goProxyLastPort = argResolution.port
        goProxyLastDanmuDir = argResolution.danmuDir

        return try {
            val commandLine = mutableListOf(command).apply { addAll(args) }
            val processBuilder = ProcessBuilder(commandLine).apply {
                if (!resolvedWorkingDirectory.isNullOrEmpty()) {
                    directory(File(resolvedWorkingDirectory))
                }
                if (environment.isNotEmpty()) {
                    environment().putAll(environment)
                }
                redirectErrorStream(false)
            }
            goProxyProcess = processBuilder.start()
            goProxyUrl = if (!resolvedProxyUrl.isNullOrEmpty()) {
                resolvedProxyUrl
            } else {
                "http://127.0.0.1:${argResolution.port}"
            }
            goProxyLastError = ""
            goProxyLastExitCode = null
            goProxyLastExitedAtMs = 0L
            goProxyStartedAtMs = System.currentTimeMillis()
            val processPid = getProcessPidCompat(goProxyProcess)?.toInt() ?: -1
            goProxyForegroundLastError = startGoProxyForegroundService(
                proxyUrl = goProxyUrl,
                commandLine = commandLine.joinToString(" "),
                processPid = processPid
            )
            mapOf(
                "success" to true,
                "running" to true,
                "proxyUrl" to goProxyUrl,
                "message" to if (goProxyForegroundLastError.isEmpty()) {
                    "GoProxy process started."
                } else {
                    "GoProxy process started, but foreground service failed."
                },
                "error" to "",
                "command" to command,
                "foregroundServiceRunning" to GoProxyForegroundService.isRunning(),
                "foregroundWakeLockHeld" to GoProxyForegroundService.isWakeLockHeld(),
                "foregroundWifiLockHeld" to GoProxyForegroundService.isWifiLockHeld(),
                "foregroundTrackedPid" to GoProxyForegroundService.getTrackedProcessPid(),
                "foregroundServiceError" to goProxyForegroundLastError
            )
        } catch (e: Exception) {
            goProxyProcess = null
            goProxyLastError = e.message ?: e.toString()
            goProxyStartedAtMs = 0L
            stopGoProxyForegroundService()
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
            goProxyStartedAtMs = 0L
            val fgError = stopGoProxyForegroundService()
            return mapOf(
                "success" to true,
                "running" to false,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy is not running.",
                "error" to "",
                "foregroundServiceRunning" to GoProxyForegroundService.isRunning(),
                "foregroundWakeLockHeld" to GoProxyForegroundService.isWakeLockHeld(),
                "foregroundWifiLockHeld" to GoProxyForegroundService.isWifiLockHeld(),
                "foregroundTrackedPid" to GoProxyForegroundService.getTrackedProcessPid(),
                "foregroundServiceError" to fgError
            )
        }
        return try {
            process.destroy()
            process.waitFor(1500, TimeUnit.MILLISECONDS)
            if (process.isAlive) {
                process.destroyForcibly()
            }
            goProxyLastExitCode = runCatching { process.exitValue() }.getOrNull()
            goProxyLastExitedAtMs = System.currentTimeMillis()
            goProxyProcess = null
            goProxyStartedAtMs = 0L
            val fgError = stopGoProxyForegroundService()
            mapOf(
                "success" to true,
                "running" to false,
                "proxyUrl" to goProxyUrl,
                "message" to "GoProxy process stopped.",
                "error" to "",
                "foregroundServiceRunning" to GoProxyForegroundService.isRunning(),
                "foregroundWakeLockHeld" to GoProxyForegroundService.isWakeLockHeld(),
                "foregroundWifiLockHeld" to GoProxyForegroundService.isWifiLockHeld(),
                "foregroundTrackedPid" to GoProxyForegroundService.getTrackedProcessPid(),
                "foregroundServiceError" to fgError
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

    private fun getGoProxyRuntimeState(): Map<String, Any?> {
        val running = reconcileGoProxyRuntimeState()
        val process = goProxyProcess
        val now = System.currentTimeMillis()
        val startedAt = if (running) goProxyStartedAtMs else 0L
        val uptimeMs = if (running && startedAt > 0L) {
            (now - startedAt).coerceAtLeast(0L)
        } else {
            0L
        }
        return mapOf(
            "success" to true,
            "running" to running,
            "proxyUrl" to goProxyUrl,
            "lastError" to goProxyLastError,
            "lastCommand" to goProxyLastCommand,
            "lastArgs" to goProxyLastArgs,
            "lastWorkingDirectory" to goProxyLastWorkingDirectory,
            "port" to goProxyLastPort,
            "danmuDir" to goProxyLastDanmuDir,
            "startedAtMs" to startedAt,
            "uptimeMs" to uptimeMs,
            "pid" to if (running) getProcessPidCompat(process) else null,
            "lastExitCode" to goProxyLastExitCode,
            "lastExitedAtMs" to goProxyLastExitedAtMs,
            "foregroundServiceRunning" to GoProxyForegroundService.isRunning(),
            "foregroundWakeLockHeld" to GoProxyForegroundService.isWakeLockHeld(),
            "foregroundWifiLockHeld" to GoProxyForegroundService.isWifiLockHeld(),
            "foregroundTrackedPid" to GoProxyForegroundService.getTrackedProcessPid(),
            "foregroundServiceError" to goProxyForegroundLastError,
            "message" to "GoProxy runtime state snapshot loaded.",
            "error" to ""
        )
    }

    private fun reconcileGoProxyRuntimeState(): Boolean {
        val process = goProxyProcess
        val running = process?.isAlive == true
        if (!running) {
            if (process != null) {
                goProxyLastExitCode = runCatching { process.exitValue() }.getOrNull()
                goProxyLastExitedAtMs = System.currentTimeMillis()
                goProxyProcess = null
                if (goProxyLastError.isEmpty()) {
                    goProxyLastError = "GoProxy process exited."
                }
            }
            goProxyStartedAtMs = 0L
            if (GoProxyForegroundService.isRunning()) {
                val fgError = stopGoProxyForegroundService()
                if (fgError.isNotEmpty()) {
                    goProxyForegroundLastError = fgError
                }
            }
            return false
        }

        if (!GoProxyForegroundService.isRunning()) {
            val trackedPid = getProcessPidCompat(process)?.toInt() ?: -1
            goProxyForegroundLastError = startGoProxyForegroundService(
                proxyUrl = goProxyUrl,
                commandLine = buildGoProxyCommandLine(),
                processPid = trackedPid
            )
        }
        return true
    }

    private fun buildGoProxyCommandLine(): String {
        if (goProxyLastCommand.isEmpty()) return ""
        return buildString {
            append(goProxyLastCommand)
            if (goProxyLastArgs.isNotEmpty()) {
                append(' ')
                append(goProxyLastArgs.joinToString(" "))
            }
        }
    }

    private fun startGoProxyForegroundService(
        proxyUrl: String,
        commandLine: String,
        processPid: Int
    ): String {
        return runCatching {
            val intent = GoProxyForegroundService.buildStartIntent(
                context = this,
                proxyUrl = proxyUrl,
                commandLine = commandLine,
                processPid = processPid
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            ""
        }.getOrElse { error ->
            error.message ?: error.toString()
        }
    }

    private fun stopGoProxyForegroundService(): String {
        val stopError = runCatching {
            startService(GoProxyForegroundService.buildStopIntent(this))
        }.exceptionOrNull()
        stopService(Intent(this, GoProxyForegroundService::class.java))
        val errorText = stopError?.let { it.message ?: it.toString() }.orEmpty()
        goProxyForegroundLastError = errorText
        return errorText
    }

    private data class GoProxyArgResolution(
        val args: List<String>,
        val port: Int,
        val danmuDir: String
    )

    private fun normalizeGoProxyArgs(
        sourceArgs: List<String>,
        fallbackPort: Int,
        fallbackDanmuDir: String
    ): GoProxyArgResolution {
        val args = sourceArgs.mapNotNull { item ->
            item.trim().takeIf { it.isNotEmpty() }
        }.toMutableList()
        val resolvedPort = upsertGoProxyArgValue(
            args = args,
            aliases = listOf("-port", "--port"),
            fallbackValue = fallbackPort.toString(),
            normalize = { it.toIntOrNull()?.takeIf { value -> value > 0 }?.toString() }
        ).toIntOrNull() ?: fallbackPort
        val resolvedDanmuDir = upsertGoProxyArgValue(
            args = args,
            aliases = listOf("-danmu-dir", "--danmu-dir"),
            fallbackValue = fallbackDanmuDir,
            normalize = { value -> resolveGoProxyDanmuDir(value.trim()) }
        )
        return GoProxyArgResolution(
            args = args.toList(),
            port = resolvedPort,
            danmuDir = resolvedDanmuDir
        )
    }

    private fun upsertGoProxyArgValue(
        args: MutableList<String>,
        aliases: List<String>,
        fallbackValue: String,
        normalize: (String) -> String?
    ): String {
        val index = args.indexOfFirst { aliases.contains(it) }
        if (index < 0) {
            args.add(aliases.first())
            args.add(fallbackValue)
            return fallbackValue
        }
        val valueIndex = index + 1
        val rawValue = args.getOrNull(valueIndex)?.takeIf { !it.startsWith("-") }
        val resolvedValue = rawValue?.let(normalize)
        if (!resolvedValue.isNullOrEmpty()) {
            if (rawValue != resolvedValue && valueIndex < args.size) {
                args[valueIndex] = resolvedValue
            }
            return resolvedValue
        }
        if (valueIndex < args.size) {
            args[valueIndex] = fallbackValue
        } else {
            args.add(fallbackValue)
        }
        return fallbackValue
    }

    private fun resolveGoProxyDanmuDir(input: String): String {
        val fallback = File(filesDir, "goproxy_danmu")
        val target = if (input.isNotEmpty()) File(input) else fallback
        return runCatching {
            val candidate = target.canonicalFile
            if (!candidate.exists()) {
                candidate.mkdirs()
            }
            if (!candidate.exists() || !candidate.isDirectory) {
                throw IOException("GoProxy danmu dir unavailable: ${candidate.absolutePath}")
            }
            candidate.absolutePath
        }.getOrElse {
            fallback.mkdirs()
            fallback.absolutePath
        }
    }

    private fun getProcessPidCompat(process: Process?): Long? {
        if (process == null) return null
        return runCatching {
            val pidMethod = process.javaClass.methods.firstOrNull { method ->
                val returnType = method.returnType
                method.name == "pid" &&
                    method.parameterCount == 0 &&
                    (
                        returnType == java.lang.Long.TYPE ||
                            returnType == java.lang.Long::class.java ||
                            Number::class.java.isAssignableFrom(returnType)
                        )
            } ?: return null
            (pidMethod.invoke(process) as? Number)?.toLong()
        }.getOrNull()
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

    private fun phpStartServer(call: MethodCall): Map<String, Any?> {
        val runtimeOptions = mergePhpRuntimeOptionsWithEnvironment(buildPhpRuntimeOptions(call))
        val port = (call.argument<Int>("port") ?: 9980).coerceIn(1, 65500)
        val instances = (call.argument<Int>("instances") ?: 4).coerceIn(1, 8)
        val documentRoot = call.argument<String>("documentRoot")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: phpGetScriptsDir()
        return phpStartServerInternal(
            port = port,
            instances = instances,
            documentRoot = documentRoot,
            runtimeOptions = runtimeOptions
        )
    }

    private fun phpStartServerWithOptions(options: Map<*, *>): Map<String, Any?> {
        val runtimeOptions = mergePhpRuntimeOptionsWithEnvironment(buildPhpRuntimeOptions(options))
        val port = parseIntValue(options["port"], 9980).coerceIn(1, 65500)
        val instances = parseIntValue(options["instances"], 4).coerceIn(1, 8)
        val documentRoot = options["documentRoot"]
            ?.toString()
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: phpGetScriptsDir()
        return phpStartServerInternal(
            port = port,
            instances = instances,
            documentRoot = documentRoot,
            runtimeOptions = runtimeOptions
        )
    }

    private fun phpStartServerInternal(
        port: Int,
        instances: Int,
        documentRoot: String,
        runtimeOptions: Map<String, Any>
    ): Map<String, Any?> {
        if (phpIsServerRunning()) {
            return mapOf(
                "success" to true,
                "running" to true,
                "port" to phpServerPort,
                "ports" to phpServerPorts.toList(),
                "documentRoot" to phpServerDocumentRoot,
                "message" to "PHP server is already running.",
                "error" to ""
            )
        }
        val command = resolvePhpCommand(runtimeOptions)
            ?: return mapOf(
                "success" to false,
                "running" to false,
                "port" to 0,
                "ports" to emptyList<Int>(),
                "documentRoot" to "",
                "message" to "PHP command not found.",
                "error" to "command_not_found"
            )
        val rootFile = File(documentRoot).apply { mkdirs() }
        ensurePhpScripts(rootFile)
        val startedProcesses = mutableListOf<Process>()
        val startedPorts = mutableListOf<Int>()
        for (index in 0 until instances) {
            val currentPort = port + index
            try {
                val processBuilder = ProcessBuilder(
                    command,
                    "-S",
                    "0.0.0.0:$currentPort",
                    "-t",
                    rootFile.absolutePath
                ).directory(rootFile)
                val environment = parseStringMap(runtimeOptions["environment"])
                if (environment.isNotEmpty()) {
                    processBuilder.environment().putAll(environment)
                }
                val process = processBuilder.start()
                startedProcesses.add(process)
                startedPorts.add(currentPort)
            } catch (_: Exception) {
            }
        }
        if (startedProcesses.isEmpty()) {
            return mapOf(
                "success" to false,
                "running" to false,
                "port" to port,
                "ports" to emptyList<Int>(),
                "documentRoot" to rootFile.absolutePath,
                "message" to "Failed to start PHP server instances.",
                "error" to "start_failed"
            )
        }
        phpServerProcesses.clear()
        phpServerProcesses.addAll(startedProcesses)
        phpServerPorts.clear()
        phpServerPorts.addAll(startedPorts)
        phpServerPort = startedPorts.first()
        phpServerDocumentRoot = rootFile.absolutePath
        phpServerRunning = true
        phpServerStartedAtMs = System.currentTimeMillis()
        return mapOf(
            "success" to true,
            "running" to true,
            "port" to phpServerPort,
            "ports" to phpServerPorts.toList(),
            "documentRoot" to phpServerDocumentRoot,
            "message" to "PHP server started.",
            "error" to ""
        )
    }

    private fun phpStopServer(): Map<String, Any?> {
        if (phpServerProcesses.isEmpty()) {
            phpServerRunning = false
            phpServerPorts.clear()
            phpServerStartedAtMs = 0L
            return mapOf(
                "success" to true,
                "running" to false,
                "port" to phpServerPort,
                "ports" to emptyList<Int>(),
                "documentRoot" to phpServerDocumentRoot,
                "message" to "PHP server is not running.",
                "error" to ""
            )
        }
        for (process in phpServerProcesses) {
            try {
                process.destroy()
                process.waitFor(800, TimeUnit.MILLISECONDS)
                if (process.isAlive) {
                    process.destroyForcibly()
                }
            } catch (_: Exception) {
            }
        }
        phpServerProcesses.clear()
        phpServerPorts.clear()
        phpServerRunning = false
        phpServerStartedAtMs = 0L
        return mapOf(
            "success" to true,
            "running" to false,
            "port" to phpServerPort,
            "ports" to emptyList<Int>(),
            "documentRoot" to phpServerDocumentRoot,
            "message" to "PHP server stopped.",
            "error" to ""
        )
    }

    private fun phpIsServerRunning(): Boolean {
        val running = phpServerProcesses.any { it.isAlive }
        if (!running) {
            phpServerProcesses.clear()
            phpServerPorts.clear()
            phpServerRunning = false
            phpServerStartedAtMs = 0L
        } else {
            phpServerRunning = true
        }
        return running
    }

    private fun phpRuntimeDir(): File = File(filesDir, "php")

    private fun phpRuntimeBinary(): File = File(phpRuntimeDir(), "php")

    private fun phpDefaultDownloadUrl(): String =
        "https://raw.githubusercontent.com/ingriddaleusag-dotcom/PeekPiliRelease/main/php/php-android-arm64.tar.gz"

    private fun phpRuntimeVersionOptions(): Map<String, Any> =
        mapOf("environment" to buildPhpRuntimeEnvironment())

    private fun mergePhpRuntimeOptionsWithEnvironment(options: Map<String, Any>): Map<String, Any> {
        val merged = options.toMutableMap()
        merged["environment"] = buildPhpRuntimeEnvironment(parseStringMap(options["environment"]))
        return merged
    }

    private fun buildPhpRuntimeEnvironment(extra: Map<String, String> = emptyMap()): Map<String, String> {
        val runtimeDir = phpRuntimeDir()
        runtimeDir.mkdirs()
        val confDir = File(runtimeDir, "conf.d")
        confDir.mkdirs()
        val libDir = File(runtimeDir, "libs")
        libDir.mkdirs()
        val environment = mutableMapOf<String, String>(
            "PHPRC" to runtimeDir.absolutePath,
            "PHP_INI_SCAN_DIR" to confDir.absolutePath,
            "HOME" to runtimeDir.absolutePath,
            "TMPDIR" to cacheDir.absolutePath
        )
        val ldParts = mutableListOf<String>()
        if (libDir.exists()) {
            ldParts.add(libDir.absolutePath)
        }
        val extraLd = extra["LD_LIBRARY_PATH"]?.trim().orEmpty()
        if (extraLd.isNotEmpty()) {
            ldParts.add(extraLd)
        }
        if (ldParts.isNotEmpty()) {
            environment["LD_LIBRARY_PATH"] = ldParts.joinToString(":")
        }
        if (extra.isNotEmpty()) {
            environment.putAll(extra)
        }
        return environment
    }

    private fun ensureWritableDirectory(directory: File): Boolean {
        return try {
            if (!directory.exists() && !directory.mkdirs()) {
                return false
            }
            directory.exists() && directory.isDirectory && directory.canWrite()
        } catch (_: Exception) {
            false
        }
    }

    private fun ensurePhpScripts(directory: File) {
        try {
            directory.mkdirs()
            val scripts = assets.list("php/scripts") ?: emptyArray()
            for (script in scripts) {
                if (!script.endsWith(".php")) {
                    continue
                }
                val target = File(directory, script)
                if (target.exists() && target.length() > 0) {
                    continue
                }
                try {
                    assets.open("php/scripts/$script").use { input ->
                        target.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                } catch (_: Exception) {
                }
            }
            val indexFile = File(directory, "index.php")
            if (!indexFile.exists() || indexFile.length() == 0L) {
                indexFile.writeText(
                    """
                    <?php
                    header('Content-Type: application/json; charset=utf-8');
                    echo json_encode([
                        'status' => 'ok',
                        'message' => 'PHP server is running',
                        'version' => PHP_VERSION,
                        'platform' => 'Android',
                        'time' => date('Y-m-d H:i:s')
                    ], JSON_UNESCAPED_UNICODE);
                    """.trimIndent()
                )
            }
        } catch (_: Exception) {
        }
    }

    private fun downloadToFile(downloadUrl: String, targetFile: File) {
        val connection = (URL(downloadUrl).openConnection() as HttpURLConnection).apply {
            connectTimeout = 30000
            readTimeout = 120000
            instanceFollowRedirects = true
        }
        try {
            connection.connect()
            val responseCode = connection.responseCode
            if (responseCode !in 200..299) {
                throw IOException("HTTP $responseCode")
            }
            targetFile.parentFile?.mkdirs()
            connection.inputStream.use { input ->
                targetFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        } finally {
            connection.disconnect()
        }
    }

    private data class PhpArchiveExtractResult(
        val success: Boolean,
        val archiveFormat: String,
        val extractMethod: String,
        val error: String
    )

    private fun extractPhpRuntimeArchive(
        archiveFile: File,
        runtimeDir: File,
        downloadUrl: String
    ): PhpArchiveExtractResult {
        val unpackDir = File(cacheDir, "php_unpack_${System.currentTimeMillis()}")
        unpackDir.mkdirs()
        val archiveFormat = detectPhpArchiveFormat(archiveFile, downloadUrl)
        var extractMethod = ""
        val extracted = when (archiveFormat) {
            "tar.gz" -> {
                when {
                    extractTarArchive(archiveFile, unpackDir) -> {
                        extractMethod = "tar_cmd"
                        true
                    }

                    extractGzipBinary(archiveFile, unpackDir) -> {
                        extractMethod = "gzip_stream_fallback"
                        true
                    }

                    else -> false
                }
            }

            "zip" -> {
                val success = extractZipArchive(archiveFile, unpackDir)
                if (success) {
                    extractMethod = "zip_stream"
                }
                success
            }

            "gzip" -> {
                val success = extractGzipBinary(archiveFile, unpackDir)
                if (success) {
                    extractMethod = "gzip_stream"
                }
                success
            }

            else -> {
                when {
                    extractTarArchive(archiveFile, unpackDir) -> {
                        extractMethod = "tar_cmd_fallback"
                        true
                    }

                    extractZipArchive(archiveFile, unpackDir) -> {
                        extractMethod = "zip_stream_fallback"
                        true
                    }

                    extractGzipBinary(archiveFile, unpackDir) -> {
                        extractMethod = "gzip_stream_fallback"
                        true
                    }

                    else -> false
                }
            }
        }

        val binarySource = if (extracted) findPhpBinary(unpackDir) else null
        if (binarySource == null) {
            archiveFile.delete()
            unpackDir.deleteRecursively()
            return PhpArchiveExtractResult(
                success = false,
                archiveFormat = archiveFormat,
                extractMethod = extractMethod,
                error = if (extracted) "php_binary_not_found" else "extract_failed"
            )
        }

        return runCatching {
            runtimeDir.mkdirs()
            val targetBinary = phpRuntimeBinary()
            binarySource.copyTo(targetBinary, overwrite = true)
            targetBinary.setExecutable(true, false)
            copyPhpRuntimeSupplement(binarySource.parentFile, unpackDir, runtimeDir)
            archiveFile.delete()
            unpackDir.deleteRecursively()
            PhpArchiveExtractResult(
                success = targetBinary.exists() && targetBinary.canExecute(),
                archiveFormat = archiveFormat,
                extractMethod = extractMethod,
                error = ""
            )
        }.getOrElse { error ->
            archiveFile.delete()
            unpackDir.deleteRecursively()
            PhpArchiveExtractResult(
                success = false,
                archiveFormat = archiveFormat,
                extractMethod = extractMethod,
                error = error.message ?: error.toString()
            )
        }
    }

    private fun detectPhpArchiveFormat(archiveFile: File, downloadUrl: String): String {
        val url = downloadUrl.lowercase()
        val name = archiveFile.name.lowercase()
        if (url.endsWith(".tar.gz") || url.endsWith(".tgz") || name.endsWith(".tar.gz") || name.endsWith(".tgz")) {
            return "tar.gz"
        }
        if (url.endsWith(".zip") || name.endsWith(".zip")) {
            return "zip"
        }
        if (url.endsWith(".gz") || name.endsWith(".gz")) {
            return "gzip"
        }
        val header = ByteArray(4)
        val read = runCatching {
            archiveFile.inputStream().use { input ->
                input.read(header)
            }
        }.getOrDefault(-1)
        if (
            read >= 4 &&
            header[0] == 0x50.toByte() &&
            header[1] == 0x4B.toByte() &&
            (header[2] == 0x03.toByte() || header[2] == 0x05.toByte() || header[2] == 0x07.toByte()) &&
            (header[3] == 0x04.toByte() || header[3] == 0x06.toByte() || header[3] == 0x08.toByte())
        ) {
            return "zip"
        }
        if (read >= 2 && header[0] == 0x1F.toByte() && header[1] == 0x8B.toByte()) {
            return "gzip"
        }
        return "unknown"
    }

    private fun extractTarArchive(archiveFile: File, unpackDir: File): Boolean {
        return runCatching {
            val process = ProcessBuilder(
                "tar",
                "-xzf",
                archiveFile.absolutePath,
                "-C",
                unpackDir.absolutePath
            ).redirectErrorStream(true).start()
            process.inputStream.bufferedReader().use { it.readText() }
            process.waitFor(30, TimeUnit.SECONDS) && process.exitValue() == 0
        }.getOrDefault(false)
    }

    private fun extractGzipBinary(archiveFile: File, unpackDir: File): Boolean {
        return runCatching {
            val fallbackBinary = File(unpackDir, "php")
            GZIPInputStream(archiveFile.inputStream()).use { input ->
                FileOutputStream(fallbackBinary).use { output ->
                    input.copyTo(output)
                }
            }
            fallbackBinary.setExecutable(true, false)
            fallbackBinary.exists() && fallbackBinary.length() > 0L
        }.getOrDefault(false)
    }

    private fun extractZipArchive(archiveFile: File, unpackDir: File): Boolean {
        return runCatching {
            val unpackPathPrefix = unpackDir.canonicalPath + File.separator
            ZipInputStream(BufferedInputStream(archiveFile.inputStream())).use { input ->
                var entry = input.nextEntry
                while (entry != null) {
                    val outFile = File(unpackDir, entry.name).canonicalFile
                    if (
                        outFile.path != unpackDir.canonicalPath &&
                        !outFile.path.startsWith(unpackPathPrefix)
                    ) {
                        throw IOException("Illegal zip entry path: ${entry.name}")
                    }
                    if (entry.isDirectory) {
                        outFile.mkdirs()
                    } else {
                        outFile.parentFile?.mkdirs()
                        FileOutputStream(outFile).use { output ->
                            input.copyTo(output)
                        }
                        if (outFile.name == "php" || outFile.extension == "so") {
                            outFile.setExecutable(true, false)
                        }
                    }
                    input.closeEntry()
                    entry = input.nextEntry
                }
            }
            true
        }.getOrDefault(false)
    }

    private fun downloadArchiveExtension(downloadUrl: String): String {
        val lower = downloadUrl.lowercase()
        return when {
            lower.endsWith(".tar.gz") -> ".tar.gz"
            lower.endsWith(".tgz") -> ".tgz"
            lower.endsWith(".zip") -> ".zip"
            lower.endsWith(".gz") -> ".gz"
            else -> ".bin"
        }
    }

    private fun findPhpBinary(root: File): File? {
        return root.walkTopDown()
            .firstOrNull { item ->
                item.isFile && item.name == "php" && item.length() > 0L
            }
    }

    private fun copyPhpRuntimeSupplement(binaryParent: File?, unpackDir: File, runtimeDir: File) {
        val roots = mutableListOf<File>()
        binaryParent?.let { roots.add(it) }
        roots.add(unpackDir)
        for (root in roots.distinct()) {
            val libsDir = root.walkTopDown().firstOrNull { item ->
                item.isDirectory && item.name == "libs"
            }
            if (libsDir != null) {
                copyDirectoryRecursively(libsDir, File(runtimeDir, "libs"))
            }
            val confDir = root.walkTopDown().firstOrNull { item ->
                item.isDirectory && item.name == "conf.d"
            }
            if (confDir != null) {
                copyDirectoryRecursively(confDir, File(runtimeDir, "conf.d"))
            }
            val iniFile = root.walkTopDown().firstOrNull { item ->
                item.isFile && item.name == "php.ini"
            }
            if (iniFile != null) {
                iniFile.copyTo(File(runtimeDir, "php.ini"), overwrite = true)
            }
        }
    }

    private fun copyDirectoryRecursively(source: File, target: File) {
        if (!source.exists() || !source.isDirectory) {
            return
        }
        target.mkdirs()
        source.walkTopDown().forEach { file ->
            if (file == source) {
                return@forEach
            }
            val relative = file.relativeTo(source).path
            val destination = File(target, relative)
            if (file.isDirectory) {
                destination.mkdirs()
            } else {
                destination.parentFile?.mkdirs()
                file.copyTo(destination, overwrite = true)
                if (file.canExecute()) {
                    destination.setExecutable(true, false)
                }
            }
        }
    }

    private fun phpInstall(call: MethodCall): Map<String, Any?> {
        if (phpIsInstalled()) {
            return mapOf(
                "success" to true,
                "message" to "PHP runtime already installed.",
                "error" to "",
                "command" to (resolvePhpCommand() ?: ""),
                "preparedFromAsset" to false,
                "downloaded" to false,
                "archivePath" to "",
                "extracted" to false,
                "archiveFormat" to "",
                "extractMethod" to ""
            )
        }
        val appRoot = filesDir.canonicalFile
        val runtimeDir = phpRuntimeDir().canonicalFile
        val runtimeBinary = phpRuntimeBinary().canonicalFile
        runtimeDir.mkdirs()
        var preparedFromAsset = false
        var downloaded = false
        var archivePath = ""
        var extracted = false
        var archiveFormat = ""
        var extractMethod = ""
        val assetCandidates = call.argument<List<String>>("assetCandidates")
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            ?: listOf("assets/runtime/php", "assets/php/php", "php")
        val downloadUrl = call.argument<String>("downloadUrl")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: phpDefaultDownloadUrl()
        val errors = mutableListOf<String>()
        if (downloadUrl.isNotEmpty()) {
            try {
                val archiveFile = File(
                    cacheDir,
                    "php_runtime_${System.currentTimeMillis()}${downloadArchiveExtension(downloadUrl)}"
                )
                downloadToFile(downloadUrl, archiveFile)
                downloaded = true
                archivePath = archiveFile.absolutePath
                val extractResult = extractPhpRuntimeArchive(archiveFile, runtimeDir, downloadUrl)
                extracted = extractResult.success
                archiveFormat = extractResult.archiveFormat
                extractMethod = extractResult.extractMethod
                if (!extractResult.success) {
                    val suffix = extractResult.error.takeIf { it.isNotEmpty() }?.let { " ($it)" } ?: ""
                    errors.add(
                        "extract failed[$archiveFormat/${extractMethod.ifEmpty { "unknown" }}]: $archivePath$suffix"
                    )
                }
            } catch (e: Exception) {
                errors.add("download failed: ${e.message ?: e.toString()}")
            }
        }

        if (!downloaded) {
            val targetRelativePath = call.argument<String>("targetRelativePath")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?: "php/php"
            val targetFile = File(appRoot, targetRelativePath).canonicalFile
            if (!targetFile.absolutePath.startsWith(appRoot.absolutePath)) {
                return mapOf(
                    "success" to false,
                    "message" to "Invalid targetRelativePath.",
                    "error" to "invalid_target_path",
                    "command" to "",
                    "preparedFromAsset" to false,
                    "downloaded" to downloaded,
                    "archivePath" to archivePath,
                    "extracted" to extracted,
                    "archiveFormat" to archiveFormat,
                    "extractMethod" to extractMethod
                )
            }
            for (candidate in assetCandidates) {
                val assetPath = candidate.removePrefix("/")
                try {
                    targetFile.parentFile?.mkdirs()
                    assets.open(assetPath).use { input ->
                        targetFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    targetFile.setExecutable(true, false)
                    if (targetFile.absolutePath != runtimeBinary.absolutePath) {
                        runtimeBinary.parentFile?.mkdirs()
                        targetFile.copyTo(runtimeBinary, overwrite = true)
                        runtimeBinary.setExecutable(true, false)
                    }
                    preparedFromAsset = true
                    break
                } catch (e: Exception) {
                    errors.add("$assetPath: ${e.message ?: e.toString()}")
                }
            }
        }

        if (runtimeBinary.exists()) {
            runtimeBinary.setExecutable(true, false)
        }
        ensurePhpScripts(File(phpGetScriptsDir()))
        val success = phpIsInstalled()
        return mapOf(
            "success" to success,
            "message" to when {
                success && downloaded -> "PHP runtime installed from download archive."
                success && preparedFromAsset -> "PHP runtime prepared from assets."
                success -> "PHP runtime already installed."
                else -> "Failed to install PHP runtime."
            },
            "error" to if (success) "" else errors.joinToString(" | "),
            "command" to (resolvePhpCommand() ?: ""),
            "preparedFromAsset" to preparedFromAsset,
            "downloaded" to downloaded,
            "archivePath" to archivePath,
            "extracted" to extracted,
            "archiveFormat" to archiveFormat,
            "extractMethod" to extractMethod
        )
    }

    private fun phpIsInstalled(): Boolean {
        val runtimeBinary = phpRuntimeBinary()
        if (runtimeBinary.exists() && runtimeBinary.canExecute()) {
            return true
        }
        val command = resolvePhpCommand(phpRuntimeVersionOptions()) ?: return false
        val result = runRuntimeCommand(
            command = command,
            args = listOf("--version"),
            timeoutMs = 5000L,
            options = phpRuntimeVersionOptions(),
            engine = "php",
            action = "version"
        )
        return result["success"] == true
    }

    private fun phpGetVersion(): String {
        val command = resolvePhpCommand(phpRuntimeVersionOptions()) ?: return ""
        val result = runRuntimeCommand(
            command = command,
            args = listOf("--version"),
            timeoutMs = 5000L,
            options = phpRuntimeVersionOptions(),
            engine = "php",
            action = "version"
        )
        if (result["success"] != true) {
            return ""
        }
        return result["stdout"]?.toString()?.lineSequence()?.firstOrNull()?.trim().orEmpty()
    }

    private fun phpGetExtensions(): List<String> {
        val command = resolvePhpCommand(phpRuntimeVersionOptions()) ?: return emptyList()
        val result = runRuntimeCommand(
            command = command,
            args = listOf("-m"),
            timeoutMs = 8000L,
            options = phpRuntimeVersionOptions(),
            engine = "php",
            action = "extensions"
        )
        if (result["success"] != true) {
            return emptyList()
        }
        val raw = result["stdout"]?.toString().orEmpty()
        return raw.lineSequence()
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .filter { !it.startsWith("[") }
            .toList()
    }

    private fun phpGetScriptsDir(): String {
        val externalDirectory = File("/storage/emulated/0/peekpili/php-scripts")
        if (ensureWritableDirectory(externalDirectory)) {
            ensurePhpScripts(externalDirectory)
            return externalDirectory.absolutePath
        }
        val internalDirectory = File(phpRuntimeDir(), "scripts")
        internalDirectory.mkdirs()
        ensurePhpScripts(internalDirectory)
        return internalDirectory.absolutePath
    }

    private fun phpGetPhpDir(): String {
        return phpRuntimeDir().absolutePath
    }

    private fun getPhpRuntimeState(): Map<String, Any?> {
        val running = phpIsServerRunning()
        val now = System.currentTimeMillis()
        val runtimeDir = phpRuntimeDir()
        val runtimeBinary = phpRuntimeBinary()
        val startedAtMs = if (running) phpServerStartedAtMs else 0L
        val uptimeMs = if (running && startedAtMs > 0L) {
            (now - startedAtMs).coerceAtLeast(0L)
        } else {
            0L
        }
        val installed = phpIsInstalled()
        return mapOf(
            "success" to true,
            "installed" to installed,
            "running" to running,
            "runningFlag" to phpServerRunning,
            "processCount" to phpServerProcesses.size,
            "aliveProcessCount" to phpServerProcesses.count { it.isAlive },
            "port" to phpServerPort,
            "ports" to phpServerPorts.toList(),
            "documentRoot" to phpServerDocumentRoot,
            "serverStartedAtMs" to startedAtMs,
            "serverUptimeMs" to uptimeMs,
            "phpDir" to runtimeDir.absolutePath,
            "phpBinary" to runtimeBinary.absolutePath,
            "phpBinaryExists" to runtimeBinary.exists(),
            "phpBinaryExecutable" to runtimeBinary.canExecute(),
            "scriptsDir" to phpGetScriptsDir(),
            "runtimeDirExists" to runtimeDir.exists(),
            "command" to (resolvePhpCommand(phpRuntimeVersionOptions()) ?: ""),
            "version" to if (installed) phpGetVersion() else "",
            "message" to "PHP runtime state snapshot loaded.",
            "error" to ""
        )
    }

    private fun phpExecuteCode(call: MethodCall): Map<String, Any?> {
        val code = call.argument<String>("code")?.trim().orEmpty()
        if (code.isEmpty()) {
            return mapOf(
                "success" to false,
                "textOutputOrError" to "Code is empty.",
                "message" to "executeCode failed",
                "error" to "empty_code"
            )
        }
        val runtimeOptions = mergePhpRuntimeOptionsWithEnvironment(buildPhpRuntimeOptions(call))
        val command = resolvePhpCommand(runtimeOptions)
            ?: return mapOf(
                "success" to false,
                "textOutputOrError" to "PHP command not found.",
                "message" to "executeCode failed",
                "error" to "command_not_found"
            )
        val result = runRuntimeCommand(
            command = command,
            args = listOf("-r", code),
            timeoutMs = (call.argument<Int>("timeoutMs") ?: 15000).toLong().coerceIn(500L, 120000L),
            options = runtimeOptions,
            engine = "php",
            action = "executeCode"
        )
        return mapOf(
            "success" to (result["success"] == true),
            "textOutputOrError" to buildString {
                append(result["stdout"]?.toString().orEmpty())
                append(result["stderr"]?.toString().orEmpty())
            }.trim(),
            "message" to (result["message"]?.toString() ?: ""),
            "error" to if (result["success"] == true) "" else (result["stderr"]?.toString() ?: "")
        )
    }

    private fun resolvePhpCommand(options: Map<*, *> = emptyMap<Any?, Any?>()): String? {
        return resolveRuntimeCommand("php", options)
    }

    private fun buildPhpRuntimeOptions(call: MethodCall?): Map<String, Any> {
        val options = mutableMapOf<String, Any>()
        if (call == null) {
            return options
        }
        call.argument<String>("command")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { options["command"] = it }
        call.argument<List<String>>("commandCandidates")
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            ?.takeIf { it.isNotEmpty() }
            ?.let { options["commandCandidates"] = it }
        call.argument<String>("workingDirectory")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { options["workingDirectory"] = it }
        call.argument<Map<*, *>>("environment")
            ?.let { options["environment"] = it }
        return options
    }

    private fun buildPhpRuntimeOptions(optionsInput: Map<*, *>): Map<String, Any> {
        val options = mutableMapOf<String, Any>()
        optionsInput["command"]
            ?.toString()
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { options["command"] = it }
        parseStringList(optionsInput["commandCandidates"])
            .takeIf { it.isNotEmpty() }
            ?.let { options["commandCandidates"] = it }
        optionsInput["workingDirectory"]
            ?.toString()
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { options["workingDirectory"] = it }
        parseStringMap(optionsInput["environment"])
            .takeIf { it.isNotEmpty() }
            ?.let { options["environment"] = it }
        return options
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
        if (invoke.success) {
            val explicitKey = call.argument<String>("key")?.trim().orEmpty()
            registerLoadedJarSpider(
                jarPath = resolvedJarFile.absolutePath,
                entryClass = resolvedEntryClass,
                key = explicitKey.ifEmpty { resolvedEntryClass },
                methodName = if (methodName.isEmpty()) "main" else methodName
            )
        }
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

    private fun destroySpider(call: MethodCall): Map<String, Any?> {
        val identity = resolveJarSpiderIdentity(call) ?: return jarLifecycleArgError(
            message = "key and jar/jarPath are required for destroySpider.",
            error = "missing_key_or_jar"
        )
        var lifecycleMethod = ""
        var lifecycleError = ""
        synchronized(jarRuntimeLock) {
            val runtime = loadedJarSpiders[identity.id]
            val context = jarSpiderContexts[identity.id]
            val lifecycle = invokeJarSpiderLifecycle(runtime, context)
            lifecycleMethod = lifecycle.methodName
            lifecycleError = lifecycle.error
            loadedJarSpiders.remove(identity.id)
            crashedJarSpiders.remove(identity.id)
            jarSpiderContexts.remove(identity.id)
        }
        return mapOf(
            "success" to true,
            "message" to if (lifecycleMethod.isNotEmpty()) {
                "Spider destroyed with lifecycle method: $lifecycleMethod"
            } else {
                "Spider destroyed"
            },
            "error" to lifecycleError,
            "lifecycleMethod" to lifecycleMethod
        )
    }

    private fun markSpiderCrashed(call: MethodCall): Map<String, Any?> {
        val identity = resolveJarSpiderIdentity(call) ?: return jarLifecycleArgError(
            message = "key and jar/jarPath are required for markSpiderCrashed.",
            error = "missing_key_or_jar"
        )
        synchronized(jarRuntimeLock) {
            crashedJarSpiders.add(identity.id)
        }
        return mapOf(
            "success" to true,
            "message" to "Spider marked as crashed: ${identity.key}",
            "error" to ""
        )
    }

    private fun isSpiderCrashed(call: MethodCall): Map<String, Any?> {
        val identity = resolveJarSpiderIdentity(call) ?: return jarLifecycleArgError(
            message = "key and jar/jarPath are required for isSpiderCrashed.",
            error = "missing_key_or_jar"
        )
        val crashed = synchronized(jarRuntimeLock) {
            crashedJarSpiders.contains(identity.id)
        }
        return mapOf(
            "success" to true,
            "crashed" to crashed,
            "message" to if (crashed) "Spider is marked crashed." else "Spider is not marked crashed.",
            "error" to ""
        )
    }

    private fun getCrashedSpiderCount(): Map<String, Any?> {
        val count = synchronized(jarRuntimeLock) {
            crashedJarSpiders.size
        }
        return mapOf(
            "success" to true,
            "count" to count,
            "message" to "Crashed spider count loaded.",
            "error" to ""
        )
    }

    private fun clearCrashedSpiders(): Map<String, Any?> {
        synchronized(jarRuntimeLock) {
            crashedJarSpiders.clear()
        }
        return mapOf(
            "success" to true,
            "message" to "Crashed spiders cleared",
            "error" to ""
        )
    }

    private fun clearAllJarSpiders(): Map<String, Any?> {
        var lifecycleCount = 0
        val lifecycleErrors = mutableListOf<String>()
        synchronized(jarRuntimeLock) {
            for ((id, context) in jarSpiderContexts) {
                val runtime = loadedJarSpiders[id]
                val lifecycle = invokeJarSpiderLifecycle(runtime, context)
                if (lifecycle.called) {
                    lifecycleCount += 1
                } else if (lifecycle.error.isNotEmpty()) {
                    lifecycleErrors.add("$id: ${lifecycle.error}")
                }
            }
            crashedJarSpiders.clear()
            loadedJarSpiders.clear()
            recentJarSpiders.clear()
            jarSpiderContexts.clear()
        }
        return mapOf(
            "success" to true,
            "message" to "All spiders cleared (lifecycle invoked: $lifecycleCount)",
            "error" to lifecycleErrors.joinToString(" | "),
            "lifecycleInvoked" to lifecycleCount
        )
    }

    private fun getJarRuntimeState(): Map<String, Any?> {
        val loadedIds: List<String>
        val crashedIds: List<String>
        val contextIds: List<String>
        val contextItems: List<Map<String, Any?>>
        val recentItems: List<Map<String, String>>
        synchronized(jarRuntimeLock) {
            loadedIds = loadedJarSpiders.keys.toList()
            crashedIds = crashedJarSpiders.toList()
            contextIds = jarSpiderContexts.keys.toList()
            contextItems = jarSpiderContexts.values.map { item ->
                mapOf(
                    "runtimeId" to item.runtimeId,
                    "hasInstance" to (item.instance != null),
                    "initAttempted" to item.initAttempted,
                    "initialized" to item.initialized,
                    "initMethod" to item.initMethod,
                    "initError" to item.initError
                )
            }
            recentItems = recentJarSpiders.entries.map { entry ->
                mapOf(
                    "jarPath" to entry.key,
                    "key" to (entry.value ?: "")
                )
            }
        }
        val initializedContextCount = contextItems.count { it["initialized"] == true }
        return mapOf(
            "success" to true,
            "loadedCount" to loadedIds.size,
            "crashedCount" to crashedIds.size,
            "contextCount" to contextIds.size,
            "initializedContextCount" to initializedContextCount,
            "recentCount" to recentItems.size,
            "loadedIds" to loadedIds,
            "crashedIds" to crashedIds,
            "contextIds" to contextIds,
            "contextItems" to contextItems,
            "recentItems" to recentItems,
            "message" to "Jar runtime state snapshot loaded.",
            "error" to ""
        )
    }

    private fun ensureJarSpiderInitialized(
        context: JarSpiderExecutionContext,
        instance: Any
    ): JarSpiderLifecycleInvoke {
        synchronized(jarRuntimeLock) {
            if (context.initAttempted) {
                return JarSpiderLifecycleInvoke(
                    called = context.initialized,
                    methodName = context.initMethod,
                    error = context.initError
                )
            }
            context.initAttempted = true
        }

        val methods = (context.clazz.methods + context.clazz.declaredMethods).distinctBy { item ->
            "${item.declaringClass.name}#${item.name}(${item.parameterTypes.joinToString(",") { type -> type.name }})"
        }
        val candidateNames = listOf("init", "initialize", "setContext")
        var lastError = ""

        for (name in candidateNames) {
            for (method in methods) {
                if (method.name != name || method.parameterCount != 1) {
                    continue
                }
                val argument = resolveJarSpiderInitArgument(method.parameterTypes[0]) ?: continue
                val target = if (Modifier.isStatic(method.modifiers)) null else instance
                try {
                    method.isAccessible = true
                    method.invoke(target, argument)
                    synchronized(jarRuntimeLock) {
                        context.initialized = true
                        context.initMethod = "$name(${method.parameterTypes[0].simpleName})"
                        context.initError = ""
                    }
                    return JarSpiderLifecycleInvoke(
                        called = true,
                        methodName = context.initMethod,
                        error = ""
                    )
                } catch (e: Exception) {
                    lastError = e.message ?: e.toString()
                }
            }
            val zeroArgMethod = methods.firstOrNull { item ->
                item.name == name && item.parameterCount == 0
            } ?: continue
            val target = if (Modifier.isStatic(zeroArgMethod.modifiers)) null else instance
            try {
                zeroArgMethod.isAccessible = true
                zeroArgMethod.invoke(target)
                synchronized(jarRuntimeLock) {
                    context.initialized = true
                    context.initMethod = "$name()"
                    context.initError = ""
                }
                return JarSpiderLifecycleInvoke(
                    called = true,
                    methodName = context.initMethod,
                    error = ""
                )
            } catch (e: Exception) {
                lastError = e.message ?: e.toString()
            }
        }

        synchronized(jarRuntimeLock) {
            context.initialized = false
            context.initMethod = ""
            context.initError = lastError
        }
        return JarSpiderLifecycleInvoke(
            called = false,
            methodName = "",
            error = lastError
        )
    }

    private fun resolveJarSpiderInitArgument(parameterType: Class<*>): Any? {
        if (parameterType.isAssignableFrom(this::class.java)) {
            return this
        }
        if (parameterType.isAssignableFrom(applicationContext::class.java)) {
            return applicationContext
        }
        return null
    }

    private fun invokeJarSpiderLifecycle(
        runtime: JarSpiderRuntime?,
        context: JarSpiderExecutionContext?
    ): JarSpiderLifecycleInvoke {
        if (runtime == null || context == null) {
            return JarSpiderLifecycleInvoke(
                called = false,
                methodName = "",
                error = ""
            )
        }
        val candidates = listOf("destroy", "release", "close")
        for (name in candidates) {
            val method = context.clazz.methods.firstOrNull { item ->
                item.name == name && item.parameterCount == 0
            } ?: context.clazz.declaredMethods.firstOrNull { item ->
                item.name == name && item.parameterCount == 0
            }
            if (method == null) {
                continue
            }
            val target = if (Modifier.isStatic(method.modifiers)) {
                null
            } else {
                context.instance
            }
            if (!Modifier.isStatic(method.modifiers) && target == null) {
                continue
            }
            return try {
                method.isAccessible = true
                method.invoke(target)
                JarSpiderLifecycleInvoke(
                    called = true,
                    methodName = name,
                    error = ""
                )
            } catch (e: Exception) {
                JarSpiderLifecycleInvoke(
                    called = false,
                    methodName = name,
                    error = e.message ?: e.toString()
                )
            }
        }
        return JarSpiderLifecycleInvoke(
            called = false,
            methodName = "",
            error = ""
        )
    }

    private fun homeContent(call: MethodCall): Map<String, Any?> {
        val filter = call.argument<Boolean>("filter") ?: true
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "homeContent",
            argumentCandidates = listOf(
                listOf(filter),
                emptyList()
            ),
            failureMessage = "homeContent error"
        )
    }

    private fun homeVideoContent(call: MethodCall): Map<String, Any?> {
        val filter = call.argument<Boolean>("filter") ?: true
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "homeVideoContent",
            argumentCandidates = listOf(
                listOf(filter),
                emptyList()
            ),
            failureMessage = "homeVideoContent error"
        )
    }

    private fun categoryContent(call: MethodCall): Map<String, Any?> {
        val tid = call.argument<String>("tid") ?: ""
        val pg = call.argument<String>("pg") ?: "1"
        val filter = call.argument<Boolean>("filter") ?: true
        val extend = hashMapOf<String, String>()
        val extendRaw = call.argument<Map<*, *>>("extend") ?: emptyMap<Any?, Any?>()
        for ((key, value) in extendRaw) {
            if (key != null && value != null) {
                extend[key.toString()] = value.toString()
            }
        }
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "categoryContent",
            argumentCandidates = listOf(
                listOf(tid, pg, filter, extend),
                listOf(tid, pg, filter),
                listOf(tid, pg),
                listOf(tid)
            ),
            failureMessage = "categoryContent error"
        )
    }

    private fun searchContent(call: MethodCall): Map<String, Any?> {
        val keyword = call.argument<String>("keyword")
            ?: call.argument<String>("wd")
            ?: ""
        val quick = call.argument<Boolean>("quick") ?: false
        val pg = call.argument<String>("pg") ?: "1"
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "searchContent",
            argumentCandidates = listOf(
                listOf(keyword, quick, pg),
                listOf(keyword, quick),
                listOf(keyword)
            ),
            failureMessage = "searchContent error"
        )
    }

    private fun detailContent(call: MethodCall): Map<String, Any?> {
        val ids = call.argument<List<String>>("ids") ?: emptyList()
        val firstId = ids.firstOrNull().orEmpty()
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "detailContent",
            argumentCandidates = listOf(
                listOf(ids),
                listOf(firstId)
            ),
            failureMessage = "detailContent error"
        )
    }

    private fun playerContent(call: MethodCall): Map<String, Any?> {
        val flag = call.argument<String>("flag") ?: ""
        val id = call.argument<String>("id") ?: ""
        val vipFlags = call.argument<List<String>>("vipFlags") ?: emptyList()
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "playerContent",
            argumentCandidates = listOf(
                listOf(flag, id, vipFlags),
                listOf(flag, id)
            ),
            failureMessage = "playerContent error"
        )
    }

    private fun action(call: MethodCall): Map<String, Any?> {
        val action = call.argument<String>("action") ?: ""
        return invokeJarSpiderDataMethod(
            call = call,
            methodName = "action",
            argumentCandidates = listOf(
                listOf(action),
                emptyList()
            ),
            failureMessage = "action error"
        )
    }

    private fun setRecent(call: MethodCall): Map<String, Any?> {
        val rawJarPath = sequenceOf(
            call.argument<String>("jar"),
            call.argument<String>("jarPath")
        ).mapNotNull { it?.trim() }.firstOrNull { it.isNotEmpty() }
            ?: return mapOf(
                "success" to false,
                "message" to "jar or jarPath is required.",
                "error" to "missing_jar"
            )
        val key = sequenceOf(
            call.argument<String>("key"),
            call.argument<String>("entryClass")
        ).mapNotNull { it?.trim() }.firstOrNull { it.isNotEmpty() }
        val jarPath = resolveRuntimePath(rawJarPath).absolutePath
        synchronized(jarRuntimeLock) {
            recentJarSpiders[jarPath] = key
        }
        return mapOf(
            "success" to true,
            "message" to "Recent set successfully",
            "error" to ""
        )
    }

    private fun invokeJarSpiderDataMethod(
        call: MethodCall,
        methodName: String,
        argumentCandidates: List<List<Any?>>,
        failureMessage: String
    ): Map<String, Any?> {
        val runtime = resolveJarSpiderRuntime(call)
            ?: return mapOf(
                "success" to false,
                "error" to "spider_not_found",
                "message" to "Spider not found. Run loadJar first or provide entryClass + jarPath."
            )
        val invoke = invokeJarSpiderMethod(
            runtime = runtime,
            methodName = methodName,
            argumentCandidates = argumentCandidates
        )
        if (!invoke.success) {
            synchronized(jarRuntimeLock) {
                crashedJarSpiders.add(runtime.runtimeId)
            }
            return mapOf(
                "success" to false,
                "error" to invoke.error,
                "message" to failureMessage
            )
        }
        synchronized(jarRuntimeLock) {
            crashedJarSpiders.remove(runtime.runtimeId)
        }
        return mapOf(
            "success" to true,
            "data" to invoke.result,
            "message" to "ok",
            "error" to ""
        )
    }

    private fun resolveJarSpiderRuntime(call: MethodCall): JarSpiderRuntime? {
        val identity = resolveJarSpiderIdentity(call) ?: resolveRecentJarSpiderIdentity(call)
        if (identity != null) {
            synchronized(jarRuntimeLock) {
                loadedJarSpiders[identity.id]?.let { return it }
                loadedJarSpiders.values
                    .filter { item -> item.jarPath == identity.jarPath }
                    .maxByOrNull { item -> item.loadedAt }
                    ?.let { return it }
            }
        }
        val jarPath = resolveJarPathFromCall(call)
        if (jarPath != null) {
            synchronized(jarRuntimeLock) {
                loadedJarSpiders.values
                    .filter { item -> item.jarPath == jarPath }
                    .maxByOrNull { item -> item.loadedAt }
                    ?.let { return it }
            }
        }
        val entryClass = call.argument<String>("entryClass")?.trim().orEmpty()
        if (entryClass.isEmpty()) {
            return null
        }
        val dynamicJarPath = jarPath ?: return null
        return JarSpiderRuntime(
            key = entryClass,
            jarPath = dynamicJarPath,
            runtimeId = buildJarSpiderId(entryClass, dynamicJarPath),
            entryClass = entryClass,
            methodName = "dynamic",
            loadedAt = 0L
        )
    }

    private fun invokeJarSpiderMethod(
        runtime: JarSpiderRuntime,
        methodName: String,
        argumentCandidates: List<List<Any?>>
    ): JarSpiderMethodInvoke {
        return try {
            val context = resolveOrCreateJarSpiderContext(runtime)
            val methods = context.clazz.methods.filter { it.name == methodName }
            if (methods.isEmpty()) {
                return JarSpiderMethodInvoke(
                    success = false,
                    result = "",
                    error = "method_not_found"
                )
            }
            var lastError = "signature_not_supported"
            for (args in argumentCandidates) {
                for (method in methods) {
                    if (method.parameterTypes.size != args.size) {
                        continue
                    }
                    val bind = convertArguments(method.parameterTypes, args) ?: continue
                    try {
                        val target = if (Modifier.isStatic(method.modifiers)) {
                            null
                        } else {
                            synchronized(jarRuntimeLock) {
                                val existing = jarSpiderContexts[runtime.runtimeId]
                                if (existing?.instance != null) {
                                    existing.instance
                                } else {
                                    val instance = context.clazz.getDeclaredConstructor().newInstance()
                                    if (existing != null) {
                                        existing.instance = instance
                                    } else {
                                        context.instance = instance
                                        jarSpiderContexts[runtime.runtimeId] = context
                                    }
                                    instance
                                }
                            }
                        }
                        if (target != null) {
                            val init = ensureJarSpiderInitialized(context, target)
                            if (init.error.isNotEmpty()) {
                                lastError = "init_failed:${init.error}"
                            }
                        }
                        method.isAccessible = true
                        val value = method.invoke(target, *bind)
                        return JarSpiderMethodInvoke(
                            success = true,
                            result = formatJarReturnValue(value),
                            error = ""
                        )
                    } catch (e: Exception) {
                        lastError = e.message ?: e.toString()
                    }
                }
            }
            JarSpiderMethodInvoke(
                success = false,
                result = "",
                error = lastError
            )
        } catch (e: Exception) {
            JarSpiderMethodInvoke(
                success = false,
                result = "",
                error = e.message ?: e.toString()
            )
        }
    }

    private fun resolveOrCreateJarSpiderContext(
        runtime: JarSpiderRuntime
    ): JarSpiderExecutionContext {
        synchronized(jarRuntimeLock) {
            jarSpiderContexts[runtime.runtimeId]?.let { return it }
        }
        val jarFile = File(runtime.jarPath)
        if (!jarFile.exists() || !jarFile.canRead()) {
            throw IllegalStateException("jar_unavailable")
        }
        val optimizedDir = File(codeCacheDir, "jar_opt").apply { mkdirs() }
        val loader = DexClassLoader(
            jarFile.absolutePath,
            optimizedDir.absolutePath,
            null,
            classLoader
        )
        val clazz = loader.loadClass(runtime.entryClass)
        val context = JarSpiderExecutionContext(
            runtimeId = runtime.runtimeId,
            loader = loader,
            clazz = clazz,
            instance = null
        )
        synchronized(jarRuntimeLock) {
            val existing = jarSpiderContexts[runtime.runtimeId]
            if (existing != null) {
                return existing
            }
            jarSpiderContexts[runtime.runtimeId] = context
        }
        return context
    }

    private fun convertArguments(
        parameterTypes: Array<Class<*>>,
        args: List<Any?>
    ): Array<Any?>? {
        if (parameterTypes.size != args.size) {
            return null
        }
        val converted = arrayOfNulls<Any?>(args.size)
        for (index in parameterTypes.indices) {
            val type = parameterTypes[index]
            val value = args[index]
            val convertedValue = convertArgument(type, value) ?: return null
            converted[index] = convertedValue
        }
        return converted
    }

    private fun convertArgument(type: Class<*>, value: Any?): Any? {
        if (value == null) {
            return if (type.isPrimitive) null else null
        }
        if (type.isInstance(value)) {
            return value
        }
        if (type == String::class.java) {
            return value.toString()
        }
        if (type == Boolean::class.java || type == java.lang.Boolean.TYPE) {
            return when (value) {
                is Boolean -> value
                is String -> value.toBooleanStrictOrNull()
                else -> null
            }
        }
        if (type == Int::class.java || type == Integer.TYPE) {
            return when (value) {
                is Int -> value
                is Number -> value.toInt()
                is String -> value.toIntOrNull()
                else -> null
            }
        }
        if (type == Long::class.java || type == java.lang.Long.TYPE) {
            return when (value) {
                is Long -> value
                is Number -> value.toLong()
                is String -> value.toLongOrNull()
                else -> null
            }
        }
        if (type == Double::class.java || type == java.lang.Double.TYPE) {
            return when (value) {
                is Double -> value
                is Number -> value.toDouble()
                is String -> value.toDoubleOrNull()
                else -> null
            }
        }
        if (type == Float::class.java || type == java.lang.Float.TYPE) {
            return when (value) {
                is Float -> value
                is Number -> value.toFloat()
                is String -> value.toFloatOrNull()
                else -> null
            }
        }
        if (type.isArray && type.componentType == String::class.java && value is List<*>) {
            val stringArray = value.mapNotNull { it?.toString() }.toTypedArray()
            return stringArray
        }
        if (List::class.java.isAssignableFrom(type) && value is List<*>) {
            return value
        }
        if (Map::class.java.isAssignableFrom(type) && value is Map<*, *>) {
            val map = hashMapOf<Any?, Any?>()
            for ((key, item) in value) {
                map[key] = item
            }
            return map
        }
        return null
    }

    private fun registerLoadedJarSpider(
        jarPath: String,
        entryClass: String,
        key: String,
        methodName: String
    ) {
        val aliases = linkedSetOf<String>()
        if (key.isNotEmpty()) {
            aliases.add(key)
        }
        if (entryClass.isNotEmpty()) {
            aliases.add(entryClass)
        }
        synchronized(jarRuntimeLock) {
            for (alias in aliases) {
                val id = buildJarSpiderId(alias, jarPath)
                jarSpiderContexts.remove(id)
                crashedJarSpiders.remove(id)
                loadedJarSpiders[id] = JarSpiderRuntime(
                    key = alias,
                    jarPath = jarPath,
                    runtimeId = id,
                    entryClass = entryClass,
                    methodName = methodName,
                    loadedAt = System.currentTimeMillis()
                )
            }
        }
    }

    private fun resolveRecentJarSpiderIdentity(call: MethodCall): JarSpiderIdentity? {
        val explicitKey = resolveJarKeyFromCall(call)
        val explicitJarPath = resolveJarPathFromCall(call)
        val resolvedPair = synchronized(jarRuntimeLock) {
            when {
                explicitJarPath != null && explicitKey == null -> {
                    val recentKey = recentJarSpiders[explicitJarPath]
                    if (recentKey.isNullOrEmpty()) {
                        null
                    } else {
                        recentKey to explicitJarPath
                    }
                }

                explicitJarPath == null && explicitKey != null -> {
                    recentJarSpiders.entries
                        .lastOrNull { item -> item.value == explicitKey }
                        ?.let { it.value.orEmpty() to it.key }
                }

                explicitJarPath == null && explicitKey == null && recentJarSpiders.size == 1 -> {
                    recentJarSpiders.entries.first().let { it.value.orEmpty() to it.key }
                }

                else -> null
            }
        } ?: return null
        val key = resolvedPair.first.trim()
        val jarPath = resolvedPair.second.trim()
        if (key.isEmpty() || jarPath.isEmpty()) {
            return null
        }
        return JarSpiderIdentity(
            key = key,
            jarPath = jarPath,
            id = buildJarSpiderId(key, jarPath)
        )
    }

    private fun resolveJarSpiderIdentity(call: MethodCall): JarSpiderIdentity? {
        val key = resolveJarKeyFromCall(call) ?: return null
        val jarPath = resolveJarPathFromCall(call) ?: return null
        return JarSpiderIdentity(
            key = key,
            jarPath = jarPath,
            id = buildJarSpiderId(key, jarPath)
        )
    }

    private fun resolveJarKeyFromCall(call: MethodCall): String? {
        return sequenceOf(
            call.argument<String>("key"),
            call.argument<String>("entryClass")
        ).mapNotNull { item -> item?.trim() }.firstOrNull { item -> item.isNotEmpty() }
    }

    private fun resolveJarPathFromCall(call: MethodCall): String? {
        val rawJarPath = sequenceOf(
            call.argument<String>("jar"),
            call.argument<String>("jarPath")
        ).mapNotNull { item -> item?.trim() }.firstOrNull { item -> item.isNotEmpty() } ?: return null
        return resolveRuntimePath(rawJarPath).absolutePath
    }

    private fun buildJarSpiderId(key: String, jarPath: String): String {
        return "${key.trim()}|${jarPath.trim()}"
    }

    private fun jarLifecycleArgError(
        message: String,
        error: String
    ): Map<String, Any?> {
        return mapOf(
            "success" to false,
            "message" to message,
            "error" to error
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

    private data class JarSpiderRuntime(
        val key: String,
        val jarPath: String,
        val runtimeId: String,
        val entryClass: String,
        val methodName: String,
        val loadedAt: Long
    )

    private data class JarSpiderIdentity(
        val key: String,
        val jarPath: String,
        val id: String
    )

    private data class JarSpiderMethodInvoke(
        val success: Boolean,
        val result: String,
        val error: String
    )

    private data class JarSpiderExecutionContext(
        val runtimeId: String,
        val loader: DexClassLoader,
        val clazz: Class<*>,
        var instance: Any?,
        var initAttempted: Boolean = false,
        var initialized: Boolean = false,
        var initMethod: String = "",
        var initError: String = ""
    )

    private data class JarSpiderLifecycleInvoke(
        val called: Boolean,
        val methodName: String,
        val error: String
    )

    private fun thunderParseMagnet(call: MethodCall): Map<String, Any?> {
        val url = call.argument<String>("url").orEmpty()
        return thunderParseUrl(url)
    }

    private fun thunderParseUrl(urlInput: String): Map<String, Any?> {
        val url = urlInput.trim()
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

        val medias = buildThunderParsedMedias(parsed.normalizedUrl, parsed.infoHash)
        return mapOf(
            "success" to true,
            "protocol" to parsed.protocol,
            "originalUrl" to parsed.originalUrl,
            "normalizedUrl" to parsed.normalizedUrl,
            "infoHash" to parsed.infoHash,
            "mediaCount" to medias.size,
            "medias" to medias,
            "message" to "Parsed successfully.",
            "error" to ""
        )
    }

    private fun buildThunderParsedMedias(
        normalizedUrl: String,
        infoHash: String
    ): List<Map<String, Any?>> {
        val lower = normalizedUrl.lowercase()
        return when {
            lower.startsWith("magnet:") -> buildMagnetMediaSnapshot(
                normalizedUrl = normalizedUrl,
                infoHash = infoHash
            )?.let { listOf(it) } ?: emptyList()

            lower.startsWith("ed2k://") -> buildEd2kMediaSnapshot(normalizedUrl)
                ?.let { listOf(it) } ?: emptyList()

            else -> emptyList()
        }
    }

    private fun buildMagnetMediaSnapshot(
        normalizedUrl: String,
        infoHash: String
    ): Map<String, Any?>? {
        return try {
            val uri = Uri.parse(normalizedUrl)
            val displayName = uri.getQueryParameter("dn")?.trim().orEmpty()
            val size = uri.getQueryParameter("xl")?.trim()?.toLongOrNull()?.coerceAtLeast(0L) ?: 0L
            val name = when {
                displayName.isNotEmpty() -> displayName
                infoHash.isNotEmpty() -> infoHash
                else -> "magnet_item"
            }
            val ext = run {
                val index = name.lastIndexOf('.')
                if (index >= 0 && index < name.lastIndex) {
                    name.substring(index + 1)
                } else {
                    ""
                }
            }
            mapOf(
                "name" to name,
                "size" to size,
                "index" to 0,
                "ext" to ext,
                "sizeText" to if (size > 0L) formatThunderByteSize(size) else ""
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun buildEd2kMediaSnapshot(normalizedUrl: String): Map<String, Any?>? {
        val payload = normalizedUrl.substringAfter("://", "").trimStart('/')
        if (payload.isEmpty()) return null
        val segments = payload.split('|')
        if (segments.size < 5) return null
        if (!segments[0].equals("file", ignoreCase = true)) return null
        val rawName = Uri.decode(segments[1]).trim()
        val name = if (rawName.isNotEmpty()) rawName else "ed2k_item"
        val size = segments[2].trim().toLongOrNull()?.coerceAtLeast(0L) ?: 0L
        val ext = run {
            val index = name.lastIndexOf('.')
            if (index >= 0 && index < name.lastIndex) {
                name.substring(index + 1)
            } else {
                ""
            }
        }
        return mapOf(
            "name" to name,
            "size" to size,
            "index" to 0,
            "ext" to ext,
            "sizeText" to if (size > 0L) formatThunderByteSize(size) else ""
        )
    }

    private fun formatThunderByteSize(size: Long): String {
        if (size <= 0L) {
            return ""
        }
        val units = listOf("B", "KB", "MB", "GB", "TB")
        var value = size.toDouble()
        var index = 0
        while (value >= 1024.0 && index < units.lastIndex) {
            value /= 1024.0
            index += 1
        }
        val text = if (index == 0) {
            value.toLong().toString()
        } else {
            String.format("%.2f", value)
        }
        return "$text ${units[index]}"
    }

    private fun thunderGetPlayUrl(call: MethodCall): Map<String, Any?> {
        val url = call.argument<String>("url").orEmpty()
        val taskId = call.argument<String>("taskId")
        val index = call.argument<Int>("index") ?: 0
        return thunderResolvePlayUrl(
            urlInput = url,
            taskIdInput = taskId,
            index = index
        )
    }

    private fun thunderResolvePlayUrl(
        urlInput: String,
        taskIdInput: String?,
        index: Int
    ): Map<String, Any?> {
        val url = urlInput.trim()
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
        val taskId = taskIdInput?.trim()?.takeIf { it.isNotEmpty() }
            ?: nextThunderTaskId(parsed.protocol)
        val safeIndex = index.coerceAtLeast(0)
        val activeTaskCount = synchronized(thunderRuntimeLock) {
            thunderActiveTasks[taskId] = ThunderTaskState(
                taskId = taskId,
                protocol = parsed.protocol,
                originalUrl = parsed.originalUrl,
                playUrl = parsed.normalizedUrl,
                infoHash = parsed.infoHash,
                index = safeIndex,
                createdAt = System.currentTimeMillis()
            )
            thunderActiveTasks.size
        }
        return mapOf(
            "success" to true,
            "playUrl" to parsed.normalizedUrl,
            "protocol" to parsed.protocol,
            "infoHash" to parsed.infoHash,
            "taskId" to taskId,
            "index" to safeIndex,
            "activeTaskCount" to activeTaskCount,
            "message" to "Play url resolved.",
            "error" to ""
        )
    }

    private fun thunderStopTask(call: MethodCall): Map<String, Any?> {
        val requestedTaskId = call.argument<String>("taskId")
        return thunderStopTaskById(requestedTaskId)
    }

    private fun thunderStopTaskById(requestedTaskIdInput: String?): Map<String, Any?> {
        val requestedTaskId = requestedTaskIdInput?.trim().orEmpty()
        val resolvedTaskId = if (requestedTaskId.isNotEmpty()) {
            requestedTaskId
        } else {
            synchronized(thunderRuntimeLock) {
                thunderActiveTasks.values.maxByOrNull { it.createdAt }?.taskId
            }
        }
        if (resolvedTaskId.isNullOrEmpty()) {
            return mapOf(
                "success" to false,
                "taskId" to requestedTaskId,
                "activeTaskCount" to thunderActiveTaskCount(),
                "message" to "Thunder task not found.",
                "error" to "task_not_found"
            )
        }
        val removed = synchronized(thunderRuntimeLock) {
            thunderActiveTasks.remove(resolvedTaskId)
        }
        val activeTaskCount = thunderActiveTaskCount()
        if (removed == null) {
            return mapOf(
                "success" to false,
                "taskId" to resolvedTaskId,
                "activeTaskCount" to activeTaskCount,
                "message" to "Thunder task not found.",
                "error" to "task_not_found"
            )
        }
        return mapOf(
            "success" to true,
            "taskId" to resolvedTaskId,
            "activeTaskCount" to activeTaskCount,
            "message" to if (requestedTaskId.isNotEmpty()) {
                "Thunder task stopped."
            } else {
                "Latest thunder task stopped."
            },
            "error" to ""
        )
    }

    private fun thunderRelease(): Map<String, Any?> {
        val clearedCount = synchronized(thunderRuntimeLock) {
            val count = thunderActiveTasks.size
            thunderActiveTasks.clear()
            count
        }
        return mapOf(
            "success" to true,
            "activeTaskCount" to 0,
            "message" to "Thunder bridge released. Cleared $clearedCount tasks.",
            "error" to ""
        )
    }

    private fun getThunderRuntimeState(): Map<String, Any?> {
        val now = System.currentTimeMillis()
        val tasks = synchronized(thunderRuntimeLock) {
            thunderActiveTasks.values
                .sortedBy { it.createdAt }
                .map { task ->
                    mapOf(
                        "taskId" to task.taskId,
                        "protocol" to task.protocol,
                        "originalUrl" to task.originalUrl,
                        "playUrl" to task.playUrl,
                        "infoHash" to task.infoHash,
                        "index" to task.index,
                        "createdAtMs" to task.createdAt,
                        "ageMs" to (now - task.createdAt).coerceAtLeast(0L)
                    )
                }
        }
        return mapOf(
            "success" to true,
            "activeTaskCount" to tasks.size,
            "taskSequence" to thunderTaskSequence,
            "tasks" to tasks,
            "message" to "Thunder runtime state snapshot loaded.",
            "error" to ""
        )
    }

    private fun thunderActiveTaskCount(): Int {
        return synchronized(thunderRuntimeLock) {
            thunderActiveTasks.size
        }
    }

    private fun nextThunderTaskId(protocol: String): String {
        return synchronized(thunderRuntimeLock) {
            thunderTaskSequence += 1
            "thunder_${protocol}_${thunderTaskSequence}"
        }
    }

    private fun parseThunderLikeUrl(raw: String): ThunderParsedResult? {
        val input = raw.trim()
        if (input.isEmpty()) return null

        if (
            input.startsWith("thunder://", ignoreCase = true) ||
            input.startsWith("qqdl://", ignoreCase = true) ||
            input.startsWith("flashget://", ignoreCase = true)
        ) {
            val scheme = input.substringBefore("://").lowercase()
            val encoded = input.substringAfter("://", "")
            if (encoded.isEmpty()) return null
            val decoded = decodeThunderFamilyPayload(encoded) ?: return null
            val unwrapped = unwrapThunderFamilyPayload(decoded, scheme).trim()
            val nested = parseThunderLikeUrl(unwrapped) ?: ThunderParsedResult(
                protocol = scheme,
                originalUrl = input,
                normalizedUrl = unwrapped,
                infoHash = ""
            )
            return nested.copy(originalUrl = input)
        }

        if (
            input.startsWith("magnet:", ignoreCase = true) ||
            input.startsWith("ed2k://", ignoreCase = true) ||
            input.startsWith("ftp://", ignoreCase = true) ||
            input.startsWith("http://", ignoreCase = true) ||
            input.startsWith("https://", ignoreCase = true)
        ) {
            val protocol = input.substringBefore(':').lowercase()
            val infoHash = when (protocol) {
                "magnet" -> extractMagnetInfoHash(input)
                "ed2k" -> extractEd2kInfoHash(input)
                else -> ""
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

    private fun decodeThunderFamilyPayload(encoded: String): String? {
        val normalized = encoded.trim().replace(" ", "+")
        val padded = normalized.padEnd(((normalized.length + 3) / 4) * 4, '=')
        val flags = listOf(
            Base64.DEFAULT,
            Base64.NO_WRAP,
            Base64.URL_SAFE or Base64.NO_WRAP
        )
        for (flag in flags) {
            try {
                return String(Base64.decode(padded, flag), Charsets.UTF_8)
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun unwrapThunderFamilyPayload(decoded: String, scheme: String): String {
        val trimmed = decoded.trim()
        return when (scheme) {
            "flashget" -> trimmed
                .removePrefix("[FLASHGET]")
                .removeSuffix("[FLASHGET]")
                .trim()

            else -> trimmed
                .removePrefix("AA")
                .removeSuffix("ZZ")
                .trim()
        }
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

    private fun extractEd2kInfoHash(url: String): String {
        val payload = url.substringAfter("://", "").trimStart('/')
        if (payload.isEmpty()) return ""
        val segments = payload.split('|')
        if (segments.size < 5) return ""
        if (!segments[0].equals("file", ignoreCase = true)) return ""
        return segments[3].trim().uppercase()
    }

    private data class ThunderParsedResult(
        val protocol: String,
        val originalUrl: String,
        val normalizedUrl: String,
        val infoHash: String
    )

    private data class ThunderTaskState(
        val taskId: String,
        val protocol: String,
        val originalUrl: String,
        val playUrl: String,
        val infoHash: String,
        val index: Int,
        val createdAt: Long
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
        phpStopServer()
        thunderRelease()
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
