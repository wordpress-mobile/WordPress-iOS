import SwiftUI

struct SettingsPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let values: [SettingsPickerValue<T>]

    private var isEditable = true

    init(title: String, selection: Binding<T>, values: [SettingsPickerValue<T>]) {
        self.title = title
        self._selection = selection
        self.values = values
    }

    var body: some View {
        let value = values.first { $0.id == selection }
        let cell = SettingsCell(title: title, value: value?.title)
        if isEditable {
            NavigationLink(destination: {
                SettingsPickerListView(selection: $selection, values: values)
                    .navigationTitle(title)
            }, label: {
                cell
            })
        } else {
            cell
        }
    }

    /// Disables editing if set to `false`. By default, the picker is editable.
    func editable(_ isEditable: Bool) -> Self {
        var copy = self
        copy.isEditable = isEditable
        return copy
    }
}

struct SettingsPickerValue<T: Hashable>: Identifiable {
    let title: String
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
                Text(value.title)
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
