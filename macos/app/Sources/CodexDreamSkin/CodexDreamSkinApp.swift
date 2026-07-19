import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationWillFinishLaunching(_ notification: Notification) {
    let currentPID = ProcessInfo.processInfo.processIdentifier
    let peers = NSRunningApplication.runningApplications(
      withBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.local.codex-dream-skin-manager"
    )
    if let existing = peers.first(where: { $0.processIdentifier != currentPID }) {
      existing.activate(options: [.activateIgnoringOtherApps])
      NSApplication.shared.terminate(nil)
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    Task { @MainActor in
      await SkinController.shared.start()
      let defaults = UserDefaults.standard
      let shouldShow = ProcessInfo.processInfo.arguments.contains("--show-settings")
        || !defaults.bool(forKey: "ui.hasShownWelcome")
      if shouldShow {
        SettingsWindowController.shared.show()
        defaults.set(true, forKey: "ui.hasShownWelcome")
      }
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
}

@main
struct CodexDreamSkinApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var controller = SkinController.shared

  var body: some Scene {
    MenuBarExtra {
      MenuContentView()
        .environmentObject(controller)
    } label: {
      Image(systemName: controller.menuSymbol)
        .accessibilityLabel("Codex Theme Studio")
    }
    .menuBarExtraStyle(.window)
  }
}
