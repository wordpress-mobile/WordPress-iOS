import Testing
import Foundation
@testable import JetpackWatch_Watch_App

@Suite("VoiceNote")
struct VoiceNoteTests {

    @Test func codable_roundtrip_preserves_all_fields() throws {
        let original = VoiceNote(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: Date(timeIntervalSince1970: 1_715_500_000),
            siteID: 42,
            audioFilename: "voice-1.m4a",
            durationSeconds: 75,
            status: .uploading,
            statusReason: nil,
            postID: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VoiceNote.self, from: data)

        #expect(decoded == original)
    }

    @Test func isTerminal_returns_true_only_for_draftReady_and_failed() {
        #expect(NoteStatus.recording.isTerminal == false)
        #expect(NoteStatus.queued.isTerminal == false)
        #expect(NoteStatus.uploading.isTerminal == false)
        #expect(NoteStatus.transcribing.isTerminal == false)
        #expect(NoteStatus.drafting.isTerminal == false)
        #expect(NoteStatus.draftReady.isTerminal == true)
        #expect(NoteStatus.failed.isTerminal == true)
    }

    @Test func isActive_is_complement_of_isTerminal() {
        for status in NoteStatus.allCases {
            #expect(status.isActive == !status.isTerminal)
        }
    }
}
