import UIKit
import WordPressUI
import AsyncImageKit

final class LightboxImagePageViewController: UIViewController {
    private(set) var scrollView = LightboxImageScrollView()
    private let controller = ImageLoadingController()
    private let siteMediaImageLoadingController = SiteMediaImageLoadingController()
    private let item: LightboxItem
    private let activityIndicator = UIActivityIndicatorView()
    private var errorView: UIImageView?

    /// Used by UIPageViewController to track position.
    var pageIndex: Int = 0

    init(item: LightboxItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)

        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.pinCenter()

        scrollView.onDismissTapped = { [weak self] in
            self?.parent?.presentingViewController?.dismiss(animated: true)
        }

        controller.onStateChanged = { [weak self] in
            self?.setState($0)
        }

        siteMediaImageLoadingController.onStateChanged = { [weak self] in
            self?.setState($0)
        }

        startFetching()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if scrollView.frame != view.bounds {
            scrollView.frame = view.bounds
            scrollView.configureLayout()
        }
    }

    private func startFetching() {
        switch item {
        case .image(let image):
            setState(.success(image))
        case .asset(let asset):
            controller.setImage(with: ImageRequest(url: asset.sourceURL, host: asset.host))
        case .media(let media):
            siteMediaImageLoadingController.setImage(with: media, size: .original)
        }
    }

    private func setState(_ state: ImageLoadingController.State) {
        switch state {
        case .loading:
            if scrollView.imageView.image == nil {
                activityIndicator.startAnimating()
            }
        case .success(let image):
            activityIndicator.stopAnimating()
            scrollView.configure(with: image)
        case .failure:
            activityIndicator.stopAnimating()
            makeErrorView().isHidden = false
        }
    }

    private func makeErrorView() -> UIImageView {
        if let errorView {
            return errorView
        }
        let errorView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        errorView.tintColor = .separator
        view.addSubview(errorView)
        errorView.pinCenter()
        self.errorView = errorView
        return errorView
    }
}
