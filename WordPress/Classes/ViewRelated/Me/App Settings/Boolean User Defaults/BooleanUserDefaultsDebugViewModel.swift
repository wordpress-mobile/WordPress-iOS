import SwiftUI

final class BooleanUserDefaultsDebugViewModel: ObservableObject {
    private let persistentRepository: UserPersistentRepository
    private let coreDataStack: CoreDataStack

    private var allUserDefaultsSections = Sections() {
        didSet {
            self.reloadSections()
        }
    }

    @Published var searchQuery: String = "" {
        didSet {
            self.reloadSections()
        }
    }

    @Published var userDefaultsSections: Sections = []

    init(coreDataStack: CoreDataStack = ContextManager.shared,
         persistentRepository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.coreDataStack = coreDataStack
        self.persistentRepository = persistentRepository
    }

    func load() {
        let allUserDefaults = persistentRepository.dictionaryRepresentation()
        var loadedUserDefaultsSections = Sections()
        var otherSection = [Row]()

        for (key, value) in allUserDefaults {
            if let groupedUserDefaults = value as? [String: Bool], !isFeatureFlagsSection(key) {
                let section = Section(
                    key: key,
                    rows: processGroupedUserDefaults(groupedUserDefaults)
                )
                loadedUserDefaultsSections.append(section)
            } else if let booleanUserDefault = value as? Bool, !isGutenbergUserDefault(key) {
                otherSection.append(.init(key: key, title: key, value: booleanUserDefault))
            }
        }
        if !otherSection.isEmpty {
            let rows = otherSection.sorted { $0.title < $1.title }
            let section = Section(key: Strings.otherBooleanUserDefaultsSectionID, rows: rows)
            loadedUserDefaultsSections.append(section)
        }
        allUserDefaultsSections = loadedUserDefaultsSections
    }

    private func reloadSections() {
        self.userDefaultsSections = filterUserDefaults(by: searchQuery)
    }

    private func filterUserDefaults(by query: String) -> Sections {
        guard !query.isEmpty else {
            return allUserDefaultsSections
        }

        var filteredSections = Sections()
        allUserDefaultsSections.forEach { section in
            let filteredUserDefaults = section.rows.filter { entry in
                section.key.localizedCaseInsensitiveContains(query) || entry.title.localizedCaseInsensitiveContains(query)
            }
            if section.key.localizedCaseInsensitiveContains(query) || !filteredUserDefaults.isEmpty {
                let section = Section(
                    key: section.key,
                    rows: filteredUserDefaults.isEmpty ? section.rows : filteredUserDefaults
                )
                filteredSections.append(section)
            }
        }
        return filteredSections
    }

    private func processGroupedUserDefaults(_ userDefaults: [String: Bool]) -> [Row] {
        var rows = userDefaults.reduce(into: [Row]()) { result, keyValue in
            let (key, value) = keyValue
            result.append(processSingleUserDefault(key: key, value: value))
        }
        rows = rows.sorted { $0.title < $1.title }
        return rows
    }

    private func processSingleUserDefault(key: String, value: Bool) -> Row {
        let title = findBlog(byID: key)?.url ?? key
        return Row(key: key, title: title, value: value)
    }

    private func findBlog(byID id: String) -> Blog? {
        return try? Blog.lookup(withID: Int(id) ?? 0, in: coreDataStack.mainContext)
    }

    func updateUserDefault(_ newValue: Bool, forSection targetSection: String, forRow targetRow: String) {
        updateAllUserDefaultsSections(newValue, forSection: targetSection, forRow: targetRow)
        if targetSection == Strings.otherBooleanUserDefaultsSectionID {
            persistentRepository.set(newValue, forKey: targetRow)
        } else {
            guard let section = allUserDefaultsSections.first(where: { $0.key == targetSection }) else {
                return
            }
            let entries = section.rows.reduce(into: [String: Bool]()) { result, row in
                if row.key == targetRow {
                    result[row.key] = newValue
                } else {
                    result[row.key] = row.value
                }
            }
            persistentRepository.set(entries, forKey: targetSection)
        }
    }

    func updateAllUserDefaultsSections(_ newValue: Bool, forSection targetSection: String, forRow targetRow: String) {
        allUserDefaultsSections = allUserDefaultsSections.map { currentSection in
            if currentSection.key == targetSection {
                let updatedRows = currentSection.rows.map { currentRow in
                    if currentRow.key == targetRow {
                        return Row(key: currentRow.key, title: currentRow.title, value: newValue)
                    } else {
                        return currentRow
                    }
                }
                return Section(key: currentSection.key, rows: updatedRows)
            } else {
                return currentSection
            }
        }
    }

    private func isGutenbergUserDefault(_ key: String) -> Bool {
        key.starts(with: Strings.gutenbergUserDefaultPrefix)
    }

    private func isFeatureFlagsSection(_ key: String) -> Bool {
        key.isEqual(to: Strings.featureFlagSectionKey)
    }

    // MARK: - Types

    struct Section {
        let key: String
        let rows: [Row]
    }

    final class Row {
        let key: String
        let title: String
        let value: Bool

        init(key: String, title: String, value: Bool) {
            self.key = key
            self.title = title
            self.value = value
        }
    }

    typealias Sections = [Section]

}

// MARK: - Constants

private enum Strings {
    static let otherBooleanUserDefaultsSectionID = "Other"
    static let gutenbergUserDefaultPrefix = "com.wordpress.gutenberg-"
    static let featureFlagSectionKey = "FeatureFlagStoreCache"
}
