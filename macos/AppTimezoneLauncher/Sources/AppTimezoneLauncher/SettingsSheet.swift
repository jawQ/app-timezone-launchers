import AppTimezoneLauncherCore
import SwiftUI

struct SettingsSheet: View {
  @ObservedObject var settings: AppSettingsStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 4) {
          Text("设置")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
          Text("外观与 Dock")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 12)
        Button("完成") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
      }
      .padding(.horizontal, 22)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider().opacity(0.5)

      Form {
        Section {
          Picker("外观", selection: appearanceBinding) {
            Text("跟随系统").tag(AppearancePreference.system)
            Text("浅色").tag(AppearancePreference.light)
            Text("深色").tag(AppearancePreference.dark)
          }
          .pickerStyle(.segmented)

          Toggle("在 Dock 中显示", isOn: showInDockBinding)
        } header: {
          Text("界面")
        } footer: {
          Text("取消勾选后，应用仅保留菜单栏图标；下次启动会记住此状态。")
            .font(.system(size: 11))
        }
      }
      .formStyle(.grouped)

      Spacer(minLength: 8)

      quitButton
        .padding(.horizontal, 22)
        .padding(.bottom, 20)
    }
    .frame(width: 420, height: 340)
  }

  private var quitButton: some View {
    Button(action: quitApp) {
      Label("退出应用", systemImage: "rectangle.portrait.and.arrow.right")
        .font(.system(size: 13, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    .buttonStyle(.bordered)
    .tint(.red)
    .controlSize(.large)
    .help("完全退出 ZoneLaunch（菜单栏图标也会消失）")
    .accessibilityLabel("退出应用")
  }

  private func quitApp() {
    // Sheet must go away first: a window with an attached sheet cannot close,
    // and AppKit cancels terminate when that happens.
    dismiss()
    DispatchQueue.main.async {
      AppChromeController.shared.quit()
    }
  }

  private var appearanceBinding: Binding<AppearancePreference> {
    Binding(
      get: { settings.appearance },
      set: { settings.appearance = $0 }
    )
  }

  private var showInDockBinding: Binding<Bool> {
    Binding(
      get: { settings.showInDock },
      set: { settings.showInDock = $0 }
    )
  }
}
