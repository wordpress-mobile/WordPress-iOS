
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

    // MARK: Public Fields

    public var photonQuality: UInt {
        get {
            return selectedPhotonQuality
        }
        set(newPhotonQuality) {
            selectedPhotonQuality = min(max(newPhotonQuality, Constants.minPhotonQuality), Constants.maxPhotonQuality)
        }
    }

    // MARK: Private Fields

    private unowned let imageView: CachedAnimatedImageView
    private let loadingIndicator: CircularProgressView

    private var successHandler: (() -> Void)?
    private var errorHandler: ((Error?) -> Void)?
    private var placeholder: UIImage?
    private var selectedPhotonQuality: UInt = Constants.defaultPhotonQuality

    @objc init(imageView: CachedAnimatedImageView, gifStrategy: GIFStrategy = .mediumGIFs) {
        self.imageView = imageView
        imageView.gifStrategy = gifStrategy
        loadingIndicator = CircularProgressView(style: .wordPressBlue)

        super.init()

        WPStyleGuide.styleProgressViewWhite(loadingIndicator)
        imageView.addLoadingIndicator(loadingIndicator, style: .fullView)
    }

    /// Removes the gif animation and prevents it from animate again.
    /// Call this in a table/collection cell's `prepareForReuse()`.
    ///
    @objc func prepareForReuse() {
        imageView.prepForReuse()
    }

    @objc(loadImageWithURL:fromPost:andPreferredSize:)
    /// Load an image from a specific post, using the given URL. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - post: The post where the image is loaded from.
    ///   - size: The preferred size of the image to load.
    ///
    func loadImage(with url: URL, from source: ImageSourceInformation, preferredSize size: CGSize = .zero) {
        if url.isGif {
            loadGif(with: url, from: source, preferredSize: size)
        } else {
            imageView.clean()
            loadStaticImage(with: url, from: source, preferredSize: size)
        }
    }

    @objc(loadImageWithURL:fromPost:preferredSize:placeholder:success:error:)
    /// Load an image from a specific post, using the given URL. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - post: The post where the image is loaded from.
    ///   - size: The preferred size of the image to load. You can pass height 0 to set width and preserve aspect ratio.
    ///   - placeholder: A placeholder to show while the image is loading.
    ///   - success: A closure to be called if the image was loaded successfully.
    ///   - error: A closure to be called if there was an error loading the image.
    func loadImage(with url: URL, from source: ImageSourceInformation, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: (() -> Void)?, error: ((Error?) -> Void)?) {

        self.placeholder = placeholder
        successHandler = success
        errorHandler = error

        loadImage(with: url, from: source, preferredSize: size)
    }

    // MARK: - Private helpers

    /// Load an animated image from the given URL.
    ///
    private func loadGif(with url: URL, from source: ImageSourceInformation, preferredSize size: CGSize) {
        let request: URLRequest
        if url.isFileURL {
            request = URLRequest(url: url)
        } else if source.isPrivateOnWPCom {
            request = PrivateSiteURLProtocol.requestForPrivateSite(from: url)
        } else {
            // Photon helper set the size to load the retina version. We don't want that for gifs
            let scale = UIScreen.main.scale
            let nonRetinaSize = CGSize(width: size.width / scale, height: size.height / scale)
            if let photonUrl = getPhotonUrl(for: url, size: nonRetinaSize) {
                request = URLRequest(url: photonUrl)
            } else {
                request = URLRequest(url: url)
            }
        }
        downloadGif(from: request)
    }

    /// Load a static image from the given URL.
    ///
    private func loadStaticImage(with url: URL, from source: ImageSourceInformation, preferredSize size: CGSize) {
        if url.isFileURL {
            downloadImage(from: url)
        } else if source.isPrivateOnWPCom {
            loadPrivateImage(with: url, from: source, preferredSize: size)
        } else if source.isSelfHostedWithCredentials {
            downloadImage(from: url)
        } else {
            loadPhotonUrl(with: url, preferredSize: size)
        }
    }

    /// Loads the image from a private post hosted in WPCom.
    ///
    private func loadPrivateImage(with url: URL, from source: ImageSourceInformation, preferredSize size: CGSize) {
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let scaledURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)
        let request = PrivateSiteURLProtocol.requestForPrivateSite(from: scaledURL)

        downloadImage(from: request)
    }

    /// Loads the image from the Photon API with the given size.
    ///
    private func loadPhotonUrl(with url: URL, preferredSize size: CGSize) {
        guard let photonURL = getPhotonUrl(for: url, size: size) else {
            downloadImage(from: url)
            return
        }

        downloadImage(from: photonURL)
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
            if self.imageView.shouldShowLoadingIndicator {
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
    ///   - size: The preferred size of the image to load.
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
            loadGif(with: url, from: media.blog, preferredSize: size)
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

    private func getPhotonUrl(for url: URL, size: CGSize) -> URL? {
        return PhotonImageURLHelper.photonURL(with: size,
                                              forImageURL: url,
                                              forceResize: true,
                                              imageQuality: selectedPhotonQuality)
    }
}

// MARK: - Constants

private extension ImageLoader {
    enum Constants {
        static let minPhotonQuality: UInt = 1
        static let maxPhotonQuality: UInt = 100
        static let defaultPhotonQuality: UInt = 80
    }
}
