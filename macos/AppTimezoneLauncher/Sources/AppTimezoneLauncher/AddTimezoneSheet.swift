import SwiftUI

struct AddTimezoneSheet: View {
  @ObservedObject var model: LauncherViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var timezone = "Asia/Shanghai"

  private let presets: [(String, String)] = [
    ("China Mainland", "Asia/Shanghai"),
    ("San Francisco", "America/Los_Angeles"),
    ("Singapore", "Asia/Singapore"),
    ("Tokyo", "Asia/Tokyo"),
    ("Seoul", "Asia/Seoul"),
    ("Berlin", "Europe/Berlin"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Add Time Zone")
        .font(.title2.weight(.semibold))

      VStack(alignment: .leading, spacing: 10) {
        TextField("Display name", text: $name)
        TextField("IANA time zone", text: $timezone)
      }
      .textFieldStyle(.roundedBorder)

      VStack(alignment: .leading, spacing: 8) {
        Text("Presets")
          .font(.caption)
          .foregroundStyle(.secondary)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
          ForEach(presets, id: \.1) { preset in
            Button {
              name = preset.0
              timezone = preset.1
            } label: {
              VStack(alignment: .leading, spacing: 2) {
                Text(preset.0)
                  .font(.callout.weight(.medium))
                Text(preset.1)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
      }

      HStack {
        Spacer()
        Button("Cancel") {
          dismiss()
        }
        Button("Add") {
          model.addTimezoneGroup(name: name, ianaTimezone: timezone)
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(24)
    .frame(width: 460)
  }
}
