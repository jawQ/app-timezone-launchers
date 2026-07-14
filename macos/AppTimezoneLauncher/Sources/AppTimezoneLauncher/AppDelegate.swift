import AppKit
import AppTimezoneLauncherCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationWillFinishLaunching(_ notification: Notification) {
    applyPersistedSettings()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    // SwiftUI may adjust the activation policy while creating its scenes, so apply
    // the persisted preference again after launch completes.
    applyPersistedSettings()
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

  private func applyPersistedSettings() {
    let settings = AppSettingsRepository().load()
    AppChromeController.shared.apply(settings: settings)
  }
}
