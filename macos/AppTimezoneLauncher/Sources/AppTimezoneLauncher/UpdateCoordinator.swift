import AppKit
import Foundation
import Sparkle
import SwiftUI

enum UpdatePresentationState: Equatable {
  case idle
  case available(version: String)
  case checking(version: String?)
  case downloading(version: String, progress: Double?)
  case preparing(version: String, progress: Double?)
  case installing(version: String)
  case failed(version: String?, message: String)

  var isVisible: Bool {
    self != .idle
  }

  var version: String? {
    switch self {
    case .idle:
      return nil
    case .available(let version), .downloading(let version, _),
      .preparing(let version, _), .installing(let version):
      return version
    case .checking(let version), .failed(let version, _):
      return version
    }
  }
}

/// Owns Sparkle's update session and translates callbacks into compact SwiftUI state.
@MainActor
final class UpdateCoordinator: NSObject, ObservableObject {
  @Published private(set) var state: UpdatePresentationState = .idle
  @Published var errorMessage: String?

  private var updater: SPUUpdater!
  private var installReply: ((SPUUserUpdateChoice) -> Void)?
  private var installWhenFound = false
  private var expectedDownloadLength: UInt64 = 0
  private var receivedDownloadLength: UInt64 = 0

  override init() {
    super.init()

    updater = SPUUpdater(
      hostBundle: .main,
      applicationBundle: .main,
      userDriver: self,
      delegate: nil
    )

    do {
      try updater.start()
    } catch {
      // A missing feed is expected for `swift run`; packaged builds provide it in Info.plist.
      state = .idle
    }
  }

  var buttonTitle: String {
    switch state {
    case .idle:
      return ""
    case .available(let version):
      return "更新 v\(version)"
    case .checking:
      return "正在检查…"
    case .downloading(_, let progress):
      guard let progress else { return "正在下载…" }
      return "下载 \(Int((progress * 100).rounded()))%"
    case .preparing:
      return "正在准备…"
    case .installing:
      return "正在重启…"
    case .failed:
      return "重试更新"
    }
  }

  var systemImage: String {
    switch state {
    case .idle, .available:
      return "arrow.down.circle.fill"
    case .checking, .downloading, .preparing, .installing:
      return "arrow.triangle.2.circlepath"
    case .failed:
      return "exclamationmark.arrow.triangle.2.circlepath"
    }
  }

  var isButtonEnabled: Bool {
    switch state {
    case .available, .failed:
      return true
    case .idle, .checking, .downloading, .preparing, .installing:
      return false
    }
  }

  func installOrRetry() {
    if let installReply {
      self.installReply = nil
      beginDownload()
      installReply(.install)
      return
    }

    installWhenFound = true
    state = .checking(version: state.version)
    updater.checkForUpdates()
  }

  private func beginDownload() {
    let version = state.version ?? ""
    expectedDownloadLength = 0
    receivedDownloadLength = 0
    state = .downloading(version: version, progress: nil)
  }

  private func downloadProgress() -> Double? {
    guard expectedDownloadLength > 0 else { return nil }
    return min(Double(receivedDownloadLength) / Double(expectedDownloadLength), 1)
  }

  private func fail(_ error: Error) {
    let message = (error as NSError).localizedDescription
    state = .failed(version: state.version, message: message)
    errorMessage = message
    installReply = nil
    installWhenFound = false
  }
}

extension UpdateCoordinator: SPUUserDriver {
  func show(
    _ request: SPUUpdatePermissionRequest,
    reply: @escaping (SUUpdatePermissionResponse) -> Void
  ) {
    reply(
      SUUpdatePermissionResponse(
        automaticUpdateChecks: true,
        automaticUpdateDownloading: false,
        sendSystemProfile: false
      )
    )
  }

  func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
    state = .checking(version: state.version)
  }

  func showUpdateFound(
    with appcastItem: SUAppcastItem,
    state updateState: SPUUserUpdateState,
    reply: @escaping (SPUUserUpdateChoice) -> Void
  ) {
    let version = appcastItem.displayVersionString

    guard !appcastItem.isInformationOnlyUpdate else {
      self.state = .failed(
        version: version,
        message: "此版本需要从发布页面手动安装。"
      )
      errorMessage = "此版本需要从发布页面手动安装。"
      reply(.dismiss)
      return
    }

    if installWhenFound {
      installWhenFound = false
      self.state = .downloading(version: version, progress: nil)
      reply(.install)
    } else {
      installReply = reply
      self.state = .available(version: version)
    }
  }

  func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {}

  func showUpdateReleaseNotesFailedToDownloadWithError(_ error: any Error) {}

  func showUpdateNotFoundWithError(
    _ error: any Error,
    acknowledgement: @escaping () -> Void
  ) {
    if installWhenFound {
      fail(error)
    } else {
      state = .idle
    }
    acknowledgement()
  }

  func showUpdaterError(_ error: any Error, acknowledgement: @escaping () -> Void) {
    fail(error)
    acknowledgement()
  }

  func showDownloadInitiated(cancellation: @escaping () -> Void) {
    beginDownload()
  }

  func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
    self.expectedDownloadLength = expectedContentLength
    if let version = state.version {
      state = .downloading(version: version, progress: downloadProgress())
    }
  }

  func showDownloadDidReceiveData(ofLength length: UInt64) {
    receivedDownloadLength += length
    if let version = state.version {
      state = .downloading(version: version, progress: downloadProgress())
    }
  }

  func showDownloadDidStartExtractingUpdate() {
    if let version = state.version {
      state = .preparing(version: version, progress: nil)
    }
  }

  func showExtractionReceivedProgress(_ progress: Double) {
    if let version = state.version {
      state = .preparing(version: version, progress: progress)
    }
  }

  func showReady(
    toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void
  ) {
    if let version = state.version {
      state = .installing(version: version)
    }
    AppChromeController.shared.prepareForUpdaterRelaunch()
    reply(.install)
  }

  func showInstallingUpdate(
    withApplicationTerminated applicationTerminated: Bool,
    retryTerminatingApplication: @escaping () -> Void
  ) {
    if let version = state.version {
      state = .installing(version: version)
    }
  }

  func showUpdateInstalledAndRelaunched(
    _ relaunched: Bool,
    acknowledgement: @escaping () -> Void
  ) {
    acknowledgement()
  }

  func dismissUpdateInstallation() {
    installReply = nil
    installWhenFound = false
    if case .failed = state {
      return
    }
    state = .idle
  }

  func showUpdateInFocus() {
    AppChromeController.shared.showMainWindow()
  }
}

struct UpdateToolbarButton: View {
  @ObservedObject var coordinator: UpdateCoordinator

  var body: some View {
    Button {
      coordinator.installOrRetry()
    } label: {
      HStack(spacing: 6) {
        Group {
          if isBusy {
            ProgressView()
              .controlSize(.small)
              .scaleEffect(0.78)
          } else {
            Image(systemName: coordinator.systemImage)
              .font(.system(size: 12, weight: .semibold))
              .symbolRenderingMode(.hierarchical)
          }
        }
        .frame(width: 14, height: 14)

        Text(coordinator.buttonTitle)
          .font(.system(size: 12, weight: .semibold))
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
      }
      .foregroundStyle(foregroundColor)
      .padding(.horizontal, 12)
      .frame(height: 28)
      .frame(minWidth: 118)
      .background(backgroundColor, in: Capsule(style: .continuous))
      .overlay {
        Capsule(style: .continuous)
          .strokeBorder(borderColor, lineWidth: 1)
      }
      .contentShape(Capsule(style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(!coordinator.isButtonEnabled)
    .opacity(coordinator.isButtonEnabled ? 1 : 0.88)
    .help(helpText)
    .accessibilityLabel(coordinator.buttonTitle)
  }

  private var isBusy: Bool {
    switch coordinator.state {
    case .checking, .downloading, .preparing, .installing:
      return true
    case .idle, .available, .failed:
      return false
    }
  }

  private var foregroundColor: Color {
    switch coordinator.state {
    case .available, .failed:
      return .white
    default:
      return Color.primary.opacity(0.85)
    }
  }

  private var backgroundColor: Color {
    switch coordinator.state {
    case .available:
      return ZoneTheme.accent
    case .failed:
      return Color.orange.opacity(0.92)
    case .checking, .downloading, .preparing, .installing:
      return Color.primary.opacity(0.08)
    case .idle:
      return .clear
    }
  }

  private var borderColor: Color {
    switch coordinator.state {
    case .available:
      return ZoneTheme.accent.opacity(0.35)
    case .failed:
      return Color.orange.opacity(0.4)
    case .checking, .downloading, .preparing, .installing:
      return Color.primary.opacity(0.1)
    case .idle:
      return .clear
    }
  }

  private var helpText: String {
    if case .failed(_, let message) = coordinator.state {
      return "更新失败：\(message)"
    }
    return "下载更新；安装完成后 ZoneLaunch 会自动重启"
  }
}
