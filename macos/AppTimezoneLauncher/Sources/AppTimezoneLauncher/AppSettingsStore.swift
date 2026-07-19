import AppKit
import AppTimezoneLauncherCore
import Foundation

/// Observable wrapper around ``AppSettingsRepository``; applies Dock / appearance side effects.
@MainActor
final class AppSettingsStore: ObservableObject {
  @Published private(set) var settings: AppSettings

  private let repository: AppSettingsRepository

  init(repository: AppSettingsRepository = AppSettingsRepository()) {
    self.repository = repository
    self.settings = repository.load()
  }

  var appearance: AppearancePreference {
    get { settings.appearance }
    set {
      guard settings.appearance != newValue else { return }
      var updated = settings
      updated.appearance = newValue
      settings = updated
      persistAndApply()
    }
  }

  var showInDock: Bool {
    get { settings.showInDock }
    set {
      guard settings.showInDock != newValue else { return }
      var updated = settings
      updated.showInDock = newValue
      settings = updated
      persistAndApply()
    }
  }

  /// Apply persisted Dock visibility and appearance to the running app.
  func applyToApplication() {
    AppChromeController.shared.apply(settings: settings)
  }

  private func persistAndApply() {
    repository.save(settings)
    applyToApplication()
  }
}

/// Central AppKit side effects for chrome preferences and main-window presentation.
@MainActor
final class AppChromeController {
  static let shared = AppChromeController()

  /// Stable identifier for the primary ZoneLaunch window.
  static let mainWindowIdentifier = NSUserInterfaceItemIdentifier("zonelaunch.main")

  /// Posted when the menu bar (or other chrome) should open the About sheet on the main window.
  static let showAboutNotification = Notification.Name("zonelaunch.showAbout")

  /// Posted whenever the primary window is presented or brought back to the front.
  static let mainWindowDidPresentNotification = Notification.Name("zonelaunch.mainWindowDidPresent")

  /// Callback used when no main window exists and SwiftUI must open one.
  var openMainWindow: (() -> Void)?

  private let closeInterceptor = MainWindowCloseInterceptor()
  private var shouldPresentMainWindowWhenReady = false
  private var shouldPresentAboutWhenReady = false

  private init() {}

  func apply(settings: AppSettings) {
    applyAppearance(settings.appearance)
    applyDockVisibility(settings.showInDock)
  }

  func applyAppearance(_ preference: AppearancePreference) {
    switch preference {
    case .system:
      NSApp.appearance = nil
    case .light:
      NSApp.appearance = NSAppearance(named: .aqua)
    case .dark:
      NSApp.appearance = NSAppearance(named: .darkAqua)
    }
  }

  /// Toggles Dock icon via activation policy without destroying the main UI.
  ///
  /// Switching to `.accessory` often causes AppKit to hide windows; we capture them
  /// beforehand and bring them back immediately afterward.
  func applyDockVisibility(_ showInDock: Bool) {
    let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
    guard NSApp.activationPolicy() != policy else { return }

    let preserved = mainWindows()
    // If the user is interacting with the main UI (including Settings sheet), keep it up.
    let shouldKeepVisible = preserved.contains { window in
      window.isVisible || window.isMiniaturized || window.attachedSheet != nil
    }

    _ = NSApp.setActivationPolicy(policy)

    // Restore after AppKit finishes policy-side side effects.
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard shouldKeepVisible else { return }

      let live = preserved.filter { window in
        NSApp.windows.contains(where: { $0 === window })
      }

      if live.isEmpty {
        self.openMainWindowIfNeeded()
        return
      }

      for window in live {
        window.deminiaturize(nil)
        window.orderFrontRegardless()
      }
      live.first?.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  func showMainWindow() {
    // Keep the request alive if SwiftUI has not registered its window yet.
    shouldPresentMainWindowWhenReady = true
    NSApp.activate(ignoringOtherApps: true)

    if let window = preferredMainWindow() {
      present(window)
      return
    }

    openMainWindowIfNeeded()
  }

  /// Focuses the main window and asks it to present the About sheet.
  func showAbout() {
    shouldPresentAboutWhenReady = true
    showMainWindow()
    // Defer so a cold-opened window can attach its SwiftUI hierarchy first.
    DispatchQueue.main.async { [weak self] in
      self?.postShowAboutIfNeeded()
    }
  }

  /// Called by the main UI when it is ready (or re-ready) to honor a pending About request.
  func consumePendingShowAbout() -> Bool {
    guard shouldPresentAboutWhenReady else { return false }
    shouldPresentAboutWhenReady = false
    return true
  }

  func registerMainWindow(_ window: NSWindow) {
    window.identifier = Self.mainWindowIdentifier
    window.tabbingMode = .disallowed
    closeInterceptor.attach(to: window)

    if shouldPresentMainWindowWhenReady {
      present(window)
    }

    if shouldPresentAboutWhenReady {
      DispatchQueue.main.async { [weak self] in
        self?.postShowAboutIfNeeded()
      }
    }
  }

  private func postShowAboutIfNeeded() {
    guard shouldPresentAboutWhenReady else { return }
    NotificationCenter.default.post(name: Self.showAboutNotification, object: nil)
  }

  func quit() {
    prepareForTermination()
    dismissAttachedSheets()
    // Defer so SwiftUI sheet teardown can finish before AppKit walks windows to close.
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }

  /// Marks termination so window delegates stop converting close into hide.
  func prepareForTermination() {
    closeInterceptor.allowRealClose = true
  }

  /// Lets Sparkle close the current UI before atomically replacing and relaunching the app.
  func prepareForUpdaterRelaunch() {
    prepareForTermination()
    dismissAttachedSheets()
  }

  /// Windows with an attached sheet refuse to close, which cancels `terminate`.
  private func dismissAttachedSheets() {
    for window in NSApp.windows {
      if let sheet = window.attachedSheet {
        window.endSheet(sheet)
      }
    }
  }

  private func present(_ window: NSWindow) {
    shouldPresentMainWindowWhenReady = false
    window.deminiaturize(nil)
    window.orderFrontRegardless()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    NotificationCenter.default.post(
      name: Self.mainWindowDidPresentNotification,
      object: window
    )
  }

  private func openMainWindowIfNeeded() {
    if let window = preferredMainWindow() {
      present(window)
      return
    }

    openMainWindow?()

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if let window = self.preferredMainWindow() {
        self.present(window)
      } else {
        NSApp.activate(ignoringOtherApps: true)
      }
    }
  }

  private func preferredMainWindow() -> NSWindow? {
    let windows = mainWindows()
    return windows.first(where: \.isVisible)
      ?? windows.first(where: \.isMiniaturized)
      ?? windows.first
  }

  private func mainWindows() -> [NSWindow] {
    let identified = NSApp.windows.filter {
      $0.identifier == Self.mainWindowIdentifier
    }
    if !identified.isEmpty {
      return identified
    }

    // Fallback before the first onAppear registration completes.
    return NSApp.windows.filter { window in
      window.canBecomeKey
        && !window.className.contains("NSStatusBar")
        && !window.className.contains("NSMenu")
        && !window.className.contains("NSPopup")
        && window.frame.width >= 600
        && window.frame.height >= 400
    }
  }
}

/// Hides the main window on red-button close instead of destroying it.
/// Keeps a single window instance so Dock toggles / reopen cannot spawn duplicates.
private final class MainWindowCloseInterceptor: NSObject, NSWindowDelegate {
  nonisolated(unsafe) private weak var forwarding: (any NSWindowDelegate)?
  /// When true, allow the window to close so `NSApp.terminate` can finish.
  nonisolated(unsafe) var allowRealClose = false

  @MainActor
  func attach(to window: NSWindow) {
    if window.delegate === self { return }
    if let existing = window.delegate, existing !== self {
      forwarding = existing
    }
    window.delegate = self
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if allowRealClose {
      return true
    }
    // Hide instead of destroy while the menu-bar agent stays running.
    sender.orderOut(nil)
    return false
  }

  override func responds(to aSelector: Selector!) -> Bool {
    if super.responds(to: aSelector) { return true }
    if let forwarding, (forwarding as AnyObject).responds(to: aSelector) {
      return true
    }
    return false
  }

  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    if super.responds(to: aSelector) { return nil }
    return forwarding
  }
}
