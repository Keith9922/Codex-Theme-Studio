import AppKit
import ServiceManagement

enum LoginItemService {
  static var state: LoginItemState {
    guard #available(macOS 13.0, *) else { return .unavailable }
    switch SMAppService.mainApp.status {
    case .notRegistered: return .disabled
    case .enabled: return .enabled
    case .requiresApproval: return .requiresApproval
    case .notFound: return .unavailable
    @unknown default: return .unavailable
    }
  }

  static func setEnabled(_ enabled: Bool) throws {
    guard #available(macOS 13.0, *) else { return }
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }

  static func openSettings() {
    guard #available(macOS 13.0, *) else { return }
    SMAppService.openSystemSettingsLoginItems()
  }
}

@MainActor
final class CodexActivityMonitor {
  private var observers: [NSObjectProtocol] = []

  func start(
    onLaunch: @escaping @MainActor () async -> Void,
    onTerminate: @escaping @MainActor () async -> Void
  ) {
    guard observers.isEmpty else { return }
    let center = NSWorkspace.shared.notificationCenter
    observe(NSWorkspace.didLaunchApplicationNotification, center: center, delay: 1.2, action: onLaunch)
    observe(NSWorkspace.didTerminateApplicationNotification, center: center, delay: 0.5, action: onTerminate)
  }

  private func observe(
    _ name: Notification.Name,
    center: NotificationCenter,
    delay: TimeInterval,
    action: @escaping @MainActor () async -> Void
  ) {
    observers.append(
      center.addObserver(forName: name, object: nil, queue: .main) { notification in
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
          as? NSRunningApplication,
          application.bundleIdentifier == "com.openai.codex" else {
          return
        }
        Task { @MainActor in
          try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          await action()
        }
      }
    )
  }

  deinit {
    let center = NSWorkspace.shared.notificationCenter
    for observer in observers {
      center.removeObserver(observer)
    }
  }
}
