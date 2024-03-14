enum BlogListReducer {
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
}
