import SwiftUI

@main
struct AppTimezoneLauncherApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 820, minHeight: 540)
    }
    .windowStyle(.titleBar)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }
  }
}
