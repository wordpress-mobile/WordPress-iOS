import UIKit
import AsyncImageKit
import WordPressUI
import WordPressReader

protocol ReaderDetailFeaturedImageViewDelegate: AnyObject {
    func didTapFeaturedImage(_ sender: AsyncImageView)
}

protocol UpdatableStatusBarStyle: UIViewController {
    func updateStatusBarStyle(to style: UIStatusBarStyle)
}

final class ReaderDetailFeaturedImageView: UIView {

    // MARK: - Constants

    struct Constants {
        struct Multipliers {
            static let maxPortaitHeight: CGFloat = 0.70
            static let maxPadPortaitHeight: CGFloat = 0.50
            static let maxLandscapeHeight: CGFloat = 0.30
        }
    }

    struct Style {
        let startTintColor: UIColor
        let endTintColor: UIColor

        init(startTintColor: UIColor = .white, endTintColor: UIColor = .label) {
            self.startTintColor = startTintColor
            self.endTintColor = endTintColor
        }

        init(displaySetting: ReaderDisplaySettings) {
            self.init(endTintColor: displaySetting.color.foreground)
        }
    }

    // MARK: - Private: IBOutlets

    private let imageView = AsyncImageView()
    private let gradientView = LinearGradientView()
    private lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 230)

    // MARK: - Public: Properties

    weak var delegate: ReaderDetailFeaturedImageViewDelegate?

    /// Keeps track if the featured image is loading
    private(set) var isLoading: Bool = false

    /// Keeps track of if we've loaded the image before
    private(set) var isLoaded: Bool = false

    /// Temporary work around until white headers are shipped app-wide,
    /// allowing Reader Detail to use a blue navbar.
    var useCompatibilityMode: Bool = false {
        didSet {
            updateIfNotLoading()
        }
    }

    var displaySetting: ReaderDisplaySettings = .standard {
        didSet {
            style = .init(displaySetting: displaySetting)

            // Queue the style update in the main queue to prevent other logic from overriding this value.
            Task { @MainActor in
                resetNavigationBarTintColor()
                resetStatusBarStyle()
            }
        }
    }

    private var style: Style = .init()

    /// Determines whether the navigation bar should shift its colors to the `foreground` color
    /// once the user scrolls past the featured image.
    ///
    /// Previously, the navigation bar is only set to adaptive mode when the user uses a light `userInterfaceStyle`.
    /// Now that we're supporting multiple color themes, the logic is extended to themes with light backgrounds.
    ///
    /// For more, see comments on `updateNavigationBar(with:)`.
    private var usesAdaptiveNavigationBar: Bool {
        if displaySetting.color == .system {
            return traitCollection.userInterfaceStyle == .light
        }

        return displaySetting.hasLightBackground
    }

    // MARK: - Private: Properties

    /// The reader post that the toolbar interacts with
    private var post: ReaderPost?

    private weak var scrollView: UIScrollView?
    private weak var navigationBar: UINavigationBar?
    private weak var navigationItem: UINavigationItem?

    private var currentStatusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            statusBarUpdater?.updateStatusBarStyle(to: currentStatusBarStyle)
        }
    }

    private weak var statusBarUpdater: UpdatableStatusBarStyle?

    /// Listens for contentOffset changes to track when the user scrolls
    private var scrollViewObserver: NSKeyValueObservation?

    /// The navigation bar tint color changes depending on whether the featured image is visible or not.
    private var navBarTintColor: UIColor? {
        get {
            return navigationBar?.tintColor
        }
        set(newValue) {
            self.navigationItem?.setTintColor(useCompatibilityMode ? .invertedLabel : newValue)
        }
    }

    private var imageSize: CGSize?

    // MARK: - View Methods

    deinit {
        scrollViewObserver?.invalidate()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint.isActive = true

        gradientView.backgroundColor = UIColor.clear
        gradientView.startColor = UIColor.black.withAlphaComponent(0.66)
        gradientView.endColor = UIColor.clear

        addSubview(imageView)
        imageView.pinEdges()

        addSubview(gradientView)
        gradientView.pinEdges([.top, .horizontal])
        NSLayoutConstraint.activate([
            gradientView.heightAnchor.constraint(equalToConstant: 120).withPriority(999),
            gradientView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor) // Make sure it collapses
        ])

        isUserInteractionEnabled = false

        reset()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewWillDisappear() {
        scrollViewObserver?.invalidate()
        scrollViewObserver = nil
    }

    // MARK: - Public: Configuration

    func configure(scrollView: UIScrollView, navigationBar: UINavigationBar?, navigationItem: UINavigationItem) {
        guard self.scrollView == nil else {
            configureNavigationBar()
            addScrollObserver()
            return
        }
        self.navigationBar = navigationBar
        self.navigationItem = navigationItem
        self.scrollView = scrollView
        self.configureNavigationBar()
        self.addScrollObserver()
        self.addTapGesture()
    }

    func configure(for post: ReaderPost, with statusBarUpdater: UpdatableStatusBarStyle) {
        self.post = post
        self.statusBarUpdater = statusBarUpdater
        self.isLoaded = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Re-apply the styles after a potential orientation change.
        // This fixes a case where the navbar tint would revert after changing orientation.
        if ReaderDisplaySettings.customizationEnabled {
            resetNavigationBarTintColor()
            resetStatusBarStyle()
        }

        updateIfNotLoading()
    }

    // MARK: - Public: Fetching Featured Image

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

        isLoading = true
        isLoaded = true

        let completionHandler: (CGSize) -> Void = { [weak self] size in
            guard let self else {
                return
            }

            self.imageSize = size
            self.didFinishLoading()
            self.isLoading = false

            completion()
        }

        let failureHandler: () -> Void = { [weak self] in
            self?.reset()
            self?.isLoading = false
            completion()
        }

        // TODO: refactor.
        // This code replaced ImageDimensionsFetcher. It pretends that the image
        // the app is about the download perfectly matches the standard expectefd
        // aspect ratio. `DispatchQueue.main.async` is required for now.
        DispatchQueue.main.async {
            completionHandler(CGSize(width: 1000, height: 1000 * ReaderPostCell.coverAspectRatio))
        }

        imageView.setImage(with: ImageRequest(url: imageURL, host: MediaHost(post))) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                // If we haven't loaded the image size yet
                // trigger the handler to update the height, etc.
                if self.imageSize == nil {
                    if let size = self.imageView.image?.size {
                        self.imageSize = size
                        completionHandler(size)
                    }
                }
            case .failure:
                failureHandler()
            }
        }
    }

    // MARK: - Public: Helpers

    public func deviceDidRotate() {
        guard !useCompatibilityMode else {
            return
        }

        updateInitialHeight(resetContentOffset: false)
    }

    static func shouldDisplayFeaturedImage(with post: ReaderPost) -> Bool {
        let imageURL = URL(string: post.featuredImage)
        return imageURL != nil && !post.contentIncludesFeaturedImage()
    }

    // MARK: - Private: Config

    private func configureNavigationBar() {
        self.applyTransparentNavigationBarAppearance()
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

    // MARK: - Private: Tap Gesture

    private func addTapGesture() {
        guard let scrollView else {
            return
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        scrollView.addGestureRecognizer(tapGesture)
    }

    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didTapFeaturedImage(imageView)
    }

    // MARK: - Private: Updating UI and Handling Scrolls

    /// Updates the UI if the image is not loading.
    private func updateIfNotLoading() {
        guard !isLoading else {
            return
        }
        self.update()
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

        updateFeaturedImageHeight(with: scrollView.contentOffset.y)
        updateNavigationBar(in: scrollView)
    }

    private func scrollViewDidScroll() {
        self.updateIfNotLoading()
    }

    private func updateFeaturedImageHeight(with offset: CGFloat) {
        let height = featuredImageHeight()

        guard height > 0 else {
            return
        }

        let y = height - ((offset - topMargin()) + height)

        heightConstraint.constant = max(y, 0)
    }

    private func updateNavigationBar(in scrollView: UIScrollView) {
        /// Navigation bar is only updated in light color themes, so that the tint color can be reverted
        /// to the original color after scrolling past the featured image.
        ///
        /// In case of dark color themes, the navigation bar tint color will always be kept white.
        guard usesAdaptiveNavigationBar else {
            return
        }
        let isScrolledTop = scrollView.contentInset.top + scrollView.contentOffset.y > 5.0
        let barStyle: UIStatusBarStyle = isScrolledTop ? .darkContent : .lightContent
        if currentStatusBarStyle != barStyle {
            currentStatusBarStyle = barStyle
            navBarTintColor = barStyle == .darkContent ? style.endTintColor : style.startTintColor
        }
    }

    private func applyTransparentNavigationBarAppearance() {
        guard !useCompatibilityMode else { return }

        if isLoaded, imageView.image == nil {
            navBarTintColor = style.endTintColor
        }

        updateIfNotLoading()
    }

    // MARK: - Private: Network Helpers

    private func didFinishLoading() {
        updateInitialHeight(resetContentOffset: true)
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
        resetNavigationBarTintColor()
        resetStatusBarStyle()
        heightConstraint.constant = 0
        isHidden = true
    }

    private func resetStatusBarStyle() {
        let isDark = {
            if displaySetting.color == .system {
                return traitCollection.userInterfaceStyle == .dark
            }
            return !displaySetting.hasLightBackground
        }()

        currentStatusBarStyle = isDark ? .lightContent : .darkContent
    }

    private func resetNavigationBarTintColor() {
        navigationItem?.setTintColor(useCompatibilityMode ? UIAppColor.appBarTint : style.endTintColor)
    }

    // MARK: - Private: Calculations

    private func featuredImageHeight() -> CGFloat {
        guard let imageSize, let superview else {
            return 0
        }

        let aspectRatio = imageSize.width / imageSize.height
        let height = bounds.width / aspectRatio

        let isLandscape = UIDevice.current.orientation.isLandscape
        let maxHeightMultiplier: CGFloat = isLandscape ? Constants.Multipliers.maxLandscapeHeight : UIDevice.isPad() ? Constants.Multipliers.maxPadPortaitHeight : Constants.Multipliers.maxPortaitHeight

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

// MARK: - Private: Navigation Item Extension

private extension UINavigationItem {

    func setTintColor(_ color: UIColor?) {
        self.leftBarButtonItem?.tintColor = color
        self.rightBarButtonItem?.tintColor = color
        self.leftBarButtonItems?.forEach {
            $0.tintColor = color
        }
        self.rightBarButtonItems?.forEach {
            $0.tintColor = color
        }
    }
}
