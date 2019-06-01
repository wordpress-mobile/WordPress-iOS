import Foundation

/// Takes care of coordinating all uploaders used by the app.
///
@objc
class UploadsManager: NSObject {
    private let uploaders: [Uploader]
    private lazy var reachabilityObserver: NSObjectProtocol = {
        return NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: nil, queue: nil) { [weak self] notification in

            guard let self = self else {
                return
            }

            let internetIsReachable = notification.userInfo?[Foundation.Notification.reachabilityKey] as? Bool ?? false

            if internetIsReachable {
                self.resume()
            }
        }
    }()

    // MARK: Initialization & Finalization

    /// Default initializer.
    ///
    /// - Parameters:
    ///     - uploaders: the uploaders that this object will be handling.
    ///
    required init(uploaders: [Uploader]) {
        self.uploaders = uploaders

        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(reachabilityObserver)
    }

    // MARK: Interacting with Uploads

    /// Resumes all uploads handled by the uploaders.
    ///
    @objc
    func resume() {
        for uploader in uploaders {
            uploader.resume()
        }
    }
}
