import SwiftUI

typealias BinaryPreferenceSections = [String: BinaryPreferences]
typealias BinaryPreferences = [String: Bool]

struct BinaryPreferencesDebugView: View {
    @StateObject private var viewModel = BinaryPreferencesDebugViewModel()

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

private final class BinaryPreferencesDebugViewModel: ObservableObject {
    @Published private var allPreferenceSections = BinaryPreferenceSections()
    @Published var searchQuery: String = ""

    private var persistenceStore: UserPersistentRepository

    var preferenceSections: BinaryPreferenceSections {
        return if searchQuery.isEmpty {
            allPreferenceSections
        } else {
			filterPreferences(by: searchQuery)
        }
    }

    private func filterPreferences(by query: String) -> BinaryPreferenceSections {
        var filteredSections = BinaryPreferenceSections()
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
        let allPreferences = persistenceStore.dictionaryRepresentation()
        var loadedPreferenceSections = BinaryPreferenceSections()

        allPreferences.forEach { entryKey, entryValue in
            if let groupedPreferences = entryValue as? BinaryPreferences {
                loadedPreferenceSections[entryKey] = groupedPreferences
            } else if let binaryPreference = entryValue as? Bool, !isSystemPreference(entryKey) {
                loadedPreferenceSections[Strings.otherPreferencesSectionID, default: [:]][entryKey] = binaryPreference
            }
        }

        allPreferenceSections = loadedPreferenceSections
    }

    func updatePreference(_ value: Bool, forSection sectionID: String, forPreference preferenceID: String) {
        if sectionID == Strings.otherPreferencesSectionID {
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
    static let title = NSLocalizedString("debugMenu.binaryPreferences.title", value: "Binary Preferences", comment: "Binary Preferences Debug Menu screen title")
    static let otherPreferencesSectionID = "Other"
}
