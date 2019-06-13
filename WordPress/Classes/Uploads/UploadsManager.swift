import Foundation
import Reachability

/// Takes care of coordinating all uploaders used by the app.
///
class UploadsManager: NSObject {
    private let uploaders: [Uploader]
    private let reachability: Reachability = Reachability.forInternetConnection()

    // MARK: Initialization & Finalization

    /// Default initializer.
    ///
    /// - Parameters:
    ///     - uploaders: the uploaders that this object will be handling.
    ///
    required init(uploaders: [Uploader]) {
        self.uploaders = uploaders

        super.init()

        setupReachableBlock()
    }

    // MARK: Reachability

    private func setupReachableBlock() {
        reachability.reachableBlock = { [weak self] _ in
            self?.resume()
        }

        reachability.startNotifier()
    }

    // MARK: Interacting with Uploads

    /// Resumes all uploads handled by the uploaders.
    ///
    func resume() {
        uploaders.forEach { $0.resume() }
    }
}
