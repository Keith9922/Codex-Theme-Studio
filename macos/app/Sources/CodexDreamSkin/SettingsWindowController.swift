import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
  static let shared = SettingsWindowController()

  private var window: NSWindow?

  func show() {
    let settingsWindow: NSWindow
    if let window {
      settingsWindow = window
    } else {
      let rootView = SettingsView()
        .environmentObject(SkinController.shared)
      let created = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 980, height: 760),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
      )
      created.title = "Codex Theme Studio"
      created.titlebarAppearsTransparent = true
      created.titleVisibility = .hidden
      created.backgroundColor = NSColor(
        calibratedRed: 0.055,
        green: 0.059,
        blue: 0.073,
        alpha: 1
      )
      created.contentView = NSHostingView(rootView: rootView)
      created.isReleasedWhenClosed = false
      created.minSize = NSSize(width: 860, height: 680)
      created.center()
      created.delegate = self
      window = created
      settingsWindow = created
    }

    NSApplication.shared.activate(ignoringOtherApps: true)
    settingsWindow.makeKeyAndOrderFront(nil)
    SkinController.shared.refreshThemeLibrary()
  }

  func windowWillClose(_ notification: Notification) {
    // Keep the window instance so the menu bar can reopen it without rebuilding
    // the theme gallery or losing its current scroll position.
  }
}
