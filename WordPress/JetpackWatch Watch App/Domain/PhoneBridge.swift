import Foundation

/// Abstracts the Watch's view of the paired iPhone.
/// Plan 1: implemented by `MockPhoneBridge` (returns canned data).
/// Plan 2: implemented by a `WCSession`-backed type.
@MainActor
protocol PhoneBridge: AnyObject {
    /// Begin observing connectivity / receiving updates from the phone.
    func start() async

    /// Send the audio file for a queued note to the phone.
    func handOff(noteID: UUID, audioURL: URL, siteID: Int64) async

    /// Ask the phone to retry a previously failed note.
    func retry(noteID: UUID) async

    /// Tell the phone the user picked a new default site on the Watch.
    func setDefaultSiteID(_ id: Int64) async

    /// Ask the phone to delete a note end-to-end.
    func deleteNote(_ id: UUID) async

    /// Called when the phone pushes a fresh site list.
    var onSitesReceived: (([Site]) -> Void)? { get set }

    /// Called when the phone pushes a state update for a note.
    /// Parameters: noteID, status, postID (if draft_ready), statusReason (if failed).
    var onNoteStateUpdate: ((UUID, NoteStatus, Int64?, String?) -> Void)? { get set }
}

@MainActor
final class MockPhoneBridge: PhoneBridge {
    var onSitesReceived: (([Site]) -> Void)?
    var onNoteStateUpdate: ((UUID, NoteStatus, Int64?, String?) -> Void)?

    private(set) var handedOffNoteIDs: [UUID] = []
    private(set) var retriedNoteIDs: [UUID] = []
    private(set) var defaultSiteIDsSet: [Int64] = []
    private(set) var deletedNoteIDs: [UUID] = []

    private let seedSites: [Site]

    init(seedSites: [Site]) {
        self.seedSites = seedSites
    }

    func start() async {
        onSitesReceived?(seedSites)
    }

    func handOff(noteID: UUID, audioURL: URL, siteID: Int64) async {
        handedOffNoteIDs.append(noteID)
    }

    func retry(noteID: UUID) async {
        retriedNoteIDs.append(noteID)
    }

    func setDefaultSiteID(_ id: Int64) async {
        defaultSiteIDsSet.append(id)
    }

    func deleteNote(_ id: UUID) async {
        deletedNoteIDs.append(id)
    }
}
