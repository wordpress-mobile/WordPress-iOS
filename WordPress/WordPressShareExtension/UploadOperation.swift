import Foundation
import CoreData
import WordPressKit

@objc(UploadOperation)
public class UploadOperation: NSManagedObject {
    /// Curent status for this upload op
    ///
    var currentStatus: UploadStatus {
        get {
            return UploadStatus(rawValue: Int(self.uploadStatus))!
        }
        set {
            self.uploadStatus = Int32(newValue.rawValue)
        }
    }
    @NSManaged private var uploadStatus: Int32

    /// ID which is unique to a group of upload operations within WPiOS (and its extensions)
    ///
    @NSManaged public var groupID: String?

    /// NSURL background session task ID assigned to this upload op. Unique within a given session.
    ///
    @NSManaged public var backgroundSessionTaskID: Int32

    /// NSURL background session ID assigned to this upload op
    ///
    @NSManaged public var backgroundSessionIdentifier: String?

    /// Site ID for this upload op
    ///
    @NSManaged public var siteID: Int64

    /// Date this upload op was created
    ///
    @NSManaged public var created: NSDate?
}

// MARK: - UploadOperation Types

extension UploadOperation {
    /// Status types for a given upload operation
    ///
    enum UploadStatus: Int {
        /// Upload has been queued, but not started
        ///
        case pending

        /// Upload has been initiated, but is not complete
        ///
        case inProgress

        /// Upload has completed successfully
        ///
        case complete

        /// Upload has completed with an error
        ///
        case error

        var stringValue: String {
            switch self {
            case .pending:      return "Pending"
            case .inProgress:   return "In Progress"
            case .complete:     return "Complete"
            case .error:        return "Error"
            }
        }
    }
}
