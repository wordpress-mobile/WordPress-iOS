import UIKit
import AsyncImageKit
import WordPressData
import WordPressUI
import UniformTypeIdentifiers

/// A fullscreen preview of a set of media assets.
final class LightboxViewController: UIViewController {
    private var pageVC: LightboxImagePageViewController?
    private var items: [LightboxItem]

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

    private init(items: [LightboxItem], configuration: Configuration = .init()) {
        assert(items.count == 1, "Current API supports only one item at a time")
        self.items = items
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = configuration.backgroundColor

        if let item = items.first {
            show(item)
        }
        if configuration.showsCloseButton {
            addCloseButton()
        }
    }

    private func show(_ item: LightboxItem) {
        let pageVC = LightboxImagePageViewController(item: item)
        pageVC.willMove(toParent: self)
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.pinEdges()
        pageVC.didMove(toParent: self)
        if let thumbnail {
            pageVC.scrollView.configure(with: thumbnail)
            self.thumbnail = nil
        }
        self.pageVC = pageVC
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
                let detailsView: UIView = detailViewController.pageVC?.scrollView.imageView ?? detailViewController.view
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

@available(iOS 17, *)
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
