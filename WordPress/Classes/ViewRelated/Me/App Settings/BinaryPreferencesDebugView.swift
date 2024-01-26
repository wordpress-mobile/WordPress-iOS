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
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)) {
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
        .onAppear {
            viewModel.load()
        }
    }
}

private final class BinaryPreferencesDebugViewModel: ObservableObject {
    @Published var preferenceSections: BinaryPreferenceSections = [:]
    private var persistenceStore: UserPersistentRepository

    init() {
        persistenceStore = UserPersistentStoreFactory.instance()
        load()
    }

    func load() {
        let allPreferences = persistenceStore.dictionaryRepresentation()
        var loadedPreferenceSections: BinaryPreferenceSections = [:]

        allPreferences.forEach { entryKey, entryValue in
            if let groupedPreferences = entryValue as? BinaryPreferences {
                loadedPreferenceSections[entryKey] = groupedPreferences
            } else if let binaryPreference = entryValue as? Bool, !isSystemPreference(entryKey) {
                loadedPreferenceSections[Strings.otherPreferencesSectionID, default: [:]][entryKey] = binaryPreference
            }
        }

        preferenceSections = loadedPreferenceSections
    }

    func updatePreference(_ value: Bool, forSection sectionID: String, forPreference preferenceID: String) {
        if sectionID == Strings.otherPreferencesSectionID {
            persistenceStore.set(value, forKey: preferenceID)
        } else if var section = preferenceSections[sectionID] {
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
