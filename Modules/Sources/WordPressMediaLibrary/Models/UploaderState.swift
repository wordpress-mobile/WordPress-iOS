import Foundation

/// One row in the upload queue, in submission order. Failing in-flight
/// keeps the row at its original position so the Uploads screen does not
/// reshuffle when an upload transitions to failed (or back to pending
/// after Retry).
enum UploadEntry: Identifiable, Sendable {
    case pending(PendingUpload)
    case failed(FailedUpload)

    var id: UUID {
        switch self {
        case .pending(let p): return p.id
        case .failed(let f): return f.id
        }
    }
}

/// Snapshot of the uploader's queue. Emitted whenever any entry changes.
/// `entries` preserves submission order; `pendingCount` / `failedCount`
/// are derived for the banner.
struct UploaderState: Sendable {
    let entries: [UploadEntry]

    init(entries: [UploadEntry] = []) {
        self.entries = entries
    }

    var isEmpty: Bool { entries.isEmpty }

    var pendingCount: Int { pending.count }
    var failedCount: Int { failed.count }

    var pending: [PendingUpload] {
        entries.compactMap { if case .pending(let p) = $0 { return p } else { return nil } }
    }

    var failed: [FailedUpload] {
        entries.compactMap { if case .failed(let f) = $0 { return f } else { return nil } }
    }
}
