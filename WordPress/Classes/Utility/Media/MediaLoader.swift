
@objc protocol PostInformation {
    var isPrivateSite: Bool { get }
    var isBlogSelfHostedWithCredentials: Bool { get }
}

extension AbstractPost: PostInformation {
    var isPrivateSite: Bool {
        return isPrivate() && blog.isHostedAtWPcom
    }

    var isBlogSelfHostedWithCredentials: Bool {
        return !blog.isHostedAtWPcom && blog.isBasicAuthCredentialStored()
    }
}

extension URL {
    var isGif: Bool {
        return pathExtension == "gif"
    }
}

@objc class MediaLoader: NSObject {

    private let imageView: CachedAnimatedImageView

    @objc init(imageView: CachedAnimatedImageView) {
        self.imageView = imageView
        super.init()
    }

    @objc func prepareForReuse() {
        imageView.image = nil
        imageView.prepForReuse()
    }

    @objc(loadImageWithURL:fromPost:andPreferedSize:)
    func loadImage(with url: URL, from post: PostInformation, preferedSize size: CGSize = .zero) {
        if url.isGif {
            loadGif(with: url, from: post)
        } else {
            loadStillImage(with: url, from: post, preferedSize: size)
        }
    }

    // MARK: - Private helpers

    private func loadGif(with url: URL, from post: PostInformation) {
        let request: URLRequest
        if post.isPrivateSite {
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: url)
        } else {
            request = URLRequest(url: url)
        }

        imageView.setAnimatedImage(request, placeholderImage: nil, success: nil, failure: nil)
    }

    private func loadStillImage(with url: URL, from post: PostInformation, preferedSize size: CGSize) {
        if url.isFileURL {
            imageView.setImageWith(url)
        } else if post.isPrivateSite {
            loadImage(with: url, fromPrivatePost: post, preferedSize: size)
        } else if post.isBlogSelfHostedWithCredentials {
            imageView.setImageWith(url)
        } else {
            loadProtonUrl(with: url, preferedSize: size)
        }
    }

    private func loadImage(with url: URL, fromPrivatePost post: PostInformation, preferedSize size: CGSize) {
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let scaledURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
        imageView.setImageWith(scaledURL)
    }

    private func loadProtonUrl(with url: URL, preferedSize size: CGSize) {
        guard let protonURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: url) else {
            imageView.setImageWith(url)
            return
        }
        imageView.setImageWith(protonURL)
    }
}
