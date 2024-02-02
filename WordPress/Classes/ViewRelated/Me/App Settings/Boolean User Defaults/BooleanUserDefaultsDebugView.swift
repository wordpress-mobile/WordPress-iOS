import SwiftUI

struct BooleanUserDefaultsDebugView: View {
    @StateObject private var viewModel = BooleanUserDefaultsDebugViewModel()

    var body: some View {
        List {
            ForEach(viewModel.userDefaultsSections, id: \.key) { section in
                Section(header: Text(section.key)
                    .font(.caption)) {
                        ForEach(section.rows, id: \.key) { row in
                            let isOn = Binding<Bool>(
                                get: {
                                    row.value
                                },
                                set: { newValue in
                                    viewModel.updateUserDefault(
                                        newValue,
                                        forSection: section.key,
                                        forRow: row.key
                                    )
                                }
                            )
                            Toggle(row.title, isOn: isOn)
                                .font(.caption)
                                .toggleStyle(
                                    SwitchToggleStyle(
                                        tint: Color.DS.Background.brand(isJetpack: AppConfiguration.isJetpack)))
                        }
                    }
            }
        }
        .navigationTitle(Strings.title)
        .searchable(text: $viewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .onAppear {
            viewModel.load()
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.booleanUserDefaults.title", value: "Boolean User Defaults", comment: "Boolean User Defaults Debug Menu screen title")

    static let unrecognizedEntryTitle = "Unrecognized Entry"
}
