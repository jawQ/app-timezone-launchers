import AppKit
import SwiftUI

struct AboutSheet: View {
  @ObservedObject var updates: UpdateCoordinator
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 16)

      Divider().opacity(0.5)

      VStack(spacing: 20) {
        appIdentity

        versionCard

        updateSection
      }
      .padding(.horizontal, 22)
      .padding(.top, 20)
      .padding(.bottom, 22)
    }
    .frame(width: 420, height: 420)
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 4) {
        Text("关于")
          .font(.system(size: 18, weight: .semibold, design: .rounded))
        Text("版本信息与手动更新")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 12)
      Button("完成") {
        dismiss()
      }
      .keyboardShortcut(.cancelAction)
    }
  }

  private var appIdentity: some View {
    HStack(spacing: 14) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .interpolation(.high)
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

      VStack(alignment: .leading, spacing: 4) {
        Text("ZoneLaunch")
          .font(.system(size: 20, weight: .semibold, design: .rounded))
        Text("按独立时区启动 macOS 应用")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
  }

  private var versionCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      AboutInfoRow(title: "版本", value: AppVersionInfo.displayVersion)
      AboutInfoRow(title: "构建号", value: AppVersionInfo.build)
      AboutInfoRow(title: "Bundle ID", value: AppVersionInfo.bundleIdentifier)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.primary.opacity(0.04))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
    )
  }

  private var updateSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button {
        updates.performAboutAction()
      } label: {
        HStack(spacing: 8) {
          Group {
            if isBusy {
              ProgressView()
                .controlSize(.small)
                .scaleEffect(0.85)
            } else {
              Image(systemName: aboutActionSystemImage)
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
            }
          }
          .frame(width: 16, height: 16)

          Text(updates.aboutActionTitle)
            .font(.system(size: 13, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
      }
      .buttonStyle(.borderedProminent)
      .tint(actionTint)
      .controlSize(.large)
      .disabled(!updates.isAboutActionEnabled)
      .help("检查 GitHub Releases 上的签名更新；有新版本时可一键安装")
      .accessibilityLabel(updates.aboutActionTitle)

      if let detail = statusDetail {
        Text(detail)
          .font(.system(size: 12))
          .foregroundStyle(statusForeground)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Text("每次打开主界面都会自动检查；有更新时主窗口工具栏会出现安装按钮。")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var isBusy: Bool {
    switch updates.state {
    case .checking, .downloading, .preparing, .installing:
      return true
    case .idle, .available, .failed:
      return false
    }
  }

  private var aboutActionSystemImage: String {
    switch updates.state {
    case .idle:
      return "arrow.triangle.2.circlepath"
    case .available:
      return "arrow.down.circle.fill"
    case .failed:
      return "exclamationmark.arrow.triangle.2.circlepath"
    case .checking, .downloading, .preparing, .installing:
      return "arrow.triangle.2.circlepath"
    }
  }

  private var actionTint: Color {
    switch updates.state {
    case .available:
      return ZoneTheme.accent
    case .failed:
      return Color.orange.opacity(0.92)
    default:
      return ZoneTheme.accent
    }
  }

  private var statusDetail: String? {
    if case .failed(_, let message) = updates.state {
      return message
    }
    if case .available(let version) = updates.state {
      return "发现新版本 v\(version)，点击上方按钮下载并安装。"
    }
    if case .downloading(_, let progress) = updates.state {
      if let progress {
        return "正在下载更新… \(Int((progress * 100).rounded()))%"
      }
      return "正在下载更新…"
    }
    if case .preparing = updates.state {
      return "正在准备安装…"
    }
    if case .installing = updates.state {
      return "安装完成后 ZoneLaunch 会自动重启。"
    }
    if case .checking = updates.state {
      return "正在检查更新…"
    }
    return updates.statusMessage
  }

  private var statusForeground: Color {
    if case .failed = updates.state {
      return .orange
    }
    if case .available = updates.state {
      return ZoneTheme.accent
    }
    return .secondary
  }
}

// MARK: - Helpers

enum AppVersionInfo {
  static var shortVersion: String {
    string(for: "CFBundleShortVersionString") ?? "—"
  }

  static var build: String {
    string(for: "CFBundleVersion") ?? "—"
  }

  static var bundleIdentifier: String {
    Bundle.main.bundleIdentifier ?? "—"
  }

  static var displayVersion: String {
    if shortVersion == "—", build == "—" {
      return "开发构建"
    }
    if build == "—" || build == shortVersion {
      return shortVersion
    }
    return "\(shortVersion) (\(build))"
  }

  private static func string(for key: String) -> String? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
      return nil
    }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}

private struct AboutInfoRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(title)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .leading)
      Text(value)
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
