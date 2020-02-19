import Foundation

@objc class PostServiceQueueList: NSObject {
    /// The current NSManagedObjectID being uploaded
    private var ids: [NSManagedObjectID] = []

    /// Shared Instance
    static let shared = PostServiceQueueList()

    private override init() {}

    @objc class func sharedInstance() -> PostServiceQueueList {
        return PostServiceQueueList.shared
    }

    /// Adds an id to the list of posts being uploaded
    ///
    /// - Parameter id: `NSManagedObjectID` of the post being uploaded
    ///
    @objc func uploading(_ id: NSManagedObjectID) {
        ids.append(id)
    }

    /// Given an id, returns a Bool that indicates if the post is being uploaded in a single place
    /// Ie.: there aren't multiple uploads for the same post going on.
    ///
    /// - Parameter id: `NSManagedObjectID` of the post being uploaded
    ///
    @objc func isSingleUpload(_ id: NSManagedObjectID) -> Bool {
        return ids.filter { $0 == id }.count == 1
    }

    /// Remove a given id from the list of posts being uploaded
    ///
    /// - Parameter id: `NSManagedObjectID` of the post being uploaded
    ///
    @objc func finishedUploading(_ id: NSManagedObjectID) {
        if let firstOccurrence = ids.firstIndex(of: id) {
            ids.remove(at: firstOccurrence)
        }
    }
}
