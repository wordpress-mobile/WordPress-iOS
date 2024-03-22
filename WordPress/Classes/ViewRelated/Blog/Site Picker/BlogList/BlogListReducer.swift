enum BlogListReducer {
    private enum Constants {
        static let pinnedDomainsKey = "site_switcher_pinned_domains_key"
        static let jsonEncoder = JSONEncoder()
        static let jsonDecoder = JSONDecoder()
    }

    static func pinnedSites(
        allSites: [BlogListView.Site],
        pinnedDomains: Set<String>
    ) -> [BlogListView.Site] {
        allSites.filter {
            pinnedDomains.contains(
                $0.domain
            )
        }
    }

    static func unPinnedSites(
        allSites: [BlogListView.Site],
        pinnedDomains: Set<String>
    ) -> [BlogListView.Site] {
        allSites.filter {
            !pinnedDomains.contains(
                $0.domain
            )
        }
    }

    static func pinnedDomains(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance()
    ) -> Set<String>? {
        if let data = repository.object(forKey: Constants.pinnedDomainsKey) as? Data,
           let decodedDomains = try? Constants.jsonDecoder.decode(Set<String>.self, from: data) {
             return decodedDomains
        }

        return nil
    }

    static func togglePinnedDomain(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        domain: String
    ) {
        if var decodedPinnedDomains = pinnedDomains() {
            decodedPinnedDomains = decodedPinnedDomains.symmetricDifference([domain])
            let encodedDomain = try? Constants.jsonEncoder.encode(decodedPinnedDomains)
            repository.set(encodedDomain, forKey: Constants.pinnedDomainsKey)
        } else {
            var freshPinnedDomains: Set<String> = [domain]
            let encodedDomain = try? Constants.jsonEncoder.encode(freshPinnedDomains)
            repository.set(encodedDomain, forKey: Constants.pinnedDomainsKey)
        }
    }
}
