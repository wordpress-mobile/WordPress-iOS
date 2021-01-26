//
// Previously, we were using FLAnimatedImage to show gifs. (https://github.com/Flipboard/FLAnimatedImage)
// It's a good, battle-tested component written in Obj-c with a good solution for memory usage on big files.
// We decided to look for other alternatives and we got to Gifu. (https://github.com/kaishin/Gifu)
// - It has a similar approach to be memory efficient. Tests showed that is more memory efficient than FLAnimatedImage.
// - It's written in Swift, in a protocol oriented approach. That make it easier to implement it in a Swift code base.
// - It has extra features, like stopping and plying gifs, and a special `prepareForReuse` for table/collection views.
// - It seems to be more active, being updated few months ago, in contrast to a couple of years ago of FLAnimatedImage

import Foundation
import Gifu

@objc public protocol ActivityIndicatorType where Self: UIView {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView: ActivityIndicatorType {
}

public class CachedAnimatedImageView: UIImageView, GIFAnimatable {

    public enum LoadingIndicatorStyle {
        case centered(withSize: CGSize?)
        case fullView
    }

    // MARK: Public fields

    @objc public var gifStrategy: GIFStrategy {
        get {
            return gifPlaybackStrategy.gifStrategy
        }
        set(newGifStrategy) {
            gifPlaybackStrategy = newGifStrategy.playbackStrategy
        }
    }

    @objc public private(set) var animatedGifData: Data?

    public lazy var animator: Gifu.Animator? = {
        return Gifu.Animator(withDelegate: self)
    }()

    @objc public var shouldShowLoadingIndicator: Bool = true

    // MARK: Private fields

    private var gifPlaybackStrategy: GIFPlaybackStrategy = MediumGIFPlaybackStrategy()

    @objc private var currentTask: URLSessionTask?

    private var customLoadingIndicator: ActivityIndicatorType?

    private lazy var defaultLoadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        layoutViewCentered(loadingIndicator, size: nil)
        return loadingIndicator
    }()

    private var loadingIndicator: ActivityIndicatorType {
        guard let custom = customLoadingIndicator else {
            return defaultLoadingIndicator
        }
        return custom
    }

    // MARK: Initializers

    public override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public override init(image: UIImage?) {
        super.init(image: image)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLowMemoryWarningNotification),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }

    // MARK: - Public methods

    override open func display(_ layer: CALayer) {
        // Fixes an unrecognized selector crash on iOS 13 and below when calling super.display(_:) directly
        // This was first reported here: p5T066-1xs-p2#comment-5908
        // Investigating the issue I came across this discussion with a workaround in the Gifu repo: https://git.io/JUPxC
        if UIImageView.instancesRespond(to: #selector(display(_:))) {
            super.display(layer)
        }

        updateImageIfNeeded()
    }

    @objc public func setAnimatedImage(_ urlRequest: URLRequest,
                       placeholderImage: UIImage?,
                       success: (() -> Void)?,
                       failure: ((NSError?) -> Void)?) {

        currentTask?.cancel()
        image = placeholderImage

        if checkCache(urlRequest, success) {
            return
        }

        let successBlock: (Data, UIImage?) -> Void = { [weak self] animatedImageData, staticImage in
            self?.validateAndSetGifData(animatedImageData, alternateStaticImage: staticImage, success: success)
        }

        currentTask = AnimatedImageCache.shared.animatedImage(urlRequest,
                                                              placeholderImage: placeholderImage,
                                                              success: successBlock,
                                                              failure: failure)
    }

    @objc public func setAnimatedImage(_ animatedImageData: Data, success: (() -> Void)? = nil) {
        currentTask?.cancel()
        validateAndSetGifData(animatedImageData, alternateStaticImage: nil, success: success)
    }

    /// Clean the image view from previous images and ongoing data tasks.
    ///
    @objc public func clean() {
        currentTask?.cancel()
        image = nil
        animatedGifData = nil
    }

    @objc public func prepForReuse() {
        self.prepareForReuse()
    }

    @objc public func startLoadingAnimation() {
        guard shouldShowLoadingIndicator else {
            return
        }
        DispatchQueue.main.async() {
            self.loadingIndicator.startAnimating()
        }
    }

    @objc public func stopLoadingAnimation() {
        DispatchQueue.main.async() {
            self.loadingIndicator.stopAnimating()
        }
    }

    public func addLoadingIndicator(_ loadingIndicator: ActivityIndicatorType, style: LoadingIndicatorStyle) {
        removeCustomLoadingIndicator()
        customLoadingIndicator = loadingIndicator
        addCustomLoadingIndicator(loadingIndicator, style: style)
    }

    // MARK: - Private methods

    @objc private func handleLowMemoryWarningNotification(_ notification: NSNotification) {
        stopAnimatingGIF()
    }

    private func validateAndSetGifData(_ animatedImageData: Data, alternateStaticImage: UIImage? = nil, success: (() -> Void)? = nil) {
        let didVerifyDataSize = gifPlaybackStrategy.verifyDataSize(animatedImageData)
        DispatchQueue.main.async() {
            if let staticImage = alternateStaticImage {
                self.image = staticImage
            } else {
                self.image = UIImage(data: animatedImageData)
            }

            DispatchQueue.global().async {
                if didVerifyDataSize {
                    self.animate(data: animatedImageData, success: success)
                } else {
                    self.animatedGifData = nil
                    success?()
                }
            }
        }
    }

    private func checkCache(_ urlRequest: URLRequest, _ success: (() -> Void)?) -> Bool {
        if let cachedData = AnimatedImageCache.shared.cachedData(url: urlRequest.url) {
            // Always attempt to load momentary image to show while gif is loading to avoid flashing.
            if let cachedStaticImage = AnimatedImageCache.shared.cachedStaticImage(url: urlRequest.url) {
                image = cachedStaticImage
            } else {
                animatedGifData = nil
                let staticImage = UIImage(data: cachedData)
                image = staticImage
                AnimatedImageCache.shared.cacheStaticImage(url: urlRequest.url, image: staticImage)
            }

            if gifPlaybackStrategy.verifyDataSize(cachedData) {
                animate(data: cachedData, success: success)
            } else {
                success?()
            }

            return true
        }

        return false
    }

    private func animate(data: Data, success: (() -> Void)?) {
        animatedGifData = data
        DispatchQueue.main.async() {
            self.setFrameBufferCount(self.gifPlaybackStrategy.frameBufferCount)
            self.animate(withGIFData: data) {
                success?()
            }
        }
    }

    // MARK: Loading indicator

    private func removeCustomLoadingIndicator() {
        if let oldLoadingIndicator = customLoadingIndicator {
            oldLoadingIndicator.removeFromSuperview()
        }
    }

    private func addCustomLoadingIndicator(_ loadingView: UIView, style: LoadingIndicatorStyle) {
        switch style {
        case .centered(let size):
            layoutViewCentered(loadingView, size: size)
        default:
            layoutViewFullView(loadingView)
        }
    }

    // MARK: Layout

    private func prepareViewForLayout(_ view: UIView) {
        if view.superview == nil {
            addSubview(view)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func layoutViewCentered(_ view: UIView, size: CGSize?) {
        prepareViewForLayout(view)
        var constraints: [NSLayoutConstraint] = [
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        if let size = size {
            constraints.append(view.heightAnchor.constraint(equalToConstant: size.height))
            constraints.append(view.widthAnchor.constraint(equalToConstant: size.width))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func layoutViewFullView(_ view: UIView) {
        prepareViewForLayout(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

}
