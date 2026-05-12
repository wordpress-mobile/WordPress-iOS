import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("SiteCatalog")
@MainActor
struct SiteCatalogTests {

    private func makeCatalog() -> (catalog: SiteCatalog, tempDir: URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SiteCatalogTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return (SiteCatalog(rootURL: tempDir), tempDir)
    }

    @Test func empty_catalog_has_no_sites_and_no_default() {
        let (catalog, _) = makeCatalog()
        #expect(catalog.sites.isEmpty)
        #expect(catalog.defaultSiteID == nil)
    }

    @Test func setSites_persists_and_reloads() {
        let (catalog, tempDir) = makeCatalog()
        catalog.setSites([Site(id: 1, name: "Alpha"), Site(id: 2, name: "Beta")])

        let reloaded = SiteCatalog(rootURL: tempDir)
        #expect(reloaded.sites.count == 2)
        #expect(reloaded.sites.contains(where: { $0.id == 1 }))
    }

    @Test func setDefaultSiteID_persists_and_reloads() {
        let (catalog, tempDir) = makeCatalog()
        catalog.setSites([Site(id: 1, name: "Alpha")])
        catalog.setDefaultSiteID(1)

        let reloaded = SiteCatalog(rootURL: tempDir)
        #expect(reloaded.defaultSiteID == 1)
    }

    @Test func defaultSite_returns_matching_Site() {
        let (catalog, _) = makeCatalog()
        catalog.setSites([Site(id: 1, name: "Alpha"), Site(id: 2, name: "Beta")])
        catalog.setDefaultSiteID(2)
        #expect(catalog.defaultSite?.name == "Beta")
    }

    @Test func defaultSite_is_nil_when_default_id_no_longer_in_sites() {
        let (catalog, _) = makeCatalog()
        catalog.setSites([Site(id: 1, name: "Alpha")])
        catalog.setDefaultSiteID(99)
        #expect(catalog.defaultSite == nil)
    }
}
