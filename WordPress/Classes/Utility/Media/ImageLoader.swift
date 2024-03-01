import MobileCoreServices
import AlamofireImage
import AutomatticTracks

/// Class used together with `CachedAnimatedImageView` to facilitate the loading of both
/// still images and animated gifs.
///
@objc class ImageLoader: NSObject {
    typealias ImageLoaderSuccessBlock = () -> Void
    typealias ImageLoaderFailureBlock = (Error?) -> Void

    // MARK: Public Fields

    public var photonQuality: UInt {
        get {
            return selectedPhotonQuality
        }
        set(newPhotonQuality) {
            selectedPhotonQuality = min(max(newPhotonQuality, Constants.minPhotonQuality), Constants.maxPhotonQuality)
        }
    }

    // MARK: - Image Dimensions Support
    typealias ImageLoaderDimensionsBlock = (ImageDimensionFormat, CGSize) -> Void

    /// Called if the imageLoader is able to determine the image format, and dimensions
    /// for the image prior to it being downloaded.
    /// Note: Set the property prior to calling any load method
    public var imageDimensionsHandler: ImageLoaderDimensionsBlock?
    private var imageDimensionsFetcher: ImageDimensionsFetcher? = nil

    // MARK: Private Fields

    private unowned let imageView: CachedAnimatedImageView
    private let loadingIndicator: ActivityIndicatorType

    private var successHandler: ImageLoaderSuccessBlock?
    private var errorHandler: ImageLoaderFailureBlock?
    private var placeholder: UIImage?
    private var selectedPhotonQuality: UInt = Constants.defaultPhotonQuality

    @objc convenience init(imageView: CachedAnimatedImageView, gifStrategy: GIFStrategy = .mediumGIFs) {
        self.init(imageView: imageView, gifStrategy: gifStrategy, loadingIndicator: nil)
    }

    init(imageView: CachedAnimatedImageView, gifStrategy: GIFStrategy = .mediumGIFs, loadingIndicator: ActivityIndicatorType?) {
        self.imageView = imageView
        imageView.gifStrategy = gifStrategy

        if let loadingIndicator {
            self.loadingIndicator = loadingIndicator
        } else {
            let loadingIndicator = CircularProgressView(style: .primary)
            loadingIndicator.backgroundColor = .clear
            self.loadingIndicator = loadingIndicator
        }

        super.init()

        imageView.addLoadingIndicator(self.loadingIndicator, style: .fullView)
    }

    /// Removes the gif animation and prevents it from animate again.
    /// Call this in a table/collection cell's `prepareForReuse()`.
    ///
    @objc func prepareForReuse() {
        imageView.prepForReuse()
    }

    /// Load an image from a specific post, using the given URL. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - host: The `MediaHost` of the image.
    ///   - size: The preferred size of the image to load.
    ///
    func loadImage(with url: URL, from host: MediaHost, preferredSize size: CGSize = .zero) {
        if url.isFileURL {
            downloadImage(from: url)
        } else if url.isGif {
            loadGif(with: url, from: host, preferredSize: size)
        } else {
            imageView.clean()
            loadStaticImage(with: url, from: host, preferredSize: size)
        }
    }

    /// Load an image from a specific URL. As no source is provided, we can assume
    /// that this is from a public site. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - success: A closure to be called if the image was loaded successfully.
    ///   - error: A closure to be called if there was an error loading the image.
    ///
    func loadImage(with url: URL, success: ImageLoaderSuccessBlock?, error: ImageLoaderFailureBlock?) {
        successHandler = success
        errorHandler = error

        if url.isGif {
            loadGif(with: url, from: .publicSite)
        } else {
            imageView.clean()
            loadStaticImage(with: url, from: .publicSite)
        }
    }

    @objc(loadImageWithURL:fromPost:preferredSize:placeholder:success:error:)
    func loadImage(with url: URL, from post: AbstractPost, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: ImageLoaderSuccessBlock?, error: ImageLoaderFailureBlock?) {

        let host = MediaHost(with: post, failure: { error in
            WordPressAppDelegate.crashLogging?.logError(error)
        })

        loadImage(with: url, from: host, preferredSize: size, placeholder: placeholder, success: success, error: error)
    }

    @objc(loadImageWithURL:fromReaderPost:preferredSize:placeholder:success:error:)
    func loadImage(with url: URL, from readerPost: ReaderPost, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: ImageLoaderSuccessBlock?, error: ImageLoaderFailureBlock?) {

        let host = MediaHost(with: readerPost, failure: { error in
            WordPressAppDelegate.crashLogging?.logError(error)
        })

        loadImage(with: url, from: host, preferredSize: size, placeholder: placeholder, success: success, error: error)
    }

    /// Load an image from a specific post, using the given URL. Supports animated images (gifs) as well.
    ///
    /// - Parameters:
    ///   - url: The URL to load the image from.
    ///   - host: The host of the image.
    ///   - size: The preferred size of the image to load. You can pass height 0 to set width and preserve aspect ratio.
    ///   - placeholder: A placeholder to show while the image is loading.
    ///   - success: A closure to be called if the image was loaded successfully.
    ///   - error: A closure to be called if there was an error loading the image.
    func loadImage(with url: URL, from host: MediaHost, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: ImageLoaderSuccessBlock?, error: ImageLoaderFailureBlock?) {

        self.placeholder = placeholder
        successHandler = success
        errorHandler = error

        loadImage(with: url, from: host, preferredSize: size)
    }

    // MARK: - Private helpers

    /// Load an animated image from the given URL.
    ///
    private func loadGif(with url: URL, from host: MediaHost, preferredSize size: CGSize = .zero) {
        let mediaAuthenticator = MediaRequestAuthenticator()
        mediaAuthenticator.authenticatedRequest(
            for: url,
            from: host,
            onComplete: { request in
                self.downloadGif(from: request)
        },
            onFailure: { error in
                WordPressAppDelegate.crashLogging?.logError(error)
                self.callErrorHandler(with: error)
        })
    }

    /// Load a static image from the given URL.
    ///
    private func loadStaticImage(with url: URL, from host: MediaHost, preferredSize size: CGSize = .zero) {
        let finalURL: URL

        switch host {
        case .publicSite: fallthrough
        case .privateSelfHostedSite:
            finalURL = url
        case .publicWPComSite: fallthrough
        case .privateAtomicWPComSite:
            finalURL = photonUrl(with: url, preferredSize: size)
        case .privateWPComSite:
            finalURL = privateImageURL(with: url, from: host, preferredSize: size)
        }

        let mediaRequestAuthenticator = MediaRequestAuthenticator()

        mediaRequestAuthenticator.authenticatedRequest(for: finalURL, from: host, onComplete: { request in
            self.downloadImage(from: request)
        }) { error in
            WordPressAppDelegate.crashLogging?.logError(error)
            self.callErrorHandler(with: error)
        }
    }

    /// Constructs the URL for an image from a private post hosted in WPCom.
    ///
    private func privateImageURL(with url: URL, from host: MediaHost, preferredSize size: CGSize) -> URL {
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let scaledURL = WPImageURLHelper.imageURLWithSize(scaledSize, forImageURL: url)

        return scaledURL
    }

    /// Gets the photon URL with the specified size, or returns the passed `URL`
    ///
    private func photonUrl(with url: URL, preferredSize size: CGSize) -> URL {
        guard let photonURL = getPhotonUrl(for: url, size: size) else {
            return url
        }

        return photonURL
    }

    /// Triggers the image dimensions fetcher if the `imageDimensionsHandler` property is set
    private func calculateImageDimensionsIfNeeded(from request: URLRequest) {
        guard let imageDimensionsHandler = imageDimensionsHandler else {
            return
        }

        let fetcher = ImageDimensionsFetcher(request: request, success: { (format, size) in
            guard let size = size, size != .zero else {
                return
            }

            DispatchQueue.main.async {
                imageDimensionsHandler(format, size)
            }
        })

        fetcher.start()

        imageDimensionsFetcher = fetcher
    }

    /// Stop the image dimension calculation
    private func cancelImageDimensionCalculation() {
        imageDimensionsFetcher?.cancel()
        imageDimensionsFetcher = nil
    }

    /// Download the animated image from the given URL Request.
    ///
    private func downloadGif(from request: URLRequest) {
        calculateImageDimensionsIfNeeded(from: request)

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
        calculateImageDimensionsIfNeeded(from: request)

        imageView.startLoadingAnimation()
        imageView.af.setImage(withURLRequest: request, completion: { [weak self] dataResponse in
            guard let self = self else {
                return
            }

            switch dataResponse.result {
            case .success:
                self.callSuccessHandler()
            case .failure(let error):
                self.callErrorHandler(with: error)
            }
        })
    }

    /// Downloads the image from the given URL.
    ///
    private func downloadImage(from url: URL) {
        let request = URLRequest(url: url)
        downloadImage(from: request)
    }

    private func callSuccessHandler() {
        cancelImageDimensionCalculation()

        imageView.stopLoadingAnimation()
        guard successHandler != nil else {
            return
        }
        DispatchQueue.main.async {
            self.successHandler?()
        }
    }

    private func callErrorHandler(with error: Error?) {
        if let error = error, (error as NSError).code == NSURLErrorCancelled {
            return
        }

        cancelImageDimensionCalculation()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            if self.imageView.shouldShowLoadingIndicator {
                (self.loadingIndicator as? CircularProgressView)?.state = .error
            }

            self.errorHandler?(error)
        }
    }
}

// MARK: - Loading Media object

extension ImageLoader {
    private func getPhotonUrl(for url: URL, size: CGSize) -> URL? {
        var finalSize = size
        if url.isGif {
            // Photon helper sets the size to load the retina version. We don't want that for gifs
            let scale = UIScreen.main.scale
            finalSize = CGSize(width: size.width / scale, height: size.height / scale)
        }
        return PhotonImageURLHelper.photonURL(with: finalSize,
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
