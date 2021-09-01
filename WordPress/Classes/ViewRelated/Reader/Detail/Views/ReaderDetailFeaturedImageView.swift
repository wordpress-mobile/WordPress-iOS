import UIKit

protocol ReaderDetailFeaturedImageViewDelegate: AnyObject {
    func didTapFeaturedImage(_ sender: CachedAnimatedImageView)
}

protocol UpdatableStatusBarStyle: UIViewController {
    func updateStatusBarStyle(to style: UIStatusBarStyle)
}

class ReaderDetailFeaturedImageView: UIView, NibLoadable {
    struct Constants {
        struct multipliers {
            static let maxPortaitHeight: CGFloat = 0.70
            static let maxPadPortaitHeight: CGFloat = 0.50
            static let maxLandscapeHeight: CGFloat = 0.30
        }

        static let imageLoadingTimeout: TimeInterval = 4
    }

    struct Styles {
        static let startTintColor: UIColor = .white
        static let endTintColor: UIColor = .text
    }

    // MARK: - IBOutlets
    @IBOutlet weak var imageView: CachedAnimatedImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingView: UIView!

    // MARK: - Public: Properties
    weak var delegate: ReaderDetailFeaturedImageViewDelegate?

    /// Keeps track if the featured image is loading
    var isLoading: Bool = false

    /// Keeps track of if we've loaded the image before
    var isLoaded: Bool = false

    /// Temporary work around until white headers are shipped app-wide,
    /// allowing Reader Detail to use a blue navbar.
    var useCompatibilityMode: Bool = false {
        didSet {
            updateUI()
        }
    }

    // MARK: - Private: Properties

    /// Image loader for the featured image
    ///
    private lazy var imageLoader: ImageLoader = {
        // Allow for large GIFs to animate on the detail page
        return ImageLoader(imageView: imageView, gifStrategy: .largeGIFs)
    }()

    /// The reader post that the toolbar interacts with
    private var post: ReaderPost?
    private weak var scrollView: UIScrollView?
    private weak var navigationBar: UINavigationBar?

    private var currentStatusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            statusBarUpdater?.updateStatusBarStyle(to: currentStatusBarStyle)
        }
    }

    private weak var statusBarUpdater: UpdatableStatusBarStyle?

    /// Listens for contentOffset changes to track when the user scrolls
    private var scrollViewObserver: NSKeyValueObservation?

    /// Stores the nav bar appearance before we change it to transparent
    /// this allows us to reset it when the view disappears
    private var originalNavBarAppearance: NavBarAppearance?

    private var navBarTintColor: UIColor = Styles.endTintColor {
        didSet {
            navigationBar?.setItemTintColor(useCompatibilityMode ? .textInverted : navBarTintColor)
        }
    }

    private var imageSize: CGSize?
    private var timeoutTimer: Timer?

    // MARK: - View Methods
    deinit {
        scrollViewObserver?.invalidate()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        loadingView.backgroundColor = .placeholderElement
        isUserInteractionEnabled = false

        reset()
    }

    func viewWillDisappear() {
        scrollViewObserver?.invalidate()
        scrollViewObserver = nil

        restoreNavigationBarAppearanceIfNeeded()
    }

    // MARK: - Public: Configuration

    func configure(scrollView: UIScrollView, navigationBar: UINavigationBar?) {
        guard self.navigationBar == nil, self.scrollView == nil else {
            configureNavigationBar()
            addScrollObserver()
            return
        }

        // Navigation Bar
        self.navigationBar = navigationBar

        // Save the original appearance
        if let navBar = navigationBar {
            originalNavBarAppearance = NavBarAppearance(navigationBar: navBar)
        }

        self.scrollView = scrollView

        configureNavigationBar()
        addScrollObserver()
        addTapGesture()
    }

    func configure(for post: ReaderPost, with statusBarUpdater: UpdatableStatusBarStyle) {
        self.post = post
        self.statusBarUpdater = statusBarUpdater
        isLoaded = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUI()
    }

    // MARK: - Public: Helpers
    public func updateUI() {
        scrollViewDidScroll()
    }

    public func deviceDidRotate() {
        guard !useCompatibilityMode else {
            return
        }

        updateInitialHeight(resetContentOffset: false)
    }

    func applyTransparentNavigationBarAppearance(to navigationBar: UINavigationBar?) {
        guard let navigationBar = navigationBar,
              useCompatibilityMode == false else {
            return
        }

        navigationBar.standardAppearance.configureWithTransparentBackground()

        NavBarAppearance.transparent.apply(navigationBar)
        if isLoaded, imageView.image == nil {
            navBarTintColor = Styles.endTintColor
        }

        updateUI()
    }

    func restoreNavigationBarAppearanceIfNeeded() {
        guard
            let navBar = navigationBar,
            let appearance = originalNavBarAppearance
        else {
            return
        }

        appearance.apply(navBar)
    }

    private func hideLoading() {
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0.0
        }) { (_) in
            self.loadingView.isHidden = true
            self.loadingView.alpha = 1.0
        }
    }

    // MARK: - Private: Config
    private func configureNavigationBar() {
        applyTransparentNavigationBarAppearance(to: navigationBar)
    }

    private func addScrollObserver() {
        guard scrollViewObserver == nil,
              let scrollView = self.scrollView else {
            return
        }

        scrollViewObserver = scrollView.observe(\.contentOffset, options: .new) { [weak self] _, _ in
            self?.scrollViewDidScroll()
        }
    }

    // MARK: - Tap Gesture
    private func addTapGesture() {
        guard let scrollView = scrollView else {
            return
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        scrollView.addGestureRecognizer(tapGesture)
    }

    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didTapFeaturedImage(imageView)
    }



    // MARK: - Private: Scroll Handlers
    private func scrollViewDidScroll () {
        guard !isLoading else {
            return
        }

        update()
    }

    private func update() {
        guard
            !useCompatibilityMode,
            imageSize != nil,
            let scrollView = self.scrollView
        else {
            reset()
            return
        }

        let offsetY = scrollView.contentOffset.y

        updateFeaturedImageHeight(with: offsetY)
        updateNavigationBar(with: offsetY)
    }

    private func updateFeaturedImageHeight(with offset: CGFloat) {
        let height = featuredImageHeight()

        guard height > 0 else {
            return
        }

        let y = height - ((offset - topMargin()) + height)

        heightConstraint.constant = max(y, 0)
    }

    private func updateNavigationBar(with offset: CGFloat) {
        guard navigationBar != nil else {
            return
        }

        let fullProgress = (offset / heightConstraint.constant)
        let progress = fullProgress.clamp(min: 0, max: 1)

        let tintColor = UIColor.interpolate(from: Styles.startTintColor,
                                            to: Styles.endTintColor,
                                            with: progress)

        if traitCollection.userInterfaceStyle == .light {
            currentStatusBarStyle = fullProgress >= 2.5 ? .darkContent : .lightContent
        } else {
            currentStatusBarStyle = .lightContent
        }

        navBarTintColor = tintColor
    }

    static func shouldDisplayFeaturedImage(with post: ReaderPost) -> Bool {
        let imageURL = URL(string: post.featuredImage)

        return imageURL != nil && !post.contentIncludesFeaturedImage()
    }

    // MARK: - Private: Network Helpers
    public func load(completion: @escaping () -> Void) {
        guard
            !useCompatibilityMode,
            !isLoading,
            let post = self.post,
            let imageURL = URL(string: post.featuredImage),
            Self.shouldDisplayFeaturedImage(with: post)
        else {
            reset()
            isLoaded = true
            completion()
            return
        }

        loadingView.isHidden = false

        isLoading = true
        isLoaded = true

        var timedOut = false

        let completionHandler: (CGSize) -> Void = { [weak self] size in
            guard let self = self else {
                return
            }

            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil

            self.imageSize = size
            self.didFinishLoading(timedOut: timedOut)
            self.isLoading = false

            completion()
        }

        let failureHandler: () -> Void = { [weak self] in
            self?.reset()
            self?.isLoading = false
            completion()
        }

        // Times out if the loading is taking too long
        // this prevents the user from being stuck on the loading view for too long
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: Constants.imageLoadingTimeout, repeats: false, block: { _ in
            timedOut = true
            failureHandler()
        })

        self.imageLoader.imageDimensionsHandler = { _, size in
            completionHandler(size)
        }

        self.imageLoader.loadImage(with: imageURL, from: post, placeholder: nil, success: { [weak self] in
            // If we haven't loaded the image size yet
            // trigger the handler to update the height, etc.
            if self?.imageSize == nil {
                if let size = self?.imageView.image?.size {
                    self?.imageSize = size
                    completionHandler(size)
                }
            }

            self?.hideLoading()
        }) { _ in
            failureHandler()
        }
    }

    private func didFinishLoading(timedOut: Bool = false) {
        // Don't reset the scroll position if we timed out to prevent a jump
        // if the user has started reading / scrolling
        updateInitialHeight(resetContentOffset: !timedOut)
        update()

        isHidden = false
    }

    private func updateInitialHeight(resetContentOffset: Bool = true) {
        let height = featuredImageHeight() - topMargin()

        heightConstraint.constant = height

        if let scrollView = self.scrollView {
            if height > 0 {
                // Only adjust insets when height is a positive value to avoid clipping.
                scrollView.contentInset = UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
            }
            if resetContentOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: -height), animated: false)
            }
        }
    }

    private func reset() {
        navigationBar?.setItemTintColor(useCompatibilityMode ? .appBarTint : Styles.endTintColor)

        resetStatusBarStyle()
        heightConstraint.constant = 0
        isHidden = true

        loadingView.isHidden = true
    }

    private func resetStatusBarStyle() {
        let isDark = traitCollection.userInterfaceStyle == .dark

        currentStatusBarStyle = isDark ? .lightContent : .darkContent
    }

    // MARK: - Private: Calculations
    private func featuredImageHeight() -> CGFloat {
        guard
            let imageSize = self.imageSize,
            let superview = self.superview
        else {
            return 0
        }

        let aspectRatio = imageSize.width / imageSize.height
        let height = bounds.width / aspectRatio

        let isLandscape = UIDevice.current.orientation.isLandscape
        let maxHeightMultiplier: CGFloat = isLandscape ? Constants.multipliers.maxLandscapeHeight : UIDevice.isPad() ? Constants.multipliers.maxPadPortaitHeight : Constants.multipliers.maxPortaitHeight

        let result = min(height, superview.bounds.height * maxHeightMultiplier)

        // Restrict the min height of the view to twice the size of the top margin
        // This prevents high aspect ratio images from appearing too small
        return max(result, topMargin() * 2)
    }

    private var statusBarHeight: CGFloat {
        return max(UIApplication.shared.currentStatusBarFrame.size.height, UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0)
    }

    private func topMargin() -> CGFloat {
        let navBarHeight = navigationBar?.frame.height ?? 0
        return statusBarHeight + navBarHeight
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ReaderDetailFeaturedImageView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: self)
        let isOutsideView = !imageView.frame.contains(touchPoint)

        /// Do not accept the touch if outside the featured image view
        return isOutsideView == false
    }
}

/// Represents the appearance for a navigation bar
struct NavBarAppearance {
    var backgroundImage: UIImage?
    var shadowImage: UIImage?
    var backgroundColor: UIColor?
    var tintColor: UIColor?
    var isTranslucent: Bool = false
    var titleTextAttributes: [NSAttributedString.Key: Any]?

    func apply(_ navigationBar: UINavigationBar) {
        navigationBar.isTranslucent = isTranslucent
        navigationBar.setItemTintColor(tintColor)
        navigationBar.titleTextAttributes = titleTextAttributes ?? nil

        let appearance = navigationBar.standardAppearance
        appearance.backgroundImage = backgroundImage ?? nil
        appearance.shadowImage = shadowImage ?? nil
        appearance.backgroundColor = backgroundColor ?? nil
    }

    static var transparent: NavBarAppearance {
        return NavBarAppearance(backgroundImage: UIImage(),
                                shadowImage: UIImage(),
                                backgroundColor: .clear,
                                tintColor: .clear,
                                isTranslucent: false,
                                titleTextAttributes: nil)
    }
}

private extension NavBarAppearance {
    init(navigationBar: UINavigationBar) {
        let appearance = navigationBar.standardAppearance
        backgroundImage = appearance.backgroundImage
        shadowImage = appearance.shadowImage
        backgroundColor = appearance.backgroundColor
        isTranslucent = navigationBar.isTranslucent
        tintColor = navigationBar.tintColor
        titleTextAttributes = navigationBar.titleTextAttributes
    }
}


// MARK: - UINavigationBar Tint Color Helper Extension
private extension UINavigationBar {
    func setItemTintColor(_ color: UIColor?) {
        tintColor = color

        items?.forEach { $0.setTintColor(color) }
    }
}

private extension UINavigationItem {
    /// Forcibly sets the tint color of all the button items
    func setTintColor(_ color: UIColor?) {
        leftBarButtonItem?.tintColor = color
        leftBarButtonItems?.forEach { $0.tintColor = color }
        rightBarButtonItem?.tintColor = color
        rightBarButtonItems?.forEach { $0.tintColor = color }
    }
}
