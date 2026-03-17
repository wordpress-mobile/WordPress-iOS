import UIKit
import WordPressUI
import AsyncImageKit

final class LightboxImagePageViewController: UIViewController {
    private(set) var scrollView = LightboxImageScrollView()
    private let item: LightboxItem
    private let activityIndicator = UIActivityIndicatorView()
    private var errorView: UIImageView?
    private var task: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?

    /// Used by UIPageViewController to track position.
    var pageIndex: Int = 0

    init(item: LightboxItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        task?.cancel()
        previewTask?.cancel()
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

        task = Task { @MainActor [weak self] in
            await self?.loadImage()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if scrollView.frame != view.bounds {
            scrollView.frame = view.bounds
            scrollView.configureLayout()
        }
    }

    // MARK: - Loading

    @MainActor
    private func loadImage() async {
        switch item {
        case .image(let image):
            showImage(image)
        case .asset(let asset):
            await loadAsset(asset)
        case .media(let media):
            await loadMedia(media)
        }
    }

    @MainActor
    private func loadAsset(_ asset: LightboxAsset) async {
        let downloader = ImageDownloader.shared
        let request = ImageRequest(url: asset.sourceURL, host: asset.host)

        if let cached = downloader.cachedImage(for: request) {
            showImage(cached)
            return
        }

        activityIndicator.startAnimating()

        // Load preview in parallel with the full image.
        var previewTask: Task<Void, Never>?
        if let previewURL = asset.previewURL {
            previewTask = Task { @MainActor [weak self] in
                let previewRequest = ImageRequest(url: previewURL, host: asset.host)
                if let preview = try? await downloader.image(for: previewRequest) {
                    guard !Task.isCancelled else { return }
                    self?.showImage(preview)
                }
            }
            self.previewTask = previewTask
        }

        // Load full-resolution image.
        do {
            let image = try await downloader.image(for: request)
            guard !Task.isCancelled else { return }
            previewTask?.cancel()
            showImage(image)
        } catch {
            guard !Task.isCancelled else { return }
            if scrollView.imageView.image == nil {
                showError()
            }
        }
    }

    @MainActor
    private func loadMedia(_ media: Media) async {
        let service = MediaImageService.shared

        if let cached = service.getCachedThumbnail(for: .init(media), size: .original) {
            showImage(cached)
            return
        }

        activityIndicator.startAnimating()

        do {
            let image = try await service.image(for: media, size: .original)
            guard !Task.isCancelled else { return }
            showImage(image)
        } catch {
            guard !Task.isCancelled else { return }
            showError()
        }
    }

    // MARK: - State

    private func showImage(_ image: UIImage) {
        activityIndicator.stopAnimating()
        scrollView.configure(with: image)
        errorView?.isHidden = true
    }

    private func showError() {
        activityIndicator.stopAnimating()
        if errorView == nil {
            let errorView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
            errorView.tintColor = .separator
            self.view.addSubview(errorView)
            errorView.pinCenter()
            self.errorView = errorView
        }
        errorView?.isHidden = false
    }
}
