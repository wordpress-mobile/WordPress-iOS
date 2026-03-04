import Testing
import WordPressKit
@testable import WordPress

struct PluginDirectoryEntryLookupTests {

    /// The directory entries dictionary in PluginStoreState is keyed by slug.
    /// PluginViewModel must use `plugin.state.slug` (not `plugin.id`) to look
    /// up entries, because `id` and `slug` are different values.
    ///
    /// Example: id = "jetpack/jetpack.php", slug = "jetpack"
    @Test
    func pluginIdDiffersFromSlug() {
        let state = PluginState(
            id: "jetpack/jetpack.php",
            slug: "jetpack",
            active: true,
            name: "Jetpack",
            author: "Automattic",
            version: "5.5",
            updateState: .updated,
            autoupdate: false,
            automanaged: false,
            url: nil,
            settingsURL: nil
        )
        let plugin = Plugin(state: state, directoryEntry: nil)

        #expect(plugin.id != plugin.state.slug,
                "plugin.id and plugin.state.slug should differ")
        #expect(plugin.id == "jetpack/jetpack.php")
        #expect(plugin.state.slug == "jetpack")
    }

    @Test
    func directoryEntryLookupBySlugSucceeds() {
        let entry = makeDirectoryEntry(slug: "jetpack")

        // Simulate the directoryEntries dictionary (keyed by slug)
        var directoryEntries = [String: PluginDirectoryEntryState]()
        directoryEntries["jetpack"] = .present(entry)

        // Looking up by slug succeeds
        #expect(directoryEntries["jetpack"]?.entry != nil)
    }

    @Test
    func directoryEntryLookupByIdFails() {
        let entry = makeDirectoryEntry(slug: "jetpack")

        // Simulate the directoryEntries dictionary (keyed by slug)
        var directoryEntries = [String: PluginDirectoryEntryState]()
        directoryEntries["jetpack"] = .present(entry)

        // Looking up by plugin.id (the bug) fails because id != slug
        let pluginId = "jetpack/jetpack.php"
        #expect(directoryEntries[pluginId]?.entry == nil,
                "Looking up by plugin.id should fail since entries are keyed by slug")
    }

    @Test
    func pluginStoreGetPluginDirectoryEntryUsesSlugKey() {
        let store = PluginStore()
        let entry = makeDirectoryEntry(slug: "jetpack")

        // Populate the store's directoryEntries via its state
        store.state.directoryEntries["jetpack"] = .present(entry)

        // Lookup by slug succeeds
        #expect(store.getPluginDirectoryEntry(slug: "jetpack") != nil)

        // Lookup by id fails
        #expect(store.getPluginDirectoryEntry(slug: "jetpack/jetpack.php") == nil)
    }

    // MARK: - Helpers

    private func makeDirectoryEntry(slug: String) -> PluginDirectoryEntry {
        let json = """
        {
            "name": "Test Plugin",
            "slug": "\(slug)",
            "version": "1.0",
            "author": "Test",
            "rating": 80,
            "icons": {},
            "sections": {}
        }
        """.data(using: .utf8)!

        return try! JSONDecoder().decode(PluginDirectoryEntry.self, from: json)
    }
}
