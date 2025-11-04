import SwiftUI

struct SettingsPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let values: [SettingsPickerValue<T>]

    init(title: String, selection: Binding<T>, values: [SettingsPickerValue<T>]) {
        self.title = title
        self._selection = selection
        self.values = values
    }

    var body: some View {
        NavigationLink(destination: {
            SettingsPickerListView(selection: $selection, values: values)
                .navigationTitle(title)
        }, label: {
            let value = values.first { $0.id == selection }
            SettingsCell(title: title, value: value?.title)
        })
    }
}

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
            Section(content: {
                ForEach(values, content: makeRow)
            }, footer: {
                if let hint = values.first(where: { $0.id == selection })?.hint {
                    Text(hint)
                }
            })
        }
        .listStyle(.insetGrouped)
    }

    private func makeRow(for value: SettingsPickerValue<T>) -> some View {
        Button(action: {
            guard selection != value.id else { return }
            selection = value.id
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value.title)
                    if let details = value.details {
                        Text(details)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if value.id == selection {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundColor(.accentColor)

                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
