import AppTimezoneLauncherCore
import SwiftUI

@main
struct AppTimezoneLauncherApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var settings = AppSettingsStore()
  @StateObject private var updates = UpdateCoordinator()

  var body: some Scene {
    // Single unique window (not WindowGroup) so openWindow / Dock reopen cannot spawn duplicates.
    Window("ZoneLaunch", id: "main") {
      ContentView()
        .environmentObject(settings)
        .environmentObject(updates)
        .frame(minWidth: 820, minHeight: 540)
        .preferredColorScheme(colorScheme(for: settings.appearance))
        .background(MainWindowBootstrap())
        .onAppear {
          settings.applyToApplication()
        }
    }
    .windowStyle(.titleBar)
    .defaultSize(width: 960, height: 640)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }

    MenuBarExtra("ZoneLaunch", systemImage: "globe.badge.clock") {
      MenuBarMenuContent()
    }
  }

  private func colorScheme(for preference: AppearancePreference) -> ColorScheme? {
    switch preference {
    case .system:
      return nil
    case .light:
      return .light
    case .dark:
      return .dark
    }
  }
}

private struct MenuBarMenuContent: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Button("打开界面") {
      // Keep registration current, then focus or create at most one main window.
      AppChromeController.shared.openMainWindow = {
        openWindow(id: "main")
      }
      AppChromeController.shared.showMainWindow()
    }
    Button("关于") {
      AppChromeController.shared.openMainWindow = {
        openWindow(id: "main")
      }
      AppChromeController.shared.showAbout()
    }
    Divider()
    Button("退出应用") {
      AppChromeController.shared.quit()
    }
  }
}

/// Tags the hosting `NSWindow` and registers SwiftUI `openWindow` for cold reopen paths.
private struct MainWindowBootstrap: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    WindowAccessor { window in
      AppChromeController.shared.registerMainWindow(window)
    }
    .frame(width: 0, height: 0)
    .accessibilityHidden(true)
    .onAppear {
      AppChromeController.shared.openMainWindow = {
        openWindow(id: "main")
      }
    }
  }
}

/// Reads the hosting `NSWindow` once the SwiftUI hierarchy is attached.
private struct WindowAccessor: NSViewRepresentable {
  let onResolve: (NSWindow) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      if let window = view.window {
        onResolve(window)
      }
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    DispatchQueue.main.async {
      if let window = nsView.window {
        onResolve(window)
      }
    }
  }
}
