import SwiftUI

struct NoteRowView: View {
    let note: VoiceNote

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(relativeTimeString)
                    .font(.footnote)
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }
            Spacer()
            if note.status == .draftReady {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Voice note from \(relativeTimeString), \(statusText)")
    }

    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: note.createdAt, relativeTo: Date())
    }

    private var statusText: String {
        switch note.status {
        case .recording:    return "Recording…"
        case .queued:       return "Queued"
        case .uploading:    return "Uploading…"
        case .transcribing: return "Transcribing…"
        case .drafting:     return "Drafting…"
        case .draftReady:   return "Draft ready"
        case .failed:
            if let reason = note.statusReason.flatMap(FailureReason.init(rawValue:)) {
                return reason.userFacingMessage
            } else {
                return "Failed"
            }
        }
    }

    private var statusColor: Color {
        switch note.status {
        case .draftReady: return .green
        case .failed:     return .red
        default:          return .secondary
        }
    }
}
