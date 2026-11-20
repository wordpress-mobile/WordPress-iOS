import WordPressShared

/// The sites this app install created as blank sites through the short flow.
///
/// The record is local and keyed by site ID. A reinstall loses it, which is accepted: the design card it
/// enables never shows again for those sites, and nothing needs to be stored on WordPress.com.
struct BlankSiteRecord {
    private static let key = "blank-site-record"

    private let repository: UserPersistentRepository

    init(repository: UserPersistentRepository = UserDefaults.standard) {
        self.repository = repository
    }

    func contains(siteID: Int) -> Bool {
        siteIDs.contains(siteID)
    }

    func insert(siteID: Int) {
        var siteIDs = siteIDs
        guard !siteIDs.contains(siteID) else { return }
        siteIDs.append(siteID)
        repository.set(siteIDs, forKey: Self.key)
    }

    func remove(siteID: Int) {
        repository.set(siteIDs.filter { $0 != siteID }, forKey: Self.key)
    }

    private var siteIDs: [Int] {
        repository.array(forKey: Self.key) as? [Int] ?? []
    }
}
