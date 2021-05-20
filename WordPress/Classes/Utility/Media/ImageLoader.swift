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
    private let loadingIndicator: CircularProgressView

    private var successHandler: ImageLoaderSuccessBlock?
    private var errorHandler: ImageLoaderFailureBlock?
    private var placeholder: UIImage?
    private var selectedPhotonQuality: UInt = Constants.defaultPhotonQuality

    private lazy var assetRequestOptions: PHImageRequestOptions = {
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .fast
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isNetworkAccessAllowed = true
        return requestOptions
    }()

    @objc init(imageView: CachedAnimatedImageView, gifStrategy: GIFStrategy = .mediumGIFs) {
        self.imageView = imageView
        imageView.gifStrategy = gifStrategy
        loadingIndicator = CircularProgressView(style: .primary)

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
        case .privateAtomicWPComSite(siteID: _):
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
        imageView.af_setImage(withURLRequest: request, completion: { [weak self] dataResponse in
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
                self.loadingIndicator.state = .error
            }

            self.errorHandler?(error)
        }
    }

    private func createError(description: String, key: String = NSLocalizedFailureReasonErrorKey) -> NSError {
        let userInfo = [key: description]
        return NSError(domain: ImageLoader.classNameWithoutNamespaces(), code: 0, userInfo: userInfo)
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
    func loadImage(media: Media, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: ImageLoaderSuccessBlock?, error: ImageLoaderFailureBlock?) {
        guard let mediaId = media.mediaID?.stringValue else {
            let error = createError(description: "The Media id doesn't exist")
            callErrorHandler(with: error)
            return
        }

        self.placeholder = placeholder
        successHandler = success
        errorHandler = error

        guard let url = url(from: media) else {
            if media.remoteStatus == .stub {
                MediaThumbnailCoordinator.shared.fetchStubMedia(for: media) { [weak self] (fetchedMedia, fetchedMediaError) in
                    if let fetchedMedia = fetchedMedia,
                        let fetchedMediaId = fetchedMedia.mediaID?.stringValue, fetchedMediaId == mediaId {
                        DispatchQueue.main.async {
                            self?.loadImage(media: fetchedMedia, preferredSize: size, placeholder: placeholder, success: success, error: error)
                        }
                    } else {
                        self?.callErrorHandler(with: fetchedMediaError)
                    }
                }
            } else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
                callErrorHandler(with: error)
            }

            return
        }

        if url.isGif {
            let host = MediaHost(with: media.blog) { error in
                // We'll log the error, so we know it's there, but we won't halt execution.
                WordPressAppDelegate.crashLogging?.logError(error)
            }

            loadGif(with: url, from: host, preferredSize: size)
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

// MARK: - Loading PHAsset object

extension ImageLoader {

    @objc(loadImageFromPHAsset:preferredSize:placeholder:success:error:)
    /// Load an image from the given PHAsset object. If it's a gif, it will animate it.
    /// For any other type of media, this will load the corresponding static image.
    ///
    /// - Parameters:
    ///   - asset: The PHAsset object
    ///   - placeholder: A placeholder to show while the image is loading.
    ///   - size: The preferred size of the image to load.
    ///   - success: A closure to be called if the image was loaded successfully.
    ///   - error: A closure to be called if there was an error loading the image.
    ///
    func loadImage(asset: PHAsset, preferredSize size: CGSize = .zero, placeholder: UIImage?, success: ImageLoaderSuccessBlock?, error: ImageLoaderFailureBlock?) {
        self.placeholder = placeholder
        successHandler = success
        errorHandler = error

        guard asset.assetType() == .image else {
            let error = self.createError(description: ErrorDescriptions.phassetIsNotImage)
            callErrorHandler(with: error)
            return
        }

        if let typeIdentifier = asset.utTypeIdentifier(), UTTypeEqual(typeIdentifier as CFString, kUTTypeGIF) {
            loadGif(from: asset)
        } else {
            loadImage(from: asset, preferredSize: size)
        }
    }

    private func loadGif(from asset: PHAsset) {
        imageView.image = placeholder
        imageView.startLoadingAnimation()

        PHImageManager.default().requestImageDataAndOrientation(for: asset,
                                                  options: assetRequestOptions,
                                                  resultHandler: { [weak self] (data, str, orientation, info) -> Void in
            guard info?[PHImageErrorKey] == nil else {
                var error: NSError?
                if let phImageError = info?[PHImageErrorKey] as? NSError {
                    let userInfo = [NSUnderlyingErrorKey: phImageError]
                    error = NSError(domain: ImageLoader.classNameWithoutNamespaces(), code: 0, userInfo: userInfo)
                } else {
                    error = self?.createError(description: ErrorDescriptions.phassetGenericError)
                }
                self?.callErrorHandler(with: error)
                return
            }

            guard let data = data else {
                let error = self?.createError(description: ErrorDescriptions.phassetReturnedDataIsEmpty)
                self?.callErrorHandler(with: error)
                return
            }

            self?.imageView.setAnimatedImage(data, success: {
                self?.callSuccessHandler()
            })
        })
    }

    private func loadImage(from asset: PHAsset, preferredSize size: CGSize) {
        imageView.image = placeholder
        imageView.startLoadingAnimation()

        var optimizedSize: CGSize = size
        if optimizedSize == .zero {
            // When using a zero size, default to the maximum screen dimension.
            let screenSize = UIScreen.main.bounds
            let screenSizeMax = max(screenSize.width, screenSize.height)
            optimizedSize = CGSize(width: screenSizeMax, height: screenSizeMax)
        }

        PHImageManager.default().requestImage(for: asset,
                                              targetSize: optimizedSize,
                                              contentMode: .aspectFill,
                                              options: assetRequestOptions) { [weak self] (image, info) in
            guard info?[PHImageErrorKey] == nil else {
                var error: NSError?
                if let phImageError = info?[PHImageErrorKey] as? NSError {
                    let userInfo = [NSUnderlyingErrorKey: phImageError]
                    error = NSError(domain: ImageLoader.classNameWithoutNamespaces(), code: 0, userInfo: userInfo)
                } else {
                    error = self?.createError(description: ErrorDescriptions.phassetGenericError)
                }
                self?.callErrorHandler(with: error)
                return
            }
            guard let image = image else {
                let error = self?.createError(description: ErrorDescriptions.phassetReturnedDataIsEmpty)
                self?.callErrorHandler(with: error)
                return
            }

            self?.imageView.image = image
            self?.callSuccessHandler()
        }
    }
}

// MARK: - Constants

private extension ImageLoader {
    enum Constants {
        static let minPhotonQuality: UInt = 1
        static let maxPhotonQuality: UInt = 100
        static let defaultPhotonQuality: UInt = 80
    }

    enum ErrorDescriptions {
        static let phassetIsNotImage: String = "Error in \(ImageLoader.classNameWithoutNamespaces()): the provided PHAsset is not an image."
        static let phassetReturnedDataIsEmpty: String = "Error in \(ImageLoader.classNameWithoutNamespaces()): no data returned for provided PHAsset."
        static let phassetGenericError: String = "Error in \(ImageLoader.classNameWithoutNamespaces()): PHAsset could not be retrieved."
    }
}
