import Foundation

struct Gravatar {
    fileprivate struct Defaults {
        static let scheme = "https"
        static let host = "secure.gravatar.com"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    let canonicalURL: URL

    func urlWithSize(_ size: Int) -> URL {
        var components = URLComponents(url: canonicalURL, resolvingAgainstBaseURL: false)!
        components.query = "s=\(size)&d=404"
        return components.url!
    }

    static func isGravatarURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let host = components.host, host.hasSuffix(".gravatar.com") else {
                return false
        }

        guard url.path.hasPrefix("/avatar/") else {
                return false
        }

        return true
    }
}

extension Gravatar: Equatable {}

func ==(lhs: Gravatar, rhs: Gravatar) -> Bool {
    return lhs.canonicalURL == rhs.canonicalURL
}

extension Gravatar {
    init?(_ url: URL) {
        guard Gravatar.isGravatarURL(url) else {
            return nil
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.scheme = Defaults.scheme
        components.host = Defaults.host
        components.query = nil

        // Treat unknown@gravatar.com as a nil url
        guard url.lastPathComponent != Defaults.unknownHash else {
                return nil
        }

        guard let sanitizedURL = components.url else {
            return nil
        }

        self.canonicalURL = sanitizedURL
    }
}

extension UIImageView {
    func downloadGravatar(_ gravatar: Gravatar?, placeholder: UIImage, animate: Bool, failure: ((Error?) -> ())? = nil) {
        guard let gravatar = gravatar else {
            self.image = placeholder
            return
        }

        // Starting with iOS 10, it seems `initWithCoder` uses a default size
        // of 1000x1000, which was messing with our size calculations for gravatars
        // on newly created table cells.
        // Calling `layoutIfNeeded()` forces UIKit to calculate the actual size.
        layoutIfNeeded()

        let size = Int(ceil(frame.width * UIScreen.main.scale))
        let url = gravatar.urlWithSize(size)

        self.downloadImage(url,
            placeholderImage: placeholder,
            success: { image in
                guard image != self.image else {
                    return
                }

                self.image = image
                if animate {
                    self.fadeInAnimation()
                }
            }, failure: { error in
                failure?(error)
        })
    }
}
