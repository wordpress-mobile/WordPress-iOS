
/// Protocol used to abstract the information needed to load post related images
///
@objc protocol PostInformation {

    /// The post is private and hosted on WPcom.
    /// Redundant name due to naming conflict.
    ///
    var isPrivateOnWPCom: Bool { get }

    /// The blog is self-hosted and there is already a basic auth credential stored.
    ///
    var isBlogSelfHostedWithCredentials: Bool { get }
}

/// Class used together with `CachedAnimatedImageView` to facilitate the loading of both
/// still images and animated gifs.
///
@objc class ImageLoader: NSObject {

    private let imageView: CachedAnimatedImageView

    @objc init(imageView: CachedAnimatedImageView) {
        self.imageView = imageView
        super.init()
    }

    /// Call this in a table/collection cell's `prepareForReuse()`
    ///
    @objc func prepareForReuse() {
        imageView.image = nil
        imageView.prepForReuse()
    }

    @objc(loadImageWithURL:fromPost:andPreferedSize:)
    /// Load an image from a specific post, using the given URL. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - post: The post where the image is loaded from.
    ///   - size: The prefered size of the image to load.
    ///
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
        if post.isPrivateOnWPCom {
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: url)
        } else {
            request = URLRequest(url: url)
        }

        imageView.setAnimatedImage(request, placeholderImage: nil, success: nil, failure: nil)
    }

    private func loadStillImage(with url: URL, from post: PostInformation, preferedSize size: CGSize) {
        if url.isFileURL {
            imageView.downloadImage(from: url)
        } else if post.isPrivateOnWPCom {
            loadImage(with: url, fromPrivatePost: post, preferedSize: size)
        } else if post.isBlogSelfHostedWithCredentials {
            imageView.downloadImage(from: url)
        } else {
            loadProtonUrl(with: url, preferedSize: size)
        }
    }

    private func loadImage(with url: URL, fromPrivatePost post: PostInformation, preferedSize size: CGSize) {
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let scaledURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
        let request = PrivateSiteURLProtocol.requestForPrivateSite(from: scaledURL)
        imageView.setImageWith(request, placeholderImage: nil, success: nil, failure: nil)
    }

    private func loadProtonUrl(with url: URL, preferedSize size: CGSize) {
        guard let protonURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: url) else {
            imageView.downloadImage(from: url)
            return
        }
        imageView.downloadImage(from: protonURL)
    }
}
