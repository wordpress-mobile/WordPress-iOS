import Foundation

struct Gravatar {
    let canonicalURL: NSURL
}

extension Gravatar: Equatable {}

func ==(lhs: Gravatar, rhs: Gravatar) -> Bool {
    return lhs.canonicalURL == rhs.canonicalURL
}

extension Gravatar {
    init?(_ url: NSURL) {
        guard let sanitizedURL = WPImageURLHelper.gravatarURL(forURL: url) else {
            return nil
        }
        self.canonicalURL = sanitizedURL
    }
}

extension UIImageView {
    func downloadGravatar(gravatar: Gravatar?, placeholder: UIImage, animate: Bool, failure: ((NSError!) -> ())? = nil) {
        guard let gravatar = gravatar else {
            self.image = placeholder
            return
        }

        let size = Int(ceil(frame.width * contentScaleFactor))
        let url = WPImageURLHelper.gravatarURL(forURL: gravatar.canonicalURL, size: size)

        self.downloadImage(url,
            placeholderImage: placeholder,
            success: { image in
                self.image = image
                if animate {
                    self.fadeInAnimation()
                }
            }, failure: {
                error in
                failure?(error)
        })
    }
}
