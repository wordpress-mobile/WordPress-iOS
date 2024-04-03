enum BlogListReducer {
    struct PinnedDomain: Codable, Equatable {
        let domain: String
        let isRecent: Bool
    }

    enum Constants {
        static let pinnedDomainsKey = "site_switcher_pinned_domains_key"
        static let recentDomainsKey = "site_switcher_recent_domains_key"
        static let jsonEncoder = JSONEncoder()
        static let jsonDecoder = JSONDecoder()
        static let recentsTotalLimit = 8
    }

    static func syncCachedValues(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        allSites: [BlogListView.Site]
    ) {
        syncPinnedDomains(repository: repository, allSites: allSites)
        syncRecentDomains(repository: repository, allSites: allSites)
    }

    private static func syncPinnedDomains(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        allSites: [BlogListView.Site]
    ) {
        var tempPinnedDomains = pinnedDomains(repository: repository)
        let initialPinnedDomainsCount = tempPinnedDomains.count

        for pinnedDomain in tempPinnedDomains {
            if !allSites.compactMap({ $0.domain }).contains(pinnedDomain.domain) {
                let beforeRemoveCount = tempPinnedDomains.count

                tempPinnedDomains.removeAll { current in
                    current.domain == pinnedDomain.domain
                }

                if initialPinnedDomainsCount != tempPinnedDomains.count {
                    let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempPinnedDomains)
                    repository.set(encodedRecentDomains, forKey: Constants.pinnedDomainsKey)
                }
            }
        }
    }

    private static func syncRecentDomains(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        allSites: [BlogListView.Site]
    ) {
        var tempRecentDomains = recentDomains(repository: repository)
        let initialRecentDomainsCount = tempRecentDomains.count
        for recentDomain in tempRecentDomains {
            if !allSites.compactMap({ $0.domain }).contains(recentDomain) {
                let beforeRemoveCount = tempRecentDomains.count

                tempRecentDomains.removeAll { current in
                    current == recentDomain
                }

                if initialRecentDomainsCount != tempRecentDomains.count {
                    let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempRecentDomains)
                    repository.set(encodedRecentDomains, forKey: Constants.recentDomainsKey)
                }
            }
        }
    }

    static func pinnedSites(
        allSites: [BlogListView.Site],
        pinnedDomains: [String]
    ) -> [BlogListView.Site] {
        allSites.filter {
            pinnedDomains.contains(
                $0.domain
            )
        }
    }

    static func allSites(
        allSites: [BlogListView.Site],
        pinnedDomains: [String],
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
    ) -> [PinnedDomain] {
        if let data = repository.object(forKey: Constants.pinnedDomainsKey) as? Data,
           let decodedDomains = try? Constants.jsonDecoder.decode([PinnedDomain].self, from: data) {
            return decodedDomains
        }

        return []
    }

    static func toggleDomainPin(
        repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
        domain: String
    ) {
        var tempPinnedDomains = pinnedDomains(repository: repository)
        let existingPinnedDomain = tempPinnedDomains.first { pinnedDomain in
            pinnedDomain.domain == domain
        }

        if let existingPinnedDomain {
            // Pinned -> All/Recent
            if existingPinnedDomain.isRecent {
                var tempRecentDomains = recentDomains(repository: repository)
                tempRecentDomains.insert(domain, at: 0)

                let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempRecentDomains)
                repository.set(encodedRecentDomains, forKey: Constants.recentDomainsKey)
            }
            tempPinnedDomains.removeAll(where: { $0 == existingPinnedDomain })
        } else {
            // All/Recent -> Pinned
            var tempRecentDomains = recentDomains(repository: repository)
            let beforeRemoveCount = tempRecentDomains.count
            tempRecentDomains.removeAll { recentDomain in
                recentDomain == domain
            }

            let didRemoveFromRecent = tempRecentDomains.count != beforeRemoveCount
            if didRemoveFromRecent {
                let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempRecentDomains)
                repository.set(encodedRecentDomains, forKey: Constants.recentDomainsKey)
            }

            tempPinnedDomains.append(.init(domain: domain, isRecent: didRemoveFromRecent))
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
        guard !pinnedDomains(repository: repository).compactMap({ $0.domain }).contains(domain) else {
            return
        }

        var tempRecentDomains = recentDomains(repository: repository)
        tempRecentDomains.removeAll { $0 == domain }
        tempRecentDomains.insert(domain, at: 0)

        if tempRecentDomains.count > Constants.recentsTotalLimit {
            tempRecentDomains = tempRecentDomains.dropLast(tempRecentDomains.count - Constants.recentsTotalLimit)
        }

        let encodedRecentDomains = try? Constants.jsonEncoder.encode(tempRecentDomains)
        repository.set(encodedRecentDomains, forKey: Constants.recentDomainsKey)
    }
}
