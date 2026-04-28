# PeekPili 逆向迁移实施计划（v1）

## 1. 目标与边界
- 目标：把 `PeekPiliRelease/app/anzhuangbao` 同源多平台包（Android/iOS/Windows）中的业务能力，完整迁移到当前 `PiliPlus` 项目，并保持后续可正常打 Android、iOS、Windows 新包。
- 边界：以二进制/反编译证据为准，文档描述仅作补充；平台差异采用“能力分层 + 平台适配器”方式处理。
- 依据文档：`docs/PeekPili_reverse_feature_inventory.md`。

## 2. 差距矩阵（逆向能力 vs 当前项目）
| 模块 | 逆向包现状 | 当前项目现状 | 差距结论 | 优先级 |
|---|---|---|---|---|
| T4 源配置体系 | 存在 `t4ApiConfigs`、`t4_source_config_url`、`t4_is_local_config` 等 | 无对应模型和设置入口 | 需补齐配置模型、存储、设置页、路由 | P0 |
| TMDB 集成配置 | 存在 `tmdbAccessToken`、`tmdbIntegrationEnabled`、`tmdbImageProxy` 等 | 无对应设置域 | 需补齐 TMDB 配置域和设置页 | P0 |
| Source Helper 工具页 | 存在 `/pythonTest` `/catJsTest` `/nodeJsTest` | 无路由/页面 | 先补路由与占位页，后接运行时 | P0 |
| WebDAV | 逆向有 `webdav*` 键和 `/webdavSetting` | 已有 `webdavSetting` 页面和键 | 命名映射与兼容补齐 | P1 |
| Android Jar/GoProxy/Thunder | 存在 `jar_loader`、`startGoProxy`、Thunder 插件能力 | 当前无对应接入 | 需新增 Android 平台通道与服务适配 | P1 |
| Node/Python/PHP 运行时 | 逆向包存在相关 runtime 痕迹与入口 | 当前无统一运行时编排 | 需建立跨平台 Runtime Service | P1 |
| 配置驱动首页/底栏 | 逆向显示首页和底栏可由接口配置驱动 | 当前为固定主导航体系 | 需引入配置驱动导航层 | P1 |
| iOS/Windows 等效能力 | iOS/Windows 有共享业务层但平台插件差异大 | 当前无逆向能力对齐 | 需定义降级策略与能力矩阵 | P2 |

## 3. 分阶段执行

### Phase 1（P0）配置域与入口骨架
1. 新增 T4 配置模型（序列化/反序列化、存储映射）。
2. 新增 `t4_*`、`tmdb*`、兼容 `webdav*` 关键存储键。
3. 新增设置入口与页面：
   - Source Config（源配置）
   - TMDB Config
   - Source Helper（含 `/pythonTest` `/catJsTest` `/nodeJsTest` 占位）
4. 路由接入与桌面/移动端设置页联动。

验收标准：
- 路由可达：`/sourceConfig`、`/tmdbSetting`、`/pythonTest`、`/catJsTest`、`/nodeJsTest`。
- 配置保存后重启应用仍可读取。
- `flutter analyze` 无新增错误。

执行状态（2026-04-28）：
- 已完成：存储键、配置模型、设置入口、`/pythonTest` `/catJsTest` `/nodeJsTest` 路由与基础页面。

### Phase 2（P1）业务抽象与配置驱动层
1. 建立 SourceEngine 抽象层（Python/CatJS/Node/Jar/PHP）。
2. 引入配置驱动首页/底栏映射（含回退默认配置）。
3. 统一接口协议与错误模型（超时、脚本异常、解析异常）。

验收标准：
- 可按远端/本地配置切换主页/底栏。
- 不同引擎错误能在 UI 层可观测且不中断主流程。

执行状态（2026-04-28）：
- 进行中：已建立 `SourceRuntimeService` 与 `SourceRuntimeAdapter` 分层，接入 Android/Desktop/Stub 适配器骨架；`pythonTest`/`catJsTest`/`nodeJsTest` 已可执行 Probe/Execute 调试调用。
- 进行中：Android `MainActivity` 已预留 `sourceRuntimeProbe` / `sourceRuntimeExecute` 通道占位返回，便于后续接入真实 Jar/GoProxy/Thunder 逻辑。
- 进行中：已落地 GoProxy 首条桥接链路（`startGoProxy` / `stopGoProxy` / `isGoProxyRunning` / `getProxyUrl`）以及 `/goProxyTest` 联调页。
- 进行中：已新增 GoProxy 自动命令探测与资源下发（`detectGoProxyCommand` / `prepareGoProxyBinary`），`/goProxyTest` 可一键 Detect/Prepare。
- 进行中：已新增 Jar 桥接骨架（`probeJarFile` / `loadJar`）与 `/jarTest` 联调页，当前为“文件校验 + 执行占位”模式。
- 进行中：`/goProxyTest` 与 `/jarTest` 调试参数已接入本地持久化预设，支持重启后自动回填。
- 进行中：Source Config 页面已支持从远端 URL 抓取并解析 `t4ApiConfigs`（含常见字段兼容提取）。
- 未完成：配置驱动首页/底栏映射、真实业务脚本执行链路。

### Phase 3（P1）Android 平台能力迁移
1. 接入 Android MethodChannel/Plugin 适配：
   - Jar loader
   - GoProxy 生命周期管理
   - Thunder/magnet 能力
2. 与 Flutter 侧 Runtime Service 联动。

验收标准：
- Android 真机可完成至少 1 条 Jar、1 条 GoProxy、1 条 Thunder 流程。

### Phase 4（P1）Windows 平台运行时迁移
1. 增加 Node/Python/PHP 进程编排服务（启动、健康检查、停止、日志）。
2. 打包脚本纳入 runtime 依赖与路径探测。

验收标准：
- Windows Release 包可启动并稳定执行 Source Helper 流程。

### Phase 5（P2）iOS 能力对齐与降级
1. 识别 iOS 可行能力（本地执行/远程代理）。
2. 对不可行能力做明确降级路径（UI 提示 + 自动回退）。

验收标准：
- iOS 包不崩溃；不可用能力有清晰提示且不阻塞其他功能。

### Phase 6（P2）三端联调与发布闭环
1. 建立三端回归清单（设置项、路由、引擎、播放链路）。
2. 打包流水线验证 Android/iOS/Windows 产物。

验收标准：
- 三端均可成功出包，核心迁移功能可用。

## 4. 技术风险与应对
- 平台插件不对等：通过 Runtime Service 抽象统一接口，平台层仅做最薄实现。
- 反编译证据不完整：关键链路补动态验证（日志埋点 + Hook 校验）。
- 运行时依赖复杂：优先 Android 先行验证，再推广到 Windows/iOS。
- 配置驱动改造影响现有主导航：先做灰度开关，默认保持原逻辑。

## 5. 验证清单（持续执行）
- 静态验证：`flutter analyze`、关键页面 widget smoke。
- 路由验证：上述新增路由逐一可进入、可返回。
- 存储验证：新键写入/读取/默认值行为正确。
- 平台验证：Android 真机 > Windows 桌面 > iOS 真机/模拟器顺序推进。

## 6. 当前执行建议（下一步）
1. 立即完成 Phase 1 代码骨架（配置模型 + 存储键 + 设置入口 + 占位页）。
2. 同步产出 Runtime Service 设计草图（接口定义，不先落平台实现）。
3. 进入 Android 适配最小闭环（先 GoProxy，再 Jar，再 Thunder）。
