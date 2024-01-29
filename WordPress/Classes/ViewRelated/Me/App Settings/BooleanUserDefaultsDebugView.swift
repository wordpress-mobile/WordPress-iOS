import SwiftUI

private typealias BooleanUserDefaultsSections = [String: BooleanUserDefaults]
private typealias BooleanUserDefaults = [String: BooleanUserDefault]

struct BooleanUserDefaultsDebugView: View {
    @StateObject private var viewModel = BooleanUserDefaultsDebugViewModel()

    var body: some View {
        List {
            ForEach(viewModel.userDefaultsSections.keys.sorted(), id: \.self) { sectionKey in
                let userDefaultsSection = viewModel.userDefaultsSections[sectionKey] ?? BooleanUserDefaults()

                Section(header: Text(sectionKey)
                    .font(.caption)) {
                        ForEach(userDefaultsSection.keys.sorted(), id: \.self) { userDefaultKey in
                            let isOn = Binding<Bool>(
                                get: { userDefaultsSection[userDefaultKey]?.value ?? false },
                                set: { newValue in viewModel.updateUserDefault(newValue, forSection: sectionKey, forUserDefault: userDefaultKey) }
                            )
                            Toggle(userDefaultsSection[userDefaultKey]!.title, isOn: isOn)
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
    @Published private var allUserDefaultsSections = BooleanUserDefaultsSections()
    @Published var searchQuery: String = ""

    private var persistentRepository: UserPersistentRepository

    var userDefaultsSections: BooleanUserDefaultsSections {
        return if searchQuery.isEmpty {
            allUserDefaultsSections
        } else {
            filterUserDefaults(by: searchQuery)
        }
    }

    let coreDataStack: CoreDataStack

    private func filterUserDefaults(by query: String) -> BooleanUserDefaultsSections {
        var filteredSections = BooleanUserDefaultsSections()
        allUserDefaultsSections.forEach { sectionKey, userDefaults in
            let filteredUserDefaults = userDefaults.filter { key, userDefault in
                key.localizedCaseInsensitiveContains(query) || userDefault.title.localizedCaseInsensitiveContains(query)
            }
            if sectionKey.localizedCaseInsensitiveContains(query) || !filteredUserDefaults.isEmpty {
                filteredSections[sectionKey] = filteredUserDefaults.isEmpty ? userDefaults : filteredUserDefaults
            }
        }
        return filteredSections
    }

    init() {
        persistentRepository = UserPersistentStoreFactory.instance()
        coreDataStack = ContextManager.shared
        load()
    }

    func load() {
        let allUserDefaults = persistentRepository.dictionaryRepresentation()
        var loadedUserDefaultsSections = BooleanUserDefaultsSections()

        for (entryKey, entryValue) in allUserDefaults {
            if let groupedUserDefaults = entryValue as? [String: Bool] {
                loadedUserDefaultsSections[entryKey] = processGroupedUserDefaults(groupedUserDefaults)
            } else if let booleanUserDefault = entryValue as? Bool, !isSystemUserDefault(entryKey) {
                loadedUserDefaultsSections[Strings.otherBooleanUserDefaultsSectionID, default: [:]][entryKey] = BooleanUserDefault(title: entryKey, value: booleanUserDefault)
            }
        }

        allUserDefaultsSections = loadedUserDefaultsSections
    }

    private func processGroupedUserDefaults(_ userDefaults: [String: Bool]) -> BooleanUserDefaults {
        userDefaults.reduce(into: BooleanUserDefaults()) { result, keyValue in
            let (key, value) = keyValue
            result[key] = processSingleUserDefault(key: key, value: value)
        }
    }

    private func processSingleUserDefault(key: String, value: Bool) -> BooleanUserDefault {
        if let siteID = Int(key), let blogURL = try? Blog.lookup(withID: siteID, in: coreDataStack.mainContext)?.url {
            return BooleanUserDefault(title: blogURL, value: value)
        } else {
            return BooleanUserDefault(title: key, value: value)
        }
    }

    func updateUserDefault(_ value: Bool, forSection sectionID: String, forUserDefault userDefaultID: String) {
        if sectionID == Strings.otherBooleanUserDefaultsSectionID {
            persistentRepository.set(value, forKey: userDefaultID)
        } else if var section = allUserDefaultsSections[sectionID] {
            section[sectionID] = BooleanUserDefault(title: userDefaultID, value: value)
            persistentRepository.set(section, forKey: sectionID)
        }
        load()
    }

    private func isSystemUserDefault(_ key: String) -> Bool {
        key.starts(with: "com.wordpress.")
    }
}

private enum Strings {
    static let title = NSLocalizedString("debugMenu.booleanUserDefaults.title", value: "Boolean User Defaults", comment: "Boolean User Defaults Debug Menu screen title")
    static let otherBooleanUserDefaultsSectionID = "Other"
}

private struct BooleanUserDefault {
    var title: String
    var value: Bool
}
