import Foundation

/// Takes care of coordinating all uploaders used by the app.
///
class UploadsManager: NSObject {
    private let uploaders: [Uploader]

    /// The reason why this property is lazy is that it's basically a closure with a self reference.
    /// There's no easy way to initialize these, other than making them lazy (2019-06-01)
    ///
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

        /// This just makes sure the reachabilityObserver property is initialized here.
        _ = reachabilityObserver
    }

    deinit {
        NotificationCenter.default.removeObserver(reachabilityObserver)
    }

    // MARK: Interacting with Uploads

    /// Resumes all uploads handled by the uploaders.
    ///
    func resume() {
        for uploader in uploaders {
            uploader.resume()
        }
    }
}
