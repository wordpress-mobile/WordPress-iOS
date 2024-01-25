import SwiftUI

struct BinaryPreferencesDebugView: View {
    @StateObject private var viewModel = BinaryPreferencesDebugViewModel()

    var body: some View {
        List {
            ForEach($viewModel.preferenceSections) { section in
                Section(header: Text(section.id)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)) {
                        ForEach(section.settings) { setting in
                            Toggle(setting.id, isOn: setting.value)
                                .font(.caption)
                        }
                    }
            }
        }
        .navigationTitle(Strings.title)
    }
}

private final class BinaryPreferencesDebugViewModel: ObservableObject {
    @Published var preferenceSections: [BinaryPreferenceSection] = []
    private var persistenceStore: UserPersistentRepository

    init() {
        persistenceStore = UserPersistentStoreFactory.instance()
        load()
    }

    func load() {
        let allPreferences = persistenceStore.dictionaryRepresentation()
        var loadedSections: [BinaryPreferenceSection] = []
        var ungroupedPreferences = BinaryPreferenceSection(key: "Other", settings: [])

        allPreferences.forEach { entryKey, entryValue in
            switch entryValue {
            case let groupedPreferences as [String: Bool]:
                loadedSections.append(
                    BinaryPreferenceSection(
                        key: entryKey,
                        settings: groupedPreferences.map {
                            BinaryPreference(key: $0.key, value: $0.value) }))
            case let binaryPreference as Bool where !isSystemPreference(entryKey):
                ungroupedPreferences.settings.append(BinaryPreference(key: entryKey, value: binaryPreference))
            default:
                break
            }
        }

        if !ungroupedPreferences.settings.isEmpty {
            loadedSections.append(ungroupedPreferences)
        }

        preferenceSections = loadedSections
    }

    func isSystemPreference(_ key: String) -> Bool {
        key.starts(with: "com.wordpress.")
    }
}

private struct BinaryPreferenceSection: Identifiable {
    let id: String
    var settings: [BinaryPreference]

    init(key: String, settings: [BinaryPreference]) {
        self.id = key
        self.settings = settings
    }
}

private struct BinaryPreference: Identifiable {
    let id: String
    var value: Bool

    init(key: String, value: Bool) {
        self.id = key
        self.value = value
    }
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.binaryPreferences.title", value: "Binary Preferences", comment: "Binary Preferences Debug Menu screen title")
}
