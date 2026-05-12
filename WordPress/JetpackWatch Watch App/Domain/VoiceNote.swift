import Foundation

/// A voice note as known to the Watch. The Watch is authoritative for
/// `.recording` and `.queued`; the phone is authoritative for `.uploading`
/// and later (see the design spec for the full state machine).
nonisolated struct VoiceNote: Codable, Equatable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    let siteID: Int64
    let audioFilename: String
    let durationSeconds: Int
    var status: NoteStatus
    var statusReason: String?
    var postID: Int64?
}

nonisolated enum NoteStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case recording
    case queued
    case uploading
    case transcribing
    case drafting
    case draftReady = "draft_ready"
    case failed

    var isTerminal: Bool {
        switch self {
        case .draftReady, .failed: return true
        case .recording, .queued, .uploading, .transcribing, .drafting: return false
        }
    }

    var isActive: Bool { !isTerminal }
}
