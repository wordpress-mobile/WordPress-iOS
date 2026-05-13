import Foundation
import Combine

/// Caches the list of sites and the user's selected default site.
/// JSON-backed: two files inside the root directory.
@MainActor
final class SiteCatalog: ObservableObject {
    @Published private(set) var sites: [Site] = []
    @Published private(set) var defaultSiteID: Int64?

    var defaultSite: Site? {
        guard let id = defaultSiteID else { return nil }
        return sites.first(where: { $0.id == id })
    }

    private let sitesURL: URL
    private let defaultURL: URL

    init(rootURL: URL) {
        self.sitesURL = rootURL.appendingPathComponent("sites.json")
        self.defaultURL = rootURL.appendingPathComponent("default-site.json")
        load()
    }

    func setSites(_ sites: [Site]) {
        self.sites = sites
        do {
            try save(sites, to: sitesURL)
        } catch {
            watchLogger.error("SiteCatalog sites save failed: \(error, privacy: .public)")
        }
    }

    func setDefaultSiteID(_ id: Int64?) {
        self.defaultSiteID = id
        do {
            try save(id, to: defaultURL)
        } catch {
            watchLogger.error("SiteCatalog default site save failed: \(error, privacy: .public)")
        }
    }

    private func load() {
        if let data = try? Data(contentsOf: sitesURL),
           let decoded = try? JSONDecoder().decode([Site].self, from: data) {
            sites = decoded
        }
        if let data = try? Data(contentsOf: defaultURL),
           let decoded = try? JSONDecoder().decode(Int64?.self, from: data) {
            defaultSiteID = decoded
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }
}
