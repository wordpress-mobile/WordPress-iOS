import Foundation

/// A helper object encapsulating a status of Automated Transfer operation.
public struct AutomatedTransferStatus {
    public enum State: String, RawRepresentable {
        case active
        case backfilling
        case complete
        case error
        case notFound = "not found"
        case unknownStatus = "unknown_status"
        case uploading
        case pending
    }

    public let status: State
    public let step: Int?
    public let totalSteps: Int?

    init?(status statusString: String) {
        guard let status = State(rawValue: statusString) else {
            return nil
        }

        self.status = status
        self.step = nil
        self.totalSteps = nil
    }

    init?(status statusString: String, step: Int, totalSteps: Int) {
        guard let status = State(rawValue: statusString) else {
            return nil
        }

        self.status = status
        self.step = step
        self.totalSteps = totalSteps
    }

}
