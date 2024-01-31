import SwiftUI

typealias BooleanUserDefaultsSections = [String: BooleanUserDefaultEntries]
typealias BooleanUserDefaultEntries = [String: BooleanUserDefault]

final class BooleanUserDefaultsDebugViewModel: ObservableObject {
    @Published private var allUserDefaultsSections = BooleanUserDefaultsSections()
    @Published var searchQuery: String = ""

    private var persistentRepository: UserPersistentRepository

    var userDefaultsSections: BooleanUserDefaultsSections {
        return filterUserDefaults(by: searchQuery)
    }

    let coreDataStack: CoreDataStack

    private func filterUserDefaults(by query: String) -> BooleanUserDefaultsSections {
        guard !query.isEmpty else {
            return allUserDefaultsSections
        }

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
        var otherSection = BooleanUserDefaultEntries()

        for (entryKey, entryValue) in allUserDefaults {
            if let groupedUserDefaults = entryValue as? [String: Bool], !isFeatureFlagsSection(entryKey) {
                loadedUserDefaultsSections[entryKey] = processGroupedUserDefaults(groupedUserDefaults)
            } else if let booleanUserDefault = entryValue as? Bool, !isGutenbergUserDefault(entryKey) {
                otherSection[entryKey] = BooleanUserDefault(title: entryKey, value: booleanUserDefault)
            }
        }
        loadedUserDefaultsSections[Strings.otherBooleanUserDefaultsSectionID] = otherSection
        allUserDefaultsSections = loadedUserDefaultsSections
    }

    private func processGroupedUserDefaults(_ userDefaults: [String: Bool]) -> BooleanUserDefaultEntries {
        userDefaults.reduce(into: BooleanUserDefaultEntries()) { result, keyValue in
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
            section[userDefaultID] = BooleanUserDefault(title: userDefaultID, value: value)
            let sectionValues = section.mapValues { $0.value }
            persistentRepository.set(sectionValues, forKey: sectionID)
        }
        load()
    }

    private func isGutenbergUserDefault(_ key: String) -> Bool {
        key.starts(with: Strings.gutenbergUserDefaultPrefix)
    }

    private func isFeatureFlagsSection(_ key: String) -> Bool {
        key.isEqual(to: Strings.featureFlagSectionKey)
    }
}

struct BooleanUserDefault {
    var title: String
    var value: Bool
}

private enum Strings {
    static let otherBooleanUserDefaultsSectionID = "Other"
    static let gutenbergUserDefaultPrefix = "com.wordpress.gutenberg-"
    static let featureFlagSectionKey = "FeatureFlagStoreCache"
}
