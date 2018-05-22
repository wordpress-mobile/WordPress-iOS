
/// Protocol used to abstract the information needed to load post related images.
///
@objc protocol ImageSourceInformation {

    /// The post is private and hosted on WPcom.
    /// Redundant name due to naming conflict.
    ///
    var isPrivateOnWPCom: Bool { get }

    /// The blog is self-hosted and there is already a basic auth credential stored.
    ///
    var isSelfHostedWithCredentials: Bool { get }
}

/// Class used together with `CachedAnimatedImageView` to facilitate the loading of both
/// still images and animated gifs.
///
@objc class ImageLoader: NSObject {

    private unowned let imageView: CachedAnimatedImageView
    private let loadingIndicator: MediaCellProgressView

    private var successHandler: (() -> Void)?
    private var errorHandler: ((Error?) -> Void)?
    private var placeholder: UIImage?

    @objc init(imageView: CachedAnimatedImageView, gifStrategy: GIFStrategy = .mediumGIFs) {
        self.imageView = imageView
        imageView.gifStrategy = gifStrategy
        loadingIndicator = MediaCellProgressView()

        super.init()

        WPStyleGuide.styleProgressViewWhite(loadingIndicator)
        WPStyleGuide.addErrorView(to: loadingIndicator)
        imageView.addLoadingIndicator(loadingIndicator, style: .fullView)
    }

    /// Removes the gif animation and prevents it from animate again.
    /// Call this in a table/collection cell's `prepareForReuse()`.
    ///
    @objc func prepareForReuse() {
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
    func loadImage(with url: URL, from source: ImageSourceInformation, preferedSize size: CGSize = .zero) {
        if url.isGif {
            loadGif(with: url, from: source)
        } else {
            imageView.clean()
            loadStaticImage(with: url, from: source, preferedSize: size)
        }
    }

    @objc(loadImageWithURL:fromPost:preferedSize:placeholder:success:error:)
    /// Load an image from a specific post, using the given URL. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - post: The post where the image is loaded from.
    ///   - size: The prefered size of the image to load.
    ///   - placeholder: A placeholder to show while the image is loading.
    ///   - success: A closure to be called if the image was loaded successfully.
    ///   - error: A closure to be called if there was an error loading the image.
    func loadImage(with url: URL, from source: ImageSourceInformation, preferedSize size: CGSize = .zero, placeholder: UIImage?, success: (() -> Void)?, error: ((Error?) -> Void)?) {

        self.placeholder = placeholder
        successHandler = success
        errorHandler = error

        loadImage(with: url, from: source, preferedSize: size)
    }

    // MARK: - Private helpers

    /// Load an animated image from the given URL.
    ///
    private func loadGif(with url: URL, from source: ImageSourceInformation) {
        let request: URLRequest
        if source.isPrivateOnWPCom {
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: url)
        } else {
            request = URLRequest(url: url)
        }
        downloadGif(from: request)
    }

    /// Load a static image from the given URL.
    ///
    private func loadStaticImage(with url: URL, from source: ImageSourceInformation, preferedSize size: CGSize) {
        if url.isFileURL {
            downloadImage(from: url)
        } else if source.isPrivateOnWPCom {
            loadPrivateImage(with: url, from: source, preferedSize: size)
        } else if source.isSelfHostedWithCredentials {
            downloadImage(from: url)
        } else {
            loadProtonUrl(with: url, preferedSize: size)
        }
    }

    /// Loads the image from a private post hosted in WPCom.
    ///
    private func loadPrivateImage(with url: URL, from source: ImageSourceInformation, preferedSize size: CGSize) {
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let scaledURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
        let request = PrivateSiteURLProtocol.requestForPrivateSite(from: scaledURL)

        downloadImage(from: request)
    }

    /// Loads the image from the Proton API with the given size.
    ///
    private func loadProtonUrl(with url: URL, preferedSize size: CGSize) {
        guard let protonURL = PhotonImageURLHelper.photonURL(with: size, forImageURL: url) else {
            downloadImage(from: url)
            return
        }
        downloadImage(from: protonURL)
    }

    /// Download the animated image from the given URL Request.
    ///
    private func downloadGif(from request: URLRequest) {
        imageView.startLoadingAnimation()
        imageView.setAnimatedImage(request, placeholderImage: placeholder, success: { [weak self] in
            self?.callSuccessHandler()
        }) { [weak self] (error) in
            self?.callErrorHandler(with: error)
        }
    }

    /// Downloads the image from the given URL Request.
    ///
    private func downloadImage(from request: URLRequest) {
        imageView.startLoadingAnimation()
        imageView.setImageWith(request, placeholderImage: placeholder, success: { [weak self] (_, _, image) in
            // Since a success block is specified, we need to set the image manually.
            self?.imageView.image = image
            self?.callSuccessHandler()
        }) { [weak self] (_, _, error) in
            self?.callErrorHandler(with: error)
        }
    }

    /// Downloads the image from the given URL.
    ///
    private func downloadImage(from url: URL) {
        imageView.startLoadingAnimation()
        imageView.downloadImage(from: url, placeholderImage: placeholder, success: { [weak self] (_) in
            self?.callSuccessHandler()
        }) { [weak self] (error) in
            self?.callErrorHandler(with: error)
        }
    }

    private func callSuccessHandler() {
        imageView.stopLoadingAnimation()
        guard successHandler != nil else {
            return
        }
        DispatchQueue.main.async {
            self.successHandler?()
        }
    }

    private func callErrorHandler(with error: Error?) {
        guard let error = error, (error as NSError).code != NSURLErrorCancelled else {
            return
        }
        DispatchQueue.main.async {
            if self.imageView.disableLoadingIndicator == false {
                self.loadingIndicator.state = .error
            }
            self.errorHandler?(error)
        }
    }
}

// MARK: - Loading Media object

extension ImageLoader {

    @objc(loadImageFromMedia:preferredSize:placeholder:success:error:)
    /// Load an image from the given Media object. If it's a gif, it will animate it.
    /// For any other type of media, this will load the corresponding static image.
    ///
    /// - Parameters:
    ///   - media: The media object
    ///   - placeholder: A placeholder to show while the image is loading.
    ///   - size: The prefered size of the image to load.
    ///   - success: A closure to be called if the image was loaded successfully.
    ///   - error: A closure to be called if there was an error loading the image.
    ///
    func loadImage(media: Media, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: (() -> Void)?, error: ((Error?) -> Void)?) {

        self.placeholder = placeholder
        successHandler = success
        errorHandler = error

        guard let url = url(from: media) else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
            callErrorHandler(with: error)
            return
        }

        if url.isGif {
            loadGif(with: url, from: media.blog)
        } else if imageView.image == nil {
            imageView.clean()
            loadImage(from: media, preferredSize: size)
        }
    }

    private func loadImage(from media: Media, preferredSize size: CGSize) {
        imageView.image = placeholder
        imageView.startLoadingAnimation()
        media.image(with: size) {  [weak self] (image, error) in
            if let image = image {
                self?.imageView.image = image
                self?.callSuccessHandler()
            } else {
                self?.callErrorHandler(with: error)
            }
        }
    }

    private func url(from media: Media) -> URL? {
        if let localUrl = media.absoluteLocalURL {
            return localUrl
        } else if let urlString = media.remoteURL, let remoteUrl = URL(string: urlString) {
            return remoteUrl
        }
        return nil
    }
}
