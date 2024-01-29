import SwiftUI

typealias BooleanUserDefaultsSections = [String: BooleanUserDefaults]
typealias BooleanUserDefaults = [String: Bool]

struct BooleanUserDefaultsDebugView: View {
    @StateObject private var viewModel = BooleanUserDefaultsDebugViewModel()

    var body: some View {
        List {
            ForEach(viewModel.preferenceSections.keys.sorted(), id: \.self) { sectionKey in
                let sectionPreferences = viewModel.preferenceSections[sectionKey] ?? [:]

                Section(header: Text(sectionKey)
                    .font(.caption)) {
                        ForEach(sectionPreferences.keys.sorted(), id: \.self) { preferenceKey in
                            let isOn = Binding<Bool>(
                                get: { sectionPreferences[preferenceKey] ?? false },
                                set: { newValue in viewModel.updatePreference(newValue, forSection: sectionKey, forPreference: preferenceKey) }
                            )
                            Toggle(preferenceKey, isOn: isOn)
                                .font(.caption)
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

private final class BooleanUserDefaultsDebugViewModel: ObservableObject {
    @Published private var allPreferenceSections = BooleanUserDefaultsSections()
    @Published var searchQuery: String = ""

    private var persistenceStore: UserPersistentRepository

    var preferenceSections: BooleanUserDefaultsSections {
        return if searchQuery.isEmpty {
            allPreferenceSections
        } else {
			filterPreferences(by: searchQuery)
        }
    }

    private func filterPreferences(by query: String) -> BooleanUserDefaultsSections {
        var filteredSections = BooleanUserDefaultsSections()
        allPreferenceSections.forEach { sectionKey, preferences in
            let filteredPreferences = preferences.filter { preferenceKey, _ in
                preferenceKey.localizedCaseInsensitiveContains(query)
            }
            if sectionKey.localizedCaseInsensitiveContains(query) || !filteredPreferences.isEmpty {
                filteredSections[sectionKey] = filteredPreferences.isEmpty ? preferences : filteredPreferences
            }
        }
        return filteredSections
    }

    init() {
        persistenceStore = UserPersistentStoreFactory.instance()
        load()
    }

    func load() {
        let allUserDefaults = persistenceStore.dictionaryRepresentation()
        var loadedPreferenceSections = BooleanUserDefaultsSections()

        allUserDefaults.forEach { entryKey, entryValue in
            if let groupedPreferences = entryValue as? BooleanUserDefaults {
                loadedPreferenceSections[entryKey] = groupedPreferences
            } else if let booleanUserDefault = entryValue as? Bool, !isSystemPreference(entryKey) {
                loadedPreferenceSections[Strings.otherBooleanUserDefaultsSectionID, default: [:]][entryKey] = booleanUserDefault
            }
        }

        allPreferenceSections = loadedPreferenceSections
    }

    func updatePreference(_ value: Bool, forSection sectionID: String, forPreference preferenceID: String) {
        if sectionID == Strings.otherBooleanUserDefaultsSectionID {
            persistenceStore.set(value, forKey: preferenceID)
        } else if var section = allPreferenceSections[sectionID] {
            section[preferenceID] = value
            persistenceStore.set(section, forKey: sectionID)
        }
        load()
    }

    private func isSystemPreference(_ key: String) -> Bool {
        key.starts(with: "com.wordpress.")
    }
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.booleanUserDefaults.title", value: "Boolean User Defaults", comment: "Boolean User Defaults Debug Menu screen title")
    static let otherBooleanUserDefaultsSectionID = "Other"
}
