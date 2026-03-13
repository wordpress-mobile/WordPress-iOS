import UIKit
import AsyncImageKit
import WordPressData
import WordPressUI
import UniformTypeIdentifiers

/// A fullscreen preview of a set of media assets.
final class LightboxViewController: UIViewController {
    private var pageVC: LightboxImagePageViewController?
    private var items: [LightboxItem]
    private var selectedIndex: Int
    private var pageCounter: UILabel?

    /// A thumbnail to display during transition and for the initial image download.
    var thumbnail: UIImage?

    var configuration: Configuration

    struct Configuration {
        var backgroundColor: UIColor = .black
        var showsCloseButton = true
    }

    convenience init(sourceURL: URL, host: MediaHost? = nil) {
        let asset = LightboxAsset(sourceURL: sourceURL, host: host)
        self.init(items: [.asset(asset)])
    }

    convenience init(media: Media) {
        self.init(items: [.media(media)])
    }

    convenience init(_ item: LightboxItem, configuration: Configuration = .init()) {
        self.init(items: [item])
    }

    convenience init(assets: [LightboxAsset], selectedIndex: Int = 0) {
        self.init(items: assets.map { .asset($0) }, selectedIndex: selectedIndex)
    }

    private init(items: [LightboxItem], selectedIndex: Int = 0, configuration: Configuration = .init()) {
        self.items = items
        self.selectedIndex = min(selectedIndex, max(items.count - 1, 0))
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = configuration.backgroundColor

        if items.count > 1 {
            showPageViewController()
        } else if let item = items.first {
            showSingle(item)
        }
        if configuration.showsCloseButton {
            addCloseButton()
        }
    }

    // MARK: - Single item

    private func showSingle(_ item: LightboxItem) {
        let pageVC = LightboxImagePageViewController(item: item)
        addFullscreenChild(pageVC)
        if let thumbnail {
            pageVC.scrollView.configure(with: thumbnail)
            self.thumbnail = nil
        }
        self.pageVC = pageVC
    }

    // MARK: - Multi-item (UIPageViewController)

    private var uiPageVC: UIPageViewController?

    private func showPageViewController() {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self
        let initialVC = makeImagePageVC(at: selectedIndex)
        pageVC.setViewControllers([initialVC], direction: .forward, animated: false)
        addFullscreenChild(pageVC)
        self.uiPageVC = pageVC

        addPageCounter()
        updatePageCounter()
    }

    private func makeImagePageVC(at index: Int) -> LightboxImagePageViewController {
        let vc = LightboxImagePageViewController(item: items[index])
        vc.pageIndex = index
        return vc
    }

    // MARK: - Page Counter

    private func addPageCounter() {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.5
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        self.pageCounter = label
    }

    private func updatePageCounter() {
        pageCounter?.text = "\(selectedIndex + 1) / \(items.count)"
    }

    // MARK: - Helpers

    private func addFullscreenChild(_ child: UIViewController) {
        child.willMove(toParent: self)
        addChild(child)
        view.addSubview(child.view)
        child.view.pinEdges()
        child.didMove(toParent: self)
    }

    private func addCloseButton() {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 22, weight: .medium)))
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.lightGray, .opaqueSeparator.withAlphaComponent(0.2)]))
        button.setImage(image, for: [])
        button.addTarget(self, action: #selector(buttonCloseTapped), for: .primaryActionTriggered)
        button.accessibilityLabel = SharedStrings.Button.close
        view.addSubview(button)
        button.pinEdges([.top, .trailing], to: view.safeAreaLayoutGuide, insets: UIEdgeInsets(.all, 8))
    }

    @objc private func buttonCloseTapped() {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: Presentation

    func configureZoomTransition(souceItemProvider: @escaping (UIViewController) -> UIView?) {
        if #available(iOS 18.0, *) {
            let options = UIViewController.Transition.ZoomOptions()
            options.alignmentRectProvider = { context in
                // For more info, see https://douglashill.co/zoom-transitions/#Zooming-to-only-part-of-the-destination-view
                let detailViewController = context.zoomedViewController as! LightboxViewController
                let detailsView: UIView = detailViewController.currentPageVC?.scrollView.imageView ?? detailViewController.view
                return detailsView.convert(detailsView.bounds, to: detailViewController.view)
            }
            preferredTransition = .zoom(options: options) { context in
                souceItemProvider(context.zoomedViewController)
            }
        } else {
            modalTransitionStyle = .crossDissolve
        }
    }

    func configureZoomTransition(sourceView: UIView? = nil) {
        configureZoomTransition { _ in sourceView }
        if let sourceView, thumbnail == nil {
            MainActor.assumeIsolated {
                thumbnail = getThumbnail(fromSourceView: sourceView)
            }
        }
    }

    /// Returns the currently visible `LightboxImagePageViewController`.
    private var currentPageVC: LightboxImagePageViewController? {
        if let pageVC { return pageVC }
        return uiPageVC?.viewControllers?.first as? LightboxImagePageViewController
    }
}

// MARK: - UIPageViewControllerDataSource

extension LightboxViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? LightboxImagePageViewController,
              vc.pageIndex > 0 else { return nil }
        return makeImagePageVC(at: vc.pageIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? LightboxImagePageViewController,
              vc.pageIndex < items.count - 1 else { return nil }
        return makeImagePageVC(at: vc.pageIndex + 1)
    }
}

// MARK: - UIPageViewControllerDelegate

extension LightboxViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let vc = pageViewController.viewControllers?.first as? LightboxImagePageViewController else { return }
        selectedIndex = vc.pageIndex
        updatePageCounter()
    }
}

@MainActor
private func getThumbnail(fromSourceView sourceView: UIView) -> UIImage? {
    if let imageView = sourceView as? AsyncImageView {
        return imageView.image
    }
    if let imageView = sourceView as? UIImageView {
        return imageView.image
    }
    return nil
}

#Preview {
    UINavigationController(rootViewController: LightboxDemoViewController())
}

/// An example of ``LightboxController`` usage.
final class LightboxDemoViewController: UIViewController {
    private let imageView = UIImageView()
    private let imageURL = URL(string: "https://github.com/user-attachments/assets/5a1d0d95-8ce6-4a87-8175-d67396511143")!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        imageView.pinCenter()
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 80),
        ])

        Task { @MainActor in
            imageView.image = try? await ImageDownloader.shared.image(from: imageURL)
        }

        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        imageView.isUserInteractionEnabled = true
    }

    @objc private func imageTapped() {
        let lightboxVC = LightboxViewController(sourceURL: imageURL)
        lightboxVC.configureZoomTransition(sourceView: imageView)
        present(lightboxVC, animated: true)
    }
}
