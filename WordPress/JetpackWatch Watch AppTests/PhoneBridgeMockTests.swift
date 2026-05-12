import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("MockPhoneBridge")
@MainActor
struct PhoneBridgeMockTests {

    @Test func start_with_seed_sites_publishes_them_via_callback() async {
        let sites: [Site] = [Site(id: 1, name: "Alpha")]
        let bridge = MockPhoneBridge(seedSites: sites)

        var received: [Site]?
        bridge.onSitesReceived = { received = $0 }
        await bridge.start()

        #expect(received?.count == 1)
        #expect(received?.first?.id == 1)
    }

    @Test func handOff_records_the_note_id() async {
        let bridge = MockPhoneBridge(seedSites: [])
        let id = UUID()
        let url = URL(fileURLWithPath: "/tmp/x.m4a")

        await bridge.handOff(noteID: id, audioURL: url, siteID: 1)

        #expect(bridge.handedOffNoteIDs.contains(id))
    }

    @Test func retry_records_the_note_id() async {
        let bridge = MockPhoneBridge(seedSites: [])
        let id = UUID()

        await bridge.retry(noteID: id)

        #expect(bridge.retriedNoteIDs.contains(id))
    }

    @Test func setDefaultSiteID_records_the_value() async {
        let bridge = MockPhoneBridge(seedSites: [])

        await bridge.setDefaultSiteID(42)

        #expect(bridge.defaultSiteIDsSet == [42])
    }

    @Test func deleteNote_records_the_note_id() async {
        let bridge = MockPhoneBridge(seedSites: [])
        let id = UUID()

        await bridge.deleteNote(id)

        #expect(bridge.deletedNoteIDs.contains(id))
    }
}
