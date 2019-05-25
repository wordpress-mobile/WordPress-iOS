import Foundation

/// Takes care of coordinating all Uploaders used by the app.
@objc
class UploadsManager: NSObject {
    private let uploaders: [Uploader]

    init(uploaders: [Uploader]) {
        self.uploaders = uploaders
    }

    func resume() {
        for uploader in uploaders {
            uploader.resume()
        }
    }
}
