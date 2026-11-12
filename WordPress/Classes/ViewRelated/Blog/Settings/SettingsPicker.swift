import SwiftUI

struct SettingsPickerValue<T: Hashable>: Identifiable {
    let title: String
    var details: String?
    let id: T
    var hint: String?
}

struct SettingsPickerListView<T: Hashable>: View {
    @Binding var selection: T
    let values: [SettingsPickerValue<T>]

    var body: some View {
        List {
            Section(
                content: {
                    ForEach(values, content: makeRow)
                },
                footer: {
                    if let hint = values.first(where: { $0.id == selection })?.hint {
                        Text(hint)
                    }
                }
            )
        }
        .listStyle(.insetGrouped)
    }

    private func makeRow(for value: SettingsPickerValue<T>) -> some View {
        Button(action: {
            guard selection != value.id else { return }
            selection = value.id
        }) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .opacity(value.id == selection ? 1 : 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(value.title)
                    if let details = value.details {
                        Text(details)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
