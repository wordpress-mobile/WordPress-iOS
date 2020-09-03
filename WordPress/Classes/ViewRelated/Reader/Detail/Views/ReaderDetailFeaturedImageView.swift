import UIKit

protocol ReaderDetailFeaturedImageViewDelegate: class {
    func didTapFeaturedImage(_ sender: CachedAnimatedImageView)
}

class ReaderDetailFeaturedImageView: UIView, NibLoadable {
    struct Constants {
        struct multipliers {
            static let maxPortaitHeight: CGFloat = 0.70
            static let maxPadPortaitHeight: CGFloat = 0.50
            static let maxLandscapeHeight: CGFloat = 0.30
        }
    }

    struct Styles {
        static let startTintColor: UIColor = .white
        static let endTintColor: UIColor = .text
    }

    // MARK: - IBOutlets
    @IBOutlet weak var imageView: CachedAnimatedImageView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    // MARK: - Public: Properties
    weak var delegate: ReaderDetailFeaturedImageViewDelegate?
    var isLoading: Bool = false
    var isLoaded: Bool = false

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

    /// An observer of the number of likes of the post
    private var scrollViewObserver: NSKeyValueObservation?

    private var originalNavBarAppearance: NavBarAppearance?

    deinit {
        scrollViewObserver?.invalidate()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        isUserInteractionEnabled = false

        reset()
    }

    // MARK: - Public: Configuration

    func configure(scrollView: UIScrollView, navigationBar: UINavigationBar?) {
        guard self.navigationBar == nil, self.scrollView == nil else {
            configureNavigationBar()
            return
        }

        // Navigation Bar
        self.navigationBar = navigationBar

        // Save the original appearance
        if let navBar = navigationBar {
            originalNavBarAppearance = NavBarAppearance(navigationBar: navBar)
        }

        configureNavigationBar()

        // Scrol View
        self.scrollView = scrollView
        scrollViewObserver = scrollView.observe(\.contentOffset, options: .new) { [weak self] _, _ in
            self?.scrollViewDidScroll()
        }

        addTapGesture()
    }

    func configure(for post: ReaderPost) {
        self.post = post
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
        updateInitialHeight()
    }

    func applyTransparentNavigationBarAppearance(to navigationBar: UINavigationBar?) {
        guard let navigationBar = navigationBar else {
            return
        }

        if #available(iOS 13.0, *) {
            navigationBar.standardAppearance.configureWithTransparentBackground()
        }

        NavBarAppearance.transparent.apply(navigationBar)
        if isLoaded, imageView.image == nil {
            navigationBar.tintColor = Styles.endTintColor
        }

        updateUI()
    }

    func restoreNavigationBarAppearance() {
        guard
            let navBar = navigationBar,
            let appearance = originalNavBarAppearance
        else {
            return
        }

        appearance.apply(navBar)
    }

    // MARK: - Private: Config
    private func configureNavigationBar() {
        applyTransparentNavigationBarAppearance(to: navigationBar)
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
            imageView.image != nil,
            let scrollView = self.scrollView
        else {
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
        guard let navBar = navigationBar else {
            return
        }

        let progress = (offset / heightConstraint.constant).clamp(min: 0, max: 1)


        let tintColor = UIColor.interpolate(from: Styles.startTintColor,
                                            to: Styles.endTintColor,
                                            with: progress)


        navBar.tintColor = tintColor
    }

    // MARK: - Private: Network Helpers
    public func load(completion: @escaping () -> Void) {
        guard
            let post = self.post,
            let imageURL = URL(string: post.featuredImage),
            !post.contentIncludesFeaturedImage()
        else {
            reset()
            isLoaded = true
            completion()
            return
        }

        isLoading = true
        isLoaded = true

        imageLoader.loadImage(with: imageURL, from: post, placeholder: nil, success: { [weak self] in
            self?.didFinishLoading()

            self?.isLoading = false
            completion()
        }) { [weak self] error in
            self?.reset()
            self?.isLoading = false
            completion()
        }
    }

    private func didFinishLoading() {
        updateInitialHeight()
        update()

        isHidden = false
    }

    private func updateInitialHeight() {
        let height = featuredImageHeight() - topMargin()

        heightConstraint.constant = height

        if let scrollView = self.scrollView {
            scrollView.contentInset = UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
            scrollView.setContentOffset(CGPoint(x: 0, y: -height), animated: false)
        }
    }

    private func reset() {
        navigationBar?.tintColor = Styles.endTintColor

        heightConstraint.constant = 0
        isHidden = true
    }

    // MARK: - Private: Calculations
    private func featuredImageHeight() -> CGFloat {
        guard
            let image = imageView.image,
            let superview = self.superview
        else {
            return 0
        }

        let aspectRatio = image.size.width / image.size.height
        let height = bounds.width / aspectRatio

        let isLandscape = UIDevice.current.orientation.isLandscape
        let maxHeightMultiplier: CGFloat = isLandscape ? Constants.multipliers.maxLandscapeHeight : UIDevice.isPad() ? Constants.multipliers.maxPadPortaitHeight : Constants.multipliers.maxPortaitHeight

        let result = min(height, superview.bounds.height * maxHeightMultiplier)

        // Restrict the min height of the view to twice the size of the top margin
        // This prevents high aspect ratio images from appearing too small
        return max(result, topMargin() * 2)
    }

    private var statusBarHeight: CGFloat {
      return max(UIApplication.shared.statusBarFrame.size.height, UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0)
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
        navigationBar.tintColor = tintColor ?? nil
        navigationBar.titleTextAttributes = titleTextAttributes ?? nil

        if #available(iOS 13.0, *) {
            let appearance = navigationBar.standardAppearance
            appearance.backgroundImage = backgroundImage ?? nil
            appearance.shadowImage = shadowImage ?? nil
            appearance.backgroundColor = backgroundColor ?? nil
        } else {
            navigationBar.setBackgroundImage(backgroundImage ?? nil, for: .default)
            navigationBar.shadowImage = shadowImage ?? nil
            navigationBar.backgroundColor = backgroundColor ?? nil
        }
    }

    static var transparent: NavBarAppearance {
        var isTranslucent = true

        if #available(iOS 13.0, *) {
            isTranslucent = false
        }

        return NavBarAppearance(backgroundImage: UIImage(),
                                shadowImage: UIImage(),
                                backgroundColor: .clear,
                                tintColor: .clear,
                                isTranslucent: isTranslucent,
                                titleTextAttributes: nil)
    }
}

private extension NavBarAppearance {
    init(navigationBar: UINavigationBar) {
        if #available(iOS 13.0, *) {
            let appearance = navigationBar.standardAppearance
            backgroundImage = appearance.backgroundImage
            shadowImage = appearance.shadowImage
            backgroundColor = appearance.backgroundColor
        } else {
            backgroundImage = navigationBar.backgroundImage(for: .default)
            shadowImage = navigationBar.shadowImage
            backgroundColor = navigationBar.backgroundColor
        }

        isTranslucent = navigationBar.isTranslucent
        tintColor = navigationBar.tintColor
        titleTextAttributes = navigationBar.titleTextAttributes
    }
}
