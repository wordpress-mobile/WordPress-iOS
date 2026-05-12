import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("NoteStore")
@MainActor
struct NoteStoreTests {

    private func makeStore() -> (store: NoteStore, tempDir: URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoteStoreTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return (NoteStore(rootURL: tempDir), tempDir)
    }

    private func makeNote(
        id: UUID = UUID(),
        status: NoteStatus = .queued,
        siteID: Int64 = 1,
        createdAt: Date = Date()
    ) -> VoiceNote {
        VoiceNote(
            id: id,
            createdAt: createdAt,
            siteID: siteID,
            audioFilename: "\(id.uuidString).m4a",
            durationSeconds: 30,
            status: status,
            statusReason: nil,
            postID: nil
        )
    }

    @Test func empty_store_returns_no_notes() {
        let (store, _) = makeStore()
        #expect(store.notes.isEmpty)
    }

    @Test func add_persists_a_note() throws {
        let (store, tempDir) = makeStore()
        let note = makeNote()

        try store.add(note)

        #expect(store.notes.count == 1)
        #expect(store.notes.first?.id == note.id)

        let reloaded = NoteStore(rootURL: tempDir)
        #expect(reloaded.notes.count == 1)
        #expect(reloaded.notes.first?.id == note.id)
    }

    @Test func update_replaces_existing_note_by_id() throws {
        let (store, _) = makeStore()
        var note = makeNote(status: .queued)
        try store.add(note)

        note.status = .uploading
        try store.update(note)

        #expect(store.notes.first?.status == .uploading)
    }

    @Test func update_throws_when_note_unknown() {
        let (store, _) = makeStore()
        let note = makeNote()

        #expect(throws: NoteStoreError.notFound) {
            try store.update(note)
        }
    }

    @Test func delete_removes_a_note() throws {
        let (store, _) = makeStore()
        let note = makeNote()
        try store.add(note)

        try store.delete(id: note.id)

        #expect(store.notes.isEmpty)
    }

    @Test func notes_are_sorted_newest_first() throws {
        let (store, _) = makeStore()
        let old = makeNote(createdAt: Date(timeIntervalSince1970: 1_000_000))
        let new = makeNote(createdAt: Date(timeIntervalSince1970: 2_000_000))
        try store.add(old)
        try store.add(new)

        #expect(store.notes.first?.id == new.id)
    }

    @Test func eviction_removes_oldest_terminal_notes_over_cap() throws {
        let (store, _) = makeStore()

        for i in 0..<18 {
            try store.add(makeNote(
                status: .draftReady,
                createdAt: Date(timeIntervalSince1970: TimeInterval(i))
            ))
        }
        try store.add(makeNote(status: .uploading))
        try store.add(makeNote(status: .transcribing))
        try store.add(makeNote(status: .drafting))

        // 21 total, cap is 20 → one oldest draftReady evicted
        #expect(store.notes.count == 20)
        let kept = store.notes.map(\.createdAt.timeIntervalSince1970)
        #expect(kept.contains(0) == false)
    }

    @Test func eviction_never_removes_active_notes() throws {
        let (store, _) = makeStore()
        for i in 0..<25 {
            try store.add(makeNote(
                status: .uploading,
                createdAt: Date(timeIntervalSince1970: TimeInterval(i))
            ))
        }
        #expect(store.notes.count == 25)
    }
}
