import Foundation

struct EngineStatus: Codable, Equatable {
  var session: String
  var port: Int
  var injectorAlive: Bool
  var cdpOk: Bool
  var codexRunning: Bool
  var themeName: String

  static let off = EngineStatus(
    session: "off",
    port: 9341,
    injectorAlive: false,
    cdpOk: false,
    codexRunning: false,
    themeName: ""
  )

  var isActive: Bool {
    session == "active" && injectorAlive
  }

  var displayText: String {
    if isActive {
      return "皮肤已开启"
    }
    switch session {
    case "paused":
      return "皮肤已暂停"
    case "stale", "unknown":
      return "需要修复"
    default:
      return codexRunning ? "Codex 正常模式" : "Codex 未运行"
    }
  }
}

struct ThemeCatalogMetadata: Codable {
  let category: String?
  let description: String?
  let tags: [String]?
  let featured: Bool?
  let source: String?
}

struct ThemeConfiguration: Codable {
  let id: String
  let name: String
  let image: String
  let tagline: String?
  let catalog: ThemeCatalogMetadata?
}

struct ThemeDescriptor: Identifiable, Hashable {
  let id: String
  let name: String
  let category: ThemeCategory
  let summary: String
  let tags: [String]
  let isFeatured: Bool
  let directoryURL: URL
  let previewURL: URL

  func matches(_ query: String) -> Bool {
    let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
      .localizedLowercase
    guard !normalized.isEmpty else { return true }
    return ([id, name, summary, category.label] + tags)
      .joined(separator: " ")
      .localizedLowercase
      .contains(normalized)
  }
}

enum ThemeCategory: String, CaseIterable, Identifiable {
  case all
  case solid
  case abstract
  case character
  case custom
  case other

  var id: String { rawValue }

  var label: String {
    switch self {
    case .all: return "全部"
    case .solid: return "纯色"
    case .abstract: return "氛围"
    case .character: return "人物"
    case .custom: return "自定义"
    case .other: return "其他"
    }
  }

  init(catalogValue: String?, themeID: String) {
    if themeID.hasPrefix("custom-") || themeID.hasPrefix("img-") {
      self = .custom
    } else {
      self = ThemeCategory(rawValue: catalogValue ?? "") ?? .other
    }
  }
}

enum SkinTrigger {
  case manual
  case automatic
  case startup
}

enum LoginItemState: Equatable {
  case disabled
  case enabled
  case requiresApproval
  case unavailable

  var label: String {
    switch self {
    case .disabled: return "未启用"
    case .enabled: return "已启用"
    case .requiresApproval: return "需要在系统设置中批准"
    case .unavailable: return "不可用"
    }
  }
}
