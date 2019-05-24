import Foundation
import CoreData
import WordPressKit

/// NSPersistentContainer subclass that defaults to the shared container directory
///
final class SharedPersistentContainer: NSPersistentContainer {
    internal override class func defaultDirectoryURL() -> URL {
        var url = super.defaultDirectoryURL()
        if let newURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName) {
            url = newURL
        }
        return url
    }
}

class SharedCoreDataStack {

    // MARK: - Private Properties

    fileprivate let modelName: String

    fileprivate lazy var storeContainer: SharedPersistentContainer = {
        let container = SharedPersistentContainer(name: self.modelName)
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                DDLogError("Error loading persistent stores: \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Public Properties

    /// Returns the managed context associated with the main queue
    ///
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()

    // MARK: - Initializers

    /// Initialize the SharedPersistentContainer using the standard Extensions model.
    ///
    convenience init() {
        self.init(modelName: Constants.sharedModelName)
    }

    /// Initialize the core data stack with the given model name.
    ///
    /// This initializer is meant for testing. You probably want to use the convenience `init()` that uses the standard Extensions model
    ///
    /// - Parameters:
    ///     - modelName: Name of the model to initialize the SharedPersistentContainer with.
    ///
    init(modelName: String) {
        self.modelName = modelName
    }

    // MARK: - Public Funcntions

    /// Commit unsaved changes (if any exist) using the main queue's managed context
    ///
    func saveContext() {
        guard managedContext.hasChanges else {
            return
        }

        do {
            try managedContext.save()
        } catch let error as NSError {
            DDLogError("Error saving context: \(error), \(error.userInfo)")
        }
    }
}

// MARK: - Persistence Helpers - Fetching

extension SharedCoreDataStack {

    /// Fetches the group ID for the provided session ID.
    ///
    /// - Parameter sessionID: the session ID
    /// - Returns: group ID or nil if session does not have an associated group
    ///
    func fetchGroupID(for sessionID: String) -> String? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UploadOperation")
        request.predicate = NSPredicate(format: "(backgroundSessionIdentifier == %@)", sessionID)
        request.fetchLimit = 1
        guard let results = (try? managedContext.fetch(request)) as? [UploadOperation], let groupID = results.first?.groupID else {
            return nil
        }
        return groupID
    }

    /// Fetch the post upload op for the provided managed object ID string
    ///
    /// - Parameter objectID: Managed object ID string for a given post upload op
    /// - Returns: PostUploadOperation or nil
    ///
    func fetchPostUploadOp(withObjectID objectID: String) -> PostUploadOperation? {
        guard let storeCoordinator = managedContext.persistentStoreCoordinator,
            let url = URL(string: objectID),
            let managedObjectID = storeCoordinator.managedObjectID(forURIRepresentation: url) else {
                return nil
        }

        return fetchPostUploadOp(withObjectID: managedObjectID)
    }

    /// Fetch the post upload op for the provided managed object ID
    ///
    /// - Parameter postUploadOpObjectID: Managed object ID for a given post upload op
    /// - Returns: PostUploadOperation or nil
    ///
    func fetchPostUploadOp(withObjectID postUploadOpObjectID: NSManagedObjectID) -> PostUploadOperation? {
        var postUploadOp: PostUploadOperation?
        do {
            postUploadOp = try managedContext.existingObject(with: postUploadOpObjectID) as? PostUploadOperation
        } catch {
            DDLogError("Error loading PostUploadOperation Object with ID: \(postUploadOpObjectID)")
        }
        return postUploadOp
    }

    /// Fetch the upload op that represents a post for a given group ID.
    ///
    /// NOTE: There will only ever be one post associated with a group of upload ops.
    ///
    /// - Parameter groupID: group ID for a set of upload ops
    /// - Returns: post PostUploadOperation or nil
    ///
    func fetchPostUploadOp(for groupID: String) -> PostUploadOperation? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PostUploadOperation")
        request.predicate = NSPredicate(format: "(groupID == %@)", groupID)
        request.fetchLimit = 1
        guard let results = (try? managedContext.fetch(request)) as? [PostUploadOperation] else {
            return nil
        }
        return results.first
    }

    /// Fetch the media upload ops for a given group ID.
    ///
    /// - Parameter groupID: group ID for a set of upload ops
    /// - Returns: An array of MediaUploadOperations or nil
    ///
    func fetchMediaUploadOps(for groupID: String) -> [MediaUploadOperation]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MediaUploadOperation")
        request.predicate = NSPredicate(format: "(groupID == %@)", groupID)
        guard let results = (try? managedContext.fetch(request)) as? [MediaUploadOperation] else {
            DDLogError("Failed to fetch MediaUploadOperation for group ID: \(groupID)")
            return nil
        }
        return results
    }

    /// Fetch the media upload op that matches the provided filename and background session ID
    ///
    /// - Parameters:
    ///   - fileName: the name of the local (and remote) file associated with a upload op
    ///   - sessionID: background session ID
    /// - Returns: MediaUploadOperation or nil
    ///
    func fetchMediaUploadOp(for fileName: String, with sessionID: String) -> MediaUploadOperation? {
        guard let fileNameWithoutExtension = URL(string: fileName)?.deletingPathExtension().lastPathComponent else {
            return nil
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MediaUploadOperation")
        request.predicate = NSPredicate(format: "(fileName BEGINSWITH %@ AND backgroundSessionIdentifier == %@)", fileNameWithoutExtension.lowercased(), sessionID)
        request.fetchLimit = 1
        guard let results = (try? managedContext.fetch(request)) as? [MediaUploadOperation] else {
            return nil
        }
        return results.first
    }

    /// Fetch the post and media upload ops for a given URLSession taskIdentifier.
    ///
    /// NOTE: Because the WP API allows us to upload multiple media files in a single request, there
    /// will most likely be multiple upload ops for a given task id.
    ///
    /// - Parameters:
    ///   - taskIdentifier: the taskIdentifier from a URLSessionTask
    ///   - sessionID: background session ID
    /// - Returns: An array of UploadOperations or nil
    ///
    func fetchSessionUploadOps(for taskIdentifier: Int, with sessionID: String) -> [UploadOperation]? {
        var uploadOps: [UploadOperation]?
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UploadOperation")
        request.predicate = NSPredicate(format: "(backgroundSessionTaskID == %d AND backgroundSessionIdentifier == %@)", taskIdentifier, sessionID)
        do {
            uploadOps = try managedContext.fetch(request) as! [MediaUploadOperation]
        } catch {
            DDLogError("Failed to fetch MediaUploadOperation: \(error)")
        }

        return uploadOps
    }
}

// MARK: - Persistence Helpers - Saving and Updating

extension SharedCoreDataStack {

    /// Updates the status using the given uploadOp's ObjectID.
    ///
    /// - Parameters:
    ///   - status: New status
    ///   - uploadOpObjectID: Managed object ID for a given upload op
    ///
    func updateStatus(_ status: UploadOperation.UploadStatus, forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID) {
        var uploadOp: UploadOperation?
        do {
            uploadOp = try managedContext.existingObject(with: uploadOpObjectID) as? UploadOperation
        } catch {
            DDLogError("Error setting \(status.stringValue) status for UploadOperation Object with ID: \(uploadOpObjectID) — could not fetch object.")
            return
        }
        uploadOp?.currentStatus = status
        saveContext()
    }

    /// Saves a new media upload operation with the provided values
    ///
    /// - Parameters:
    ///   - remoteMedia: RemoteMedia object containing the values to persist
    ///   - sessionID: background session ID
    ///   - groupIdentifier: group ID for a set of upload ops
    ///   - siteID: New site ID
    ///   - status: New status
    /// - Returns: Managed object ID of newly saved media upload operation object
    ///
    func saveMediaOperation(_ remoteMedia: RemoteMedia, sessionID: String, groupIdentifier: String, siteID: NSNumber, with status: UploadOperation.UploadStatus) -> NSManagedObjectID {
        let mediaUploadOp = MediaUploadOperation(context: managedContext)
        mediaUploadOp.updateWithMedia(remote: remoteMedia)
        mediaUploadOp.backgroundSessionIdentifier = sessionID
        mediaUploadOp.groupID = groupIdentifier
        mediaUploadOp.created = NSDate()
        mediaUploadOp.currentStatus = status
        mediaUploadOp.siteID = siteID.int64Value
        saveContext()
        return mediaUploadOp.objectID
    }

    /// Updates the remote media URL and remote media ID on an upload op that corresponds with the provided
    /// file name. If a parameter is nil, that specific param will not be updated.
    ///
    /// Note: We are searching for the upload op using a filename because a given task ID can have
    /// multiple files associated with it.
    ///
    /// - Parameters:
    ///   - fileName: the fileName from a URLSessionTask
    ///   - sessionID: background session ID
    ///   - remoteMediaID: remote media ID
    ///   - remoteURL: remote media URL string
    ///
    func updateMediaOperation(for fileName: String, with sessionID: String, remoteMediaID: Int64?, remoteURL: String?, width: Int32?, height: Int32?) {
        guard let mediaUploadOp = fetchMediaUploadOp(for: fileName, with: sessionID) else {
            DDLogError("Error loading UploadOperation Object with File Name: \(fileName)")
            return
        }

        if let remoteMediaID = remoteMediaID {
            mediaUploadOp.remoteMediaID = remoteMediaID
        }
        if let width = width {
            mediaUploadOp.width = width
        }
        if let height = height {
            mediaUploadOp.height = height
        }
        mediaUploadOp.remoteURL = remoteURL
        saveContext()
    }

    /// Saves a new post upload operation with the provided values
    ///
    /// - Parameters:
    ///   - remotePost: RemotePost object containing the values to persist.
    ///   - groupIdentifier: group ID for a set of upload ops
    ///   - status: New status
    /// - Returns: Managed object ID of newly saved post upload operation object
    ///
    func savePostOperation(_ remotePost: RemotePost, groupIdentifier: String, with status: UploadOperation.UploadStatus) -> NSManagedObjectID {
        let postUploadOp = PostUploadOperation(context: managedContext)
        postUploadOp.updateWithPost(remote: remotePost)
        postUploadOp.groupID = groupIdentifier
        postUploadOp.created = NSDate()
        postUploadOp.currentStatus = status

        saveContext()
        return postUploadOp.objectID
    }

    /// Update an existing post upload operation with a new status and remote post ID
    ///
    /// - Parameters:
    ///   - status: New status
    ///   - remotePostID: New remote post ID
    ///   - postUploadOpObjectID: Managed object ID for a given post upload op
    ///
    func updatePostOperation(with status: UploadOperation.UploadStatus, remotePostID: Int64, forPostUploadOpWithObjectID postUploadOpObjectID: NSManagedObjectID) {
        guard let postUploadOp = (try? managedContext.existingObject(with: postUploadOpObjectID)) as? PostUploadOperation else {
            DDLogError("Error loading PostUploadOperation Object with ID: \(postUploadOpObjectID)")
            return
        }
        postUploadOp.currentStatus = status
        postUploadOp.remotePostID = remotePostID
        saveContext()
    }

    /// Update an existing upload operations with a new background session task ID
    ///
    /// - Parameters:
    ///   - taskID: New background session task ID
    ///   - uploadOpObjectID: Managed object ID for a given upload op
    ///
    func updateTaskID(_ taskID: NSNumber, forUploadOpWithObjectID uploadOpObjectID: NSManagedObjectID) {
        var uploadOp: UploadOperation?
        do {
            uploadOp = try managedContext.existingObject(with: uploadOpObjectID) as? UploadOperation
        } catch {
            DDLogError("Error loading UploadOperation Object with ID: \(uploadOpObjectID)")
            return
        }
        uploadOp?.backgroundSessionTaskID = taskID.int32Value
        saveContext()
    }
}

// MARK: - Constants

extension SharedCoreDataStack {
    struct Constants {
        static let sharedModelName = "Extensions"
    }
}
