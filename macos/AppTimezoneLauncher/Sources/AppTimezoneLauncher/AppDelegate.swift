import AppKit
import AppTimezoneLauncherCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let settings = AppSettingsRepository().load()
    AppChromeController.shared.apply(settings: settings)
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    // Allow main windows to actually close; interceptor otherwise cancels terminate.
    AppChromeController.shared.prepareForTermination()
    return .terminateNow
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    // Always route through showMainWindow so we focus an existing instance
    // instead of letting AppKit / SwiftUI spawn a second main window.
    AppChromeController.shared.showMainWindow()
    return true
  }
}
