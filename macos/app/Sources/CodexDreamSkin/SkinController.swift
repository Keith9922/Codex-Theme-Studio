import AppKit
import Foundation

@MainActor
final class SkinController: ObservableObject {
  static let shared = SkinController()

  @Published private(set) var status = EngineStatus.off
  @Published private(set) var themes: [ThemeDescriptor] = []
  @Published private(set) var selectedThemeID = ""
  @Published private(set) var desiredEnabled = false
  @Published private(set) var isBusy = false
  @Published private(set) var progressMessage = ""
  @Published private(set) var lastError: String?
  @Published private(set) var themeRefreshSummary: String?
  @Published private(set) var engineAvailable = true
  @Published private(set) var loginItemState: LoginItemState = .disabled
  @Published var autoOpenCodex: Bool {
    didSet { defaults.set(autoOpenCodex, forKey: Keys.autoOpenCodex) }
  }
  @Published var autoRepairLaunch: Bool {
    didSet { defaults.set(autoRepairLaunch, forKey: Keys.autoRepairLaunch) }
  }

  private enum Keys {
    static let desiredEnabled = "skin.desiredEnabled"
    static let selectedThemeID = "skin.selectedThemeID"
    static let autoOpenCodex = "skin.autoOpenCodex"
    static let autoRepairLaunch = "skin.autoRepairLaunch"
    static let lastAutomaticAttempt = "skin.lastAutomaticAttempt"
    static let legacyMigration = "skin.legacyMigrationVersion"
  }

  private let defaults = UserDefaults.standard
  private var engine: EngineClient?
  private let activityMonitor = CodexActivityMonitor()
  private var refreshTask: Task<Void, Never>?
  private var didStart = false

  private init() {
    desiredEnabled = defaults.bool(forKey: Keys.desiredEnabled)
    selectedThemeID = defaults.string(forKey: Keys.selectedThemeID) ?? ""
    autoOpenCodex = defaults.object(forKey: Keys.autoOpenCodex) as? Bool ?? false
    autoRepairLaunch = defaults.object(forKey: Keys.autoRepairLaunch) as? Bool ?? true
    do {
      engine = try EngineClient()
    } catch {
      engineAvailable = false
      lastError = error.localizedDescription
    }
  }

  var menuSymbol: String {
    if isBusy { return "arrow.triangle.2.circlepath" }
    if status.isActive { return "paintpalette.fill" }
    if status.session == "stale" || status.session == "unknown" {
      return "exclamationmark.triangle.fill"
    }
    return "paintpalette"
  }

  var statusColor: NSColor {
    if status.isActive { return .systemGreen }
    if status.session == "stale" || status.session == "unknown" { return .systemOrange }
    return .secondaryLabelColor
  }

  var selectedTheme: ThemeDescriptor? {
    themes.first(where: { $0.id == selectedThemeID })
  }

  func start() async {
    guard !didStart else { return }
    didStart = true
    startActivityMonitor()
    refreshLoginItemState()
    await migrateLegacyEntryPointsIfNeeded()
    await seedThemeLibrary()
    await refreshThemes()
    await refreshStatus(deep: true)

    if status.isActive {
      desiredEnabled = true
      defaults.set(true, forKey: Keys.desiredEnabled)
    } else if defaults.object(forKey: Keys.desiredEnabled) == nil {
      desiredEnabled = status.isActive
      defaults.set(desiredEnabled, forKey: Keys.desiredEnabled)
    }

    if selectedThemeID.isEmpty,
       let current = themes.first(where: { $0.name == status.themeName }) ?? themes.first {
      selectedThemeID = current.id
      defaults.set(current.id, forKey: Keys.selectedThemeID)
    }

    if desiredEnabled && !status.isActive {
      if autoOpenCodex && !status.codexRunning {
        await enableSkin(trigger: .startup)
      } else if autoRepairLaunch && status.codexRunning {
        await enableSkin(trigger: .automatic)
      }
    }
    beginPeriodicRefresh()
  }

  func setSkinEnabled(_ enabled: Bool) {
    desiredEnabled = enabled
    defaults.set(enabled, forKey: Keys.desiredEnabled)
    Task {
      if enabled {
        await enableSkin(trigger: .manual)
      } else {
        await disableSkin()
      }
    }
  }

  func selectTheme(_ theme: ThemeDescriptor) {
    selectedThemeID = theme.id
    defaults.set(theme.id, forKey: Keys.selectedThemeID)
    Task { await applySelectedTheme(theme) }
  }

  func refreshNow() {
    Task {
      await refreshStatus(deep: true)
    }
  }

  func refreshThemeLibrary() {
    Task { await scanThemeLibrary() }
  }

  func repair() {
    Task { await enableSkin(trigger: .manual) }
  }

  func openCodex() {
    if desiredEnabled {
      Task { await enableSkin(trigger: .manual) }
      return
    }
    let candidates = [
      URL(fileURLWithPath: "/Applications/ChatGPT.app"),
      FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/ChatGPT.app"),
      URL(fileURLWithPath: "/Applications/Codex.app"),
      FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Codex.app"),
    ]
    if let appURL = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
      NSWorkspace.shared.openApplication(
        at: appURL,
        configuration: NSWorkspace.OpenConfiguration()
      )
    } else {
      lastError = "没有找到官方 Codex 应用。"
    }
  }

  func importBackground() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.message = "选择一张背景图；应用会生成可切换的 Codex Theme Studio 主题。"
    guard panel.runModal() == .OK, let imageURL = panel.url else { return }

    Task {
      await runOperation(message: "正在导入背景图…") {
        guard let engine = self.engine else { return }
        var arguments = ["--file", imageURL.path]
        if !self.status.isActive {
          arguments.append("--no-apply")
        }
        _ = try await engine.run(
          script: "load-image-theme-macos.sh",
          arguments: arguments
        )
      }
      await refreshThemes()
      await refreshStatus(deep: true)
      if let newest = themes
        .filter({ $0.id.hasPrefix("img-") })
        .sorted(by: { $0.id > $1.id })
        .first {
        selectedThemeID = newest.id
        defaults.set(newest.id, forKey: Keys.selectedThemeID)
      }
    }
  }

  func openThemeFolder() {
    guard let engine else { return }
    try? FileManager.default.createDirectory(
      at: engine.themesRootURL,
      withIntermediateDirectories: true
    )
    NSWorkspace.shared.open(engine.themesRootURL)
  }

  func openLogsFolder() {
    guard let engine else { return }
    NSWorkspace.shared.open(engine.stateRootURL)
  }

  func quitApplication() {
    NSApplication.shared.terminate(nil)
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      try LoginItemService.setEnabled(enabled)
      refreshLoginItemState()
      lastError = nil
    } catch {
      refreshLoginItemState()
      lastError = "无法更新登录项：\(error.localizedDescription)"
      if loginItemState == .requiresApproval {
        LoginItemService.openSettings()
      }
    }
  }

  func openLoginItemSettings() {
    LoginItemService.openSettings()
  }

  private func enableSkin(trigger: SkinTrigger) async {
    guard let engine, !isBusy else { return }
    if trigger != .manual {
      let last = defaults.double(forKey: Keys.lastAutomaticAttempt)
      let now = Date().timeIntervalSince1970
      guard last == 0 || now - last >= 90 else { return }
      defaults.set(now, forKey: Keys.lastAutomaticAttempt)
    }

    var arguments = ["enable", "--port", String(status.port)]
    if !selectedThemeID.isEmpty {
      arguments += ["--theme", selectedThemeID]
    }

    await runOperation(message: status.codexRunning ? "正在重启一次 Codex 并应用皮肤…" : "正在启动带皮肤的 Codex…") {
      _ = try await engine.run(
        script: "manager-command-macos.sh",
        arguments: arguments
      )
    }
    await refreshThemes()
    await refreshStatus(deep: true)
    if lastError == nil && !status.isActive {
      lastError = "引擎已返回，但没有验证到活动皮肤。请打开日志查看详情。"
    }
  }

  private func disableSkin() async {
    guard let engine, !isBusy else { return }
    await runOperation(message: status.codexRunning ? "正在恢复官方外观并重启一次 Codex…" : "正在关闭皮肤…") {
      _ = try await engine.run(
        script: "manager-command-macos.sh",
        arguments: ["disable", "--port", String(self.status.port)]
      )
    }
    await refreshStatus(deep: true)
  }

  private func applySelectedTheme(_ theme: ThemeDescriptor) async {
    guard let engine, !isBusy else { return }
    await runOperation(message: status.isActive ? "正在热切换到 \(theme.name)…" : "已选择 \(theme.name)…") {
      var arguments = ["switch", "--id", theme.id]
      if self.status.isActive {
        arguments.append("--apply-if-active")
      }
      _ = try await engine.run(
        script: "manager-command-macos.sh",
        arguments: arguments
      )
    }
    await refreshStatus(deep: true)
  }

  private func runOperation(
    message: String,
    operation: @escaping () async throws -> Void
  ) async {
    guard engine != nil, !isBusy else { return }
    isBusy = true
    progressMessage = message
    lastError = nil
    defer {
      isBusy = false
      progressMessage = ""
    }
    do {
      try await operation()
    } catch {
      lastError = cleanError(error.localizedDescription)
    }
  }

  private func refreshThemes() async {
    guard let engine else { return }
    do {
      themes = try engine.loadThemes()
    } catch {
      lastError = "无法读取主题库：\(error.localizedDescription)"
    }
  }

  private func scanThemeLibrary() async {
    guard let engine, !isBusy else { return }
    let previousIDs = Set(themes.map(\.id))

    await runOperation(message: "正在扫描已有皮肤资产…") {
      _ = try await engine.run(
        script: "manager-command-macos.sh",
        arguments: ["seed-library"]
      )
    }
    guard lastError == nil else { return }

    await refreshThemes()
    guard lastError == nil else { return }
    await refreshStatus(deep: true)

    let discovered = Set(themes.map(\.id)).subtracting(previousIDs).count
    if discovered > 0 {
      themeRefreshSummary = "找到 \(discovered) 套新皮肤，主题库现有 \(themes.count) 套"
    } else {
      themeRefreshSummary = "主题库已刷新，共找到 \(themes.count) 套皮肤"
    }
  }

  private func refreshStatus(deep: Bool = false) async {
    guard let engine, !isBusy else { return }
    do {
      status = try await engine.status(deep: deep)
      engineAvailable = true
      if let currentTheme = themes.first(where: { $0.name == status.themeName }),
         currentTheme.id != selectedThemeID {
        selectedThemeID = currentTheme.id
        defaults.set(currentTheme.id, forKey: Keys.selectedThemeID)
      }
    } catch {
      engineAvailable = false
      lastError = error.localizedDescription
    }
  }

  private func refreshLoginItemState() {
    loginItemState = LoginItemService.state
  }

  private func migrateLegacyEntryPointsIfNeeded() async {
    guard defaults.integer(forKey: Keys.legacyMigration) < 1, let engine else { return }
    do {
      _ = try await engine.run(
        script: "manager-command-macos.sh",
        arguments: ["migrate-legacy"]
      )
      defaults.set(1, forKey: Keys.legacyMigration)
    } catch {
      lastError = "旧入口迁移未完成：\(cleanError(error.localizedDescription))"
    }
  }

  private func seedThemeLibrary() async {
    guard let engine else { return }
    do {
      _ = try await engine.run(
        script: "manager-command-macos.sh",
        arguments: ["seed-library"]
      )
    } catch {
      lastError = "内置主题初始化失败：\(cleanError(error.localizedDescription))"
    }
  }

  private func startActivityMonitor() {
    activityMonitor.start(
      onLaunch: { [weak self] in
        guard let self else { return }
        await self.refreshStatus(deep: true)
        if self.desiredEnabled && self.autoRepairLaunch && !self.status.isActive {
          await self.enableSkin(trigger: .automatic)
        }
      },
      onTerminate: { [weak self] in
        // A manual Codex quit is always respected; only refresh the UI.
        await self?.refreshStatus()
      }
    )
  }

  private func beginPeriodicRefresh() {
    refreshTask?.cancel()
    refreshTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        guard let self else { return }
        await self.refreshStatus()
        self.refreshLoginItemState()
      }
    }
  }

  private func cleanError(_ value: String) -> String {
    let lines = value
      .split(whereSeparator: \.isNewline)
      .map(String.init)
      .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    return lines.suffix(5).joined(separator: "\n")
  }
}
