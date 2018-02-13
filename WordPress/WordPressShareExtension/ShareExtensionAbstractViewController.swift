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

    // MARK: - Public Properties

    /// Identifies which app extension launched this VC
    ///
    var originatingExtension: OriginatingExtension = .share

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

    func cleanUpSharedContainer() {
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
