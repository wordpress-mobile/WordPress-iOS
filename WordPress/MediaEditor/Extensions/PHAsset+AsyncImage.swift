/**
This is an extension to allow PHAsset in Media Editor.
*/
extension PHAsset: AsyncImage {
    /**
     PHAsset doesn't provide a thumbnail right away.
     It will be requested in the thumbnail() method
    */
    public var thumb: UIImage? {
        return nil
    }

    /**
     Keep track of all ongoing image requests so they can be cancelled.
    */
    public var requests: [PHImageRequestID] {
        get {
            return objc_getAssociatedObject(self, &Keys.requests) as? [PHImageRequestID] ?? []
        }
        set {
            objc_setAssociatedObject(self, &Keys.requests, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /**
     Fetch a thumbnail and then display a better quality one.
    */
    public func thumbnail(finishedRetrievingThumbnail: @escaping (UIImage?) -> ()) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.version = .current
        options.resizeMode = .fast
        let requestID = PHImageManager.default().requestImage(for: self, targetSize: self.pixelSize(), contentMode: .default, options: options) { image, info in
            guard let image = image else {
                finishedRetrievingThumbnail(nil)
                return
            }

            finishedRetrievingThumbnail(image)
        }
        requests.append(requestID)
    }

    /**
     Fetch the full quality image.
    */
    public func full(finishedRetrievingFullImage: @escaping (UIImage?) -> ()) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.version = .current
        let requestID = PHImageManager.default().requestImage(for: self, targetSize: self.pixelSize(), contentMode: .default, options: options) { image, info in
            guard let image = image else {
                finishedRetrievingFullImage(nil)
                return
            }

            finishedRetrievingFullImage(image)
        }
        requests.append(requestID)
    }

    /**
     Cancel all ongoing requests
    */
    public func cancel() {
        requests.forEach { PHImageManager.default().cancelImageRequest($0) }
    }

    private enum Keys {
        static var requests = "requests"
    }
}
