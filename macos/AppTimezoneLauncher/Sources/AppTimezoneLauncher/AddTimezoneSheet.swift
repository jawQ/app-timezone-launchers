import SwiftUI

struct AddTimezoneSheet: View {
  @ObservedObject var model: LauncherViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var timezone = "Asia/Shanghai"
  @State private var selectedPresetID: String? = "Asia/Shanghai"

  private let presets: [(String, String)] = [
    ("China Mainland", "Asia/Shanghai"),
    ("San Francisco", "America/Los_Angeles"),
    ("Singapore", "Asia/Singapore"),
    ("Tokyo", "Asia/Tokyo"),
    ("Seoul", "Asia/Seoul"),
    ("Berlin", "Europe/Berlin"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 10) {
        Image(systemName: "globe.badge.clock")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(ZoneTheme.accent)
          .symbolRenderingMode(.hierarchical)

        VStack(alignment: .leading, spacing: 2) {
          Text("Add Time Zone")
            .font(.title2.weight(.semibold))
          Text("Group apps that should share one clock.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        labeledField("Display name") {
          TextField("e.g. China Mainland", text: $name)
            .textFieldStyle(.roundedBorder)
            .onChange(of: name) { _, _ in
              // Custom name clears preset highlight only when no longer matching.
              if let selected = selectedPresetID,
                !presets.contains(where: { $0.1 == selected && $0.0 == name })
              {
                selectedPresetID = nil
              }
            }
        }

        labeledField("IANA time zone") {
          TextField("e.g. Asia/Shanghai", text: $timezone)
            .textFieldStyle(.roundedBorder)
            .onChange(of: timezone) { _, newValue in
              if presets.contains(where: { $0.1 == newValue }) {
                selectedPresetID = newValue
              } else {
                selectedPresetID = nil
              }
            }
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        Text("Presets")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
          .tracking(0.3)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
          ForEach(presets, id: \.1) { preset in
            let isSelected = selectedPresetID == preset.1
            Button {
              name = preset.0
              timezone = preset.1
              selectedPresetID = preset.1
            } label: {
              VStack(alignment: .leading, spacing: 3) {
                Text(preset.0)
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundStyle(.primary)
                Text(preset.1)
                  .font(.system(size: 10))
                  .foregroundStyle(.secondary)
                Text(TimezoneDisplay.utcOffsetLabel(for: preset.1))
                  .font(.system(size: 10, weight: .medium, design: .rounded))
                  .foregroundStyle(isSelected ? ZoneTheme.accent : Color.secondary.opacity(0.8))
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(10)
              .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                  .fill(isSelected ? ZoneTheme.accentSoft : Color.primary.opacity(0.04))
              )
              .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                  .strokeBorder(
                    isSelected ? ZoneTheme.accent : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 1
                  )
              )
            }
            .buttonStyle(.plain)
          }
        }
      }

      HStack {
        Spacer()
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)

        Button("Add") {
          model.addTimezoneGroup(name: name, ianaTimezone: timezone)
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .tint(ZoneTheme.accent)
      }
    }
    .padding(24)
    .frame(width: 480)
  }

  @ViewBuilder
  private func labeledField<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.3)
      content()
    }
  }
}
