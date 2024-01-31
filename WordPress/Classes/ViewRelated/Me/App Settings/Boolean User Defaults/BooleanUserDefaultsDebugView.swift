import SwiftUI

struct BooleanUserDefaultsDebugView: View {
    @StateObject private var viewModel = BooleanUserDefaultsDebugViewModel()

    var body: some View {
        List {
            ForEach(viewModel.userDefaultsSections.keys.sorted(), id: \.self) { sectionKey in
                let userDefaultsSection = viewModel.userDefaultsSections[sectionKey] ?? BooleanUserDefaultEntries()

                Section(header: Text(sectionKey)
                    .font(.caption)) {
                        ForEach(userDefaultsSection.keys.sorted(), id: \.self) { userDefaultKey in
                            let isOn = Binding<Bool>(
                                get: { userDefaultsSection[userDefaultKey]?.value ?? false },
                                set: { newValue in viewModel.updateUserDefault(newValue, forSection: sectionKey, forUserDefault: userDefaultKey) }
                            )
                            Toggle(userDefaultsSection[userDefaultKey]?.title ?? Strings.unrecognizedEntryTitle, isOn: isOn)
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
