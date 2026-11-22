import Foundation
import WordPressData

extension BlogListViewModel {
    static let sidebarSiteLimit = 4

    /// Returns a list of sites to display in the sidebar, ensuring that:
    /// 1. The current site is always included
    /// 2. The most recent sites are included up to the display limit
    /// 3. The sites are sorted alphabetically
    var topSites: [BlogListSiteViewModel] {
        var displaySites = [BlogListSiteViewModel]()
        var encounteredIDs = Set<TaggedManagedObjectID<Blog>>()

        // Ensure the current site is included (if there is one)
        if let currentSite {
            displaySites.append(currentSite)
            encounteredIDs.insert(currentSite.id)
        }

        // Add recent sites up to the limit, if we still have space, add other sites
        for site in recentSites + allSites {
            if displaySites.count >= Self.sidebarSiteLimit {
                break
            }

            if !encounteredIDs.contains(site.id) {
                displaySites.append(site)
                encounteredIDs.insert(site.id)
            }
        }

        // Sort the sites alphabetically
        return displaySites.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
