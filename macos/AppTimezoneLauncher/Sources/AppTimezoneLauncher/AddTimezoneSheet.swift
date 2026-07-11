import AppTimezoneLauncherCore
import SwiftUI

enum TimezoneGroupSheetMode: Identifiable, Equatable {
  case add
  case edit(TimezoneGroup)

  var id: String {
    switch self {
    case .add:
      return "add"
    case .edit(let group):
      return group.id.uuidString
    }
  }
}

struct AddTimezoneSheet: View {
  @ObservedObject var model: LauncherViewModel
  let mode: TimezoneGroupSheetMode
  @Environment(\.dismiss) private var dismiss

  @State private var name: String
  @State private var timezone: String
  @State private var selectedPresetID: String?

  private static let presets: [(String, String)] = [
    ("China Mainland", "Asia/Shanghai"),
    ("San Francisco", "America/Los_Angeles"),
    ("Singapore", "Asia/Singapore"),
    ("Tokyo", "Asia/Tokyo"),
    ("Seoul", "Asia/Seoul"),
    ("Berlin", "Europe/Berlin"),
  ]

  private var isEditing: Bool {
    if case .edit = mode { return true }
    return false
  }

  private var titleText: String {
    isEditing ? "Edit Time Zone" : "Add Time Zone"
  }

  private var subtitleText: String {
    isEditing
      ? "Change the name or IANA clock used by this group."
      : "Group apps that should share one clock."
  }

  private var primaryButtonTitle: String {
    isEditing ? "Save" : "Add"
  }

  init(model: LauncherViewModel, mode: TimezoneGroupSheetMode = .add) {
    self.model = model
    self.mode = mode
    switch mode {
    case .add:
      _name = State(initialValue: "")
      _timezone = State(initialValue: "Asia/Shanghai")
      _selectedPresetID = State(initialValue: "Asia/Shanghai")
    case .edit(let group):
      _name = State(initialValue: group.name)
      _timezone = State(initialValue: group.ianaTimezone)
      let matchingPreset = Self.presets.first { $0.1 == group.ianaTimezone }
      _selectedPresetID = State(initialValue: matchingPreset?.1)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 10) {
        Image(systemName: isEditing ? "pencil.circle.fill" : "globe.badge.clock")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(ZoneTheme.accent)
          .symbolRenderingMode(.hierarchical)

        VStack(alignment: .leading, spacing: 2) {
          Text(titleText)
            .font(.title2.weight(.semibold))
          Text(subtitleText)
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
                !Self.presets.contains(where: { $0.1 == selected && $0.0 == name })
              {
                selectedPresetID = nil
              }
            }
        }

        labeledField("IANA time zone") {
          TextField("e.g. Asia/Shanghai", text: $timezone)
            .textFieldStyle(.roundedBorder)
            .onChange(of: timezone) { _, newValue in
              if Self.presets.contains(where: { $0.1 == newValue }) {
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
          ForEach(Self.presets, id: \.1) { preset in
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

        Button(primaryButtonTitle) {
          save()
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .tint(ZoneTheme.accent)
      }
    }
    .padding(24)
    .frame(width: 480)
  }

  private func save() {
    switch mode {
    case .add:
      model.addTimezoneGroup(name: name, ianaTimezone: timezone)
    case .edit(let group):
      model.updateTimezoneGroup(group, name: name, ianaTimezone: timezone)
    }
    dismiss()
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
