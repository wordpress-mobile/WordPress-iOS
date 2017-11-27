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

    /// Site ID for this upload op
    ///
    @NSManaged public var siteID: Int32

    /// Post ID for this upload op
    ///
    @NSManaged public var postID: Int32

    /// True if this upload operation involves media; False if it is a post
    ///
    @NSManaged public var isMedia: Bool

    /// ID which is unique to a group of upload operations
    ///
    @NSManaged public var groupID: String

    /// NSURL background session ID assigned to this upload op
    ///
    @NSManaged public var backgroundSessionIdentifier: String?

    /// Name of the file in this upload op (Media only)
    ///
    @NSManaged public var fileName: String?

    /// Complete local URL (including filename) for this upload op (Media only)
    ///
    @NSManaged public var localURL: String?

    /// MIME Type for the media involved in this network op (Media only)
    ///
    @NSManaged public var mimeType: String?

    /// Post subject for this upload op (Post only)
    ///
    @NSManaged public var postTitle: String?

    /// Post content for this upload op (Post only)
    ///
    @NSManaged public var postContent: String?

    /// Post status for this upload op — e.g. "Draft" or "Publish" (Post only)
    ///
    @NSManaged public var postStatus: String?

    /// Date this upload op was created
    ///
    @NSManaged public var created: NSDate?
}

// MARK: - Computed Properties
//
extension UploadOperation {
    /// Returns a RemotePost object based on this UploadOperation
    ///
    var remotePost: RemotePost? {
        guard isMedia == false else {
            return nil
        }

        let remotePost: RemotePost = {
            let post = RemotePost()
            post.siteID = NSNumber(value: siteID)
            post.postID = NSNumber(value: postID)
            post.content = postContent
            post.title = postTitle
            post.status = postStatus
            return post
        }()

        return remotePost
    }

    /// Returns a RemoteMedia object based on this UploadOperation
    ///
    var remoteMedia: RemoteMedia? {
        guard isMedia == true else {
            return nil
        }

        let remoteMedia: RemoteMedia = {
            let media = RemoteMedia()
            media.file = fileName
            media.mimeType = mimeType
            if let localURL = localURL {
                media.localURL = URL(fileURLWithPath: localURL)
            }
            return media
        }()

        return remoteMedia
    }
}

// MARK: - Update Helpers

extension UploadOperation {
    /// Updates the local fields with the new values stored in a given RemoteMedia
    ///
    func updateWithMedia(remote: RemoteMedia) {
        isMedia = true
        localURL = remote.localURL?.absoluteString
        fileName = remote.file
        mimeType = remote.mimeType
    }

    /// Updates the local fields with the new values stored in a given RemotePost
    ///
    func updateWithPost(remote: RemotePost) {
        isMedia = false
        siteID = remote.siteID.int32Value
        postTitle = remote.title
        postContent = remote.content
        postStatus = remote.status
    }
}

// MARK: - UploadOperation Types

extension UploadOperation {
    /// Status types for a given upload operation
    ///
    enum UploadStatus: Int {
        /// Upload has been queued, but not started
        ///
        case Pending

        /// Upload has been initiated, but is not complete
        ///
        case InProgress

        /// Upload has completed successfully
        ///
        case Complete

        /// Upload has completed with an error
        ///
        case Error

        func stringValue() -> String {
            switch self {
            case .Pending:      return "Pending"
            case .InProgress:   return "In Progress"
            case .Complete:     return "Complete"
            case .Error:        return "Error"
            }
        }
    }
}
