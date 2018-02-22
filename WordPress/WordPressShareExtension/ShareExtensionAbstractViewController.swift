import CoreData
import UIKit
import WordPressKit

enum OriginatingExtension: String {
    case share
    case saveToDraft
}

/// A base class for the various Share Extension view controllers.
/// It is assumed that Share Extension controllers will always be presented modally.
///
class ShareExtensionAbstractViewController: UIViewController, ShareSegueHandler {

    enum SegueIdentifier: String {
        case showModularSitePicker
    }

    typealias CompletionBlock = () -> Void

    // MARK: - Cache

    internal static let cache = NSCache<AnyObject, AnyObject>()
    static func clearCache() {
        cache.removeAllObjects()
    }
    internal static func storeCategories(_ categories: [RemotePostCategory], for siteID: NSNumber) {
        cache.setObject(categories as AnyObject, forKey: "\(siteID)-categories" as AnyObject)
    }
    internal static func cachedCategoriesForSite(_ siteID: NSNumber) -> [RemotePostCategory]? {
        return cache.object(forKey: "\(siteID)-categories" as AnyObject) as? [RemotePostCategory]
    }
    internal static func storeDefaultCategoryID(_ defaultCategoryID: NSNumber, for siteID: NSNumber) {
        cache.setObject(defaultCategoryID as AnyObject, forKey: "\(siteID)-default-category" as AnyObject)
    }
    internal static func cachedDefaultCategoryIDForSite(_ siteID: NSNumber) -> NSNumber? {
        return cache.object(forKey: "\(siteID)-default-category" as AnyObject) as? NSNumber
    }

    // MARK: - Public Properties

    /// Identifies which app extension launched this VC
    ///
    var originatingExtension: OriginatingExtension = .share {
        didSet {
            if originatingExtension == .share {
                shareData.postStatus = .publish
            } else {
                shareData.postStatus = .draft
            }
        }
    }

    /// This completion handler closure is executed when this VC is dismissed
    ///
    @objc var dismissalCompletionBlock: CompletionBlock?

    /// The extension context data provided from the host app
    ///
    open var context: NSExtensionContext?

    // MARK: - Internal Properties

    /// Stateful data related to this share session.
    ///
    internal var shareData = ShareData()

    /// All possible sites for this account
    ///
    internal var sites: [RemoteBlog]?
    internal var hasSites: Bool {
        get {
            return sites != nil && sites?.isEmpty == false
        }
    }

    /// WordPress.com Username
    ///
    internal lazy var wpcomUsername: String? = {
        ShareExtensionService.retrieveShareExtensionUsername()
    }()

    /// Primary Site's ID
    ///
    internal lazy var primarySiteID: Int? = {
        ShareExtensionService.retrieveShareExtensionPrimarySite()?.siteID
    }()

    /// Primary Site's Name
    ///
    internal lazy var primarySiteName: String? = {
        ShareExtensionService.retrieveShareExtensionPrimarySite()?.siteName
    }()

    /// Maximum Image Size
    ///
    internal lazy var maximumImageSize: CGSize = {
        let dimension = ShareExtensionService.retrieveShareExtensionMaximumMediaDimension() ?? Constants.defaultMaxDimension
        return CGSize(width: dimension, height: dimension)
    }()

    /// WordPress.com OAuth Token
    ///
    internal lazy var oauth2Token: String? = {
        ShareExtensionService.retrieveShareExtensionToken()
    }()

    /// Tracks Instance
    ///
    internal lazy var tracks: Tracks = {
        Tracks(appGroupName: WPAppGroupName)
    }()

    // MARK: - Lifecycle Methods

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tracker
        tracks.wpcomUsername = wpcomUsername
    }
}

// MARK: - Misc Helpers

extension ShareExtensionAbstractViewController {
    func verifyAuthCredentials(onSuccess: (() -> Void)?) {
        guard oauth2Token == nil else {
            onSuccess?()
            return
        }

        let title = NSLocalizedString("Sharing error", comment: "Share extension dialog title - displayed when user is missing a login token.")
        let message = NSLocalizedString("Please launch the WordPress app, log in to WordPress.com and make sure you have at least one site, then try again.", comment: "Share extension dialog text  - displayed when user is missing a login token.")
        let accept = NSLocalizedString("Cancel sharing", comment: "Share extension dialog dismiss button label - displayed when user is missing a login token.")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: accept, style: .default) { (action) in
            self.cleanUpSharedContainerAndCache()
            self.dismiss(animated: true, completion: self.dismissalCompletionBlock)
        }

        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }

    func saveImageToSharedContainer(_ image: UIImage) -> URL? {
        guard let encodedMedia = image.resizeWithMaximumSize(maximumImageSize).JPEGEncoded(),
            let mediaDirectory = ShareMediaFileManager.shared.mediaUploadDirectoryURL else {
                return nil
        }

        let uniqueString = "image_\(NSDate.timeIntervalSinceReferenceDate)"
        let fileName = uniqueString.components(separatedBy: ["."]).joined() + ".jpg"
        let fullPath = mediaDirectory.appendingPathComponent(fileName)
        do {
            try encodedMedia.write(to: fullPath, options: [.atomic])
        } catch {
            DDLogError("Error saving \(fullPath) to shared container: \(String(describing: error))")
            return nil
        }
        return fullPath
    }

    func cleanUpSharedContainerAndCache() {
        ShareExtensionAbstractViewController.clearCache()

        // Remove the temp media files if needed
        for tempMediaFileURL in shareData.sharedImageDict.keys {
            if !tempMediaFileURL.pathExtension.isEmpty {
                ShareMediaFileManager.shared.removeFromUploadDirectory(fileName: tempMediaFileURL.lastPathComponent)
            }
        }
    }

    func createErrorWithDescription(_ description: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: "ShareExtensionAbstractViewController", code: 0, userInfo: userInfo)
    }
}

// MARK: - Constants

extension ShareExtensionAbstractViewController {
    struct Constants {
        static let defaultMaxDimension = 3000
        static let fullAlpha: CGFloat = 1.0
        static let zeroAlpha: CGFloat = 0.0
    }
}
