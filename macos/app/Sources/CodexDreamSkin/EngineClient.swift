import Foundation

struct CommandResult {
  let exitCode: Int32
  let output: String
}

enum EngineClientError: LocalizedError {
  case engineNotFound
  case scriptNotFound(String)
  case commandFailed(String, Int32, String)
  case invalidStatus

  var errorDescription: String? {
    switch self {
    case .engineNotFound:
      return "没有找到 Dream Skin 引擎。请重新安装应用。"
    case let .scriptNotFound(name):
      return "引擎脚本缺失：\(name)"
    case let .commandFailed(_, code, output):
      let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
      return detail.isEmpty ? "操作失败（退出码 \(code)）。" : detail
    case .invalidStatus:
      return "无法读取 Dream Skin 运行状态。"
    }
  }
}

struct EngineClient {
  let rootURL: URL

  init() throws {
    guard let rootURL = Self.locateEngine() else {
      throw EngineClientError.engineNotFound
    }
    self.rootURL = rootURL
  }

  var scriptsURL: URL {
    rootURL.appendingPathComponent("scripts", isDirectory: true)
  }

  var stateRootURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Application Support/CodexDreamSkinStudio", isDirectory: true)
  }

  var themesRootURL: URL {
    stateRootURL.appendingPathComponent("themes", isDirectory: true)
  }

  var activeThemeURL: URL {
    stateRootURL.appendingPathComponent("theme", isDirectory: true)
  }

  static func locateEngine() -> URL? {
    let fileManager = FileManager.default
    var candidates: [URL] = []

    if let configured = ProcessInfo.processInfo.environment["CODEX_DREAM_SKIN_ENGINE"],
       !configured.isEmpty {
      candidates.append(URL(fileURLWithPath: configured, isDirectory: true))
    }
    if let resources = Bundle.main.resourceURL {
      candidates.append(resources.appendingPathComponent("engine", isDirectory: true))
    }
    candidates.append(
      fileManager.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/codex-dream-skin-studio", isDirectory: true)
    )

    let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
    candidates.append(cwd)
    candidates.append(cwd.appendingPathComponent("macos", isDirectory: true))
    candidates.append(cwd.deletingLastPathComponent())

    return candidates.first { candidate in
      let status = candidate.appendingPathComponent("scripts/status-dream-skin-macos.sh").path
      return fileManager.fileExists(atPath: status)
    }
  }

  func status(deep: Bool = false) async throws -> EngineStatus {
    var arguments = ["--json"]
    if deep {
      arguments.append("--deep")
    }
    let result = try await run(script: "status-dream-skin-macos.sh", arguments: arguments)
    guard let data = result.output.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(EngineStatus.self, from: data) else {
      throw EngineClientError.invalidStatus
    }
    return decoded
  }

  func run(
    script name: String,
    arguments: [String] = [],
    allowFailure: Bool = false
  ) async throws -> CommandResult {
    let scriptURL = scriptsURL.appendingPathComponent(name)
    guard FileManager.default.fileExists(atPath: scriptURL.path) else {
      throw EngineClientError.scriptNotFound(name)
    }

    let result = try await Task.detached(priority: .userInitiated) {
      let process = Process()
      let outputPipe = Pipe()
      process.executableURL = URL(fileURLWithPath: "/bin/bash")
      process.arguments = [scriptURL.path] + arguments
      process.currentDirectoryURL = rootURL
      process.standardOutput = outputPipe
      process.standardError = outputPipe
      var environment = ProcessInfo.processInfo.environment
      environment["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
      environment["CODEX_DREAM_SKIN_MANAGER"] = "1"
      process.environment = environment

      try process.run()
      let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      let output = String(decoding: data, as: UTF8.self)
      return CommandResult(exitCode: process.terminationStatus, output: output)
    }.value

    if result.exitCode != 0 && !allowFailure {
      throw EngineClientError.commandFailed(name, result.exitCode, result.output)
    }
    return result
  }

  func loadThemes() throws -> [ThemeDescriptor] {
    let fileManager = FileManager.default
    try fileManager.createDirectory(
      at: themesRootURL,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700]
    )
    let directories = try fileManager.contentsOfDirectory(
      at: themesRootURL,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )
    var themes: [ThemeDescriptor] = []

    for directory in directories {
      let values = try? directory.resourceValues(forKeys: [.isDirectoryKey])
      guard values?.isDirectory == true else { continue }
      let folderID = directory.lastPathComponent
      guard Self.isSafeThemeID(folderID) else { continue }
      let configURL = directory.appendingPathComponent("theme.json")
      guard let data = try? Data(contentsOf: configURL),
            let config = try? JSONDecoder().decode(ThemeConfiguration.self, from: data),
            config.id == folderID || config.id.hasPrefix("img-") || config.id.hasPrefix("custom-"),
            Self.isSafeAssetName(config.image) else {
        continue
      }
      let previewURL = directory.appendingPathComponent(config.image)
      guard fileManager.fileExists(atPath: previewURL.path) else { continue }
      themes.append(
        ThemeDescriptor(
          id: folderID,
          name: config.name,
          category: ThemeCategory(catalogValue: config.catalog?.category, themeID: folderID),
          summary: config.catalog?.description ?? config.tagline ?? "本地 Dream Skin 主题",
          tags: config.catalog?.tags ?? [],
          isFeatured: config.catalog?.featured ?? false,
          directoryURL: directory,
          previewURL: previewURL
        )
      )
    }

    return themes.sorted { lhs, rhs in
      if lhs.isFeatured != rhs.isFeatured { return lhs.isFeatured }
      if lhs.category == .custom && rhs.category != .custom { return false }
      if rhs.category == .custom && lhs.category != .custom { return true }
      return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
  }

  static func isSafeThemeID(_ value: String) -> Bool {
    guard !value.isEmpty, value.count <= 80 else { return false }
    return value.unicodeScalars.allSatisfy {
      CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_"
    }
  }

  static func isSafeAssetName(_ value: String) -> Bool {
    guard !value.isEmpty, value == URL(fileURLWithPath: value).lastPathComponent else {
      return false
    }
    return !value.contains("/") && !value.contains("\\") && !value.contains("\0")
  }
}
