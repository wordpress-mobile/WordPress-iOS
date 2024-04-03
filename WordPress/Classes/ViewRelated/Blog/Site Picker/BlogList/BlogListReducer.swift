enum BlogListReducer {
    private enum Constants {
        static let pinnedDomainsKey = "site_switcher_pinned_domains_key"
        static let recentDomainsKey = "site_switcher_recent_domains_key"
        static let jsonEncoder = JSONEncoder()
        static let jsonDecoder = JSONDecoder()
        static let recentsTotalLimit = 8
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

    static func allSites(
        allSites: [BlogListView.Site],
        pinnedDomains: Set<String>,
        recentDomains: [String]
    ) -> [BlogListView.Site] {
        allSites.filter {
            !pinnedDomains.contains($0.domain) && !recentDomains.contains($0.domain)
        }
    }

    static func recentSites(
        allSites: [BlogListView.Site],
        recentDomains: [String]
    ) -> [BlogListView.Site] {
        var sites: [BlogListView.Site] = []
        for domain in recentDomains {
            if let recentSite = allSites.first(where: { $0.domain == domain }) {
                sites.append(recentSite)
            }
        }
        return sites
    }

    static func pinnedDomains(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance()
    ) -> Set<String> {
        if let data = repository.object(forKey: Constants.pinnedDomainsKey) as? Data,
           let decodedDomains = try? Constants.jsonDecoder.decode(Set<String>.self, from: data) {
             return decodedDomains
        }

        return []
    }

    static func togglePinnedDomain(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        domain: String
    ) {
        let tempPinnedDomains = pinnedDomains().symmetricDifference([domain])

        if tempPinnedDomains.contains(domain) {
            var tempRecentDomains = recentDomains()
            let beforeRemoveCount = tempRecentDomains.count
            tempRecentDomains.removeAll { recentDomain in
                recentDomain == domain
            }

            if tempRecentDomains.count != beforeRemoveCount {
                let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempRecentDomains)
                repository.set(encodedRecentDomains, forKey: Constants.recentDomainsKey)
            }
        }

        let encodedDomain = try? Constants.jsonEncoder.encode(tempPinnedDomains)
        repository.set(encodedDomain, forKey: Constants.pinnedDomainsKey)
    }

    static func recentDomains(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance()
    ) -> [String] {
        if let data = repository.object(forKey: Constants.recentDomainsKey) as? Data,
           let decodedDomains = try? Constants.jsonDecoder.decode([String].self, from: data) {
             return decodedDomains
        }

        return []
    }

    static func didSelectDomain(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        domain: String
    ) {
        guard !pinnedDomains().contains(domain) else {
            return
        }

        var tempRecentDomains = recentDomains()
        tempRecentDomains.removeAll { $0 == domain }
        tempRecentDomains.insert(domain, at: 0)

        if tempRecentDomains.count > Constants.recentsTotalLimit {
            tempRecentDomains = tempRecentDomains.dropLast(tempRecentDomains.count - Constants.recentsTotalLimit)
        }

        let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempRecentDomains)
        repository.set(encodedRecentDomains, forKey: Constants.recentDomainsKey)
    }
}
