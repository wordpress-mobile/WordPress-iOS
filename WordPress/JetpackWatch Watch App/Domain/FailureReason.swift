import Foundation

nonisolated enum FailureReason: String, CaseIterable, Sendable {
    case uploadError = "upload_error"
    case transcriptionError = "transcription_error"
    case draftError = "draft_error"
    case siteForbidden = "site_forbidden"
    case invalidAudio = "invalid_audio"
    case timeout
    case cancelled

    var userFacingMessage: String {
        switch self {
        case .uploadError:        return "Couldn't upload — tap to retry"
        case .transcriptionError: return "Transcription failed — tap to retry"
        case .draftError:         return "Draft generation failed — tap to retry"
        case .siteForbidden:      return "You can't post to this site"
        case .invalidAudio:       return "Recording was unreadable"
        case .timeout:            return "Took too long — tap to retry"
        case .cancelled:          return "Cancelled"
        }
    }
}
