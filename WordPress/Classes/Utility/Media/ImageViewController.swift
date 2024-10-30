import Foundation
import UIKit

@MainActor
final class ImageViewController {
    var downloader: ImageDownloader = .shared
    var onStateChanged: (State) -> Void = { _ in }

    private(set) var task: Task<Void, Never>?

    enum State {
        case loading
        case success(UIImage)
        case failure
    }

    deinit {
        task?.cancel()
    }

    func prepareForReuse() {
        task?.cancel()
        task = nil
    }

    func setImage(with imageURL: URL, host: MediaHost? = nil, size: CGSize? = nil) {
        task?.cancel()

        if let image = downloader.cachedImage(for: imageURL, size: size) {
            onStateChanged(.success(image))
        } else {
            onStateChanged(.loading)
            task = Task { @MainActor [downloader, weak self] in
                do {
                    let options = ImageRequestOptions(size: size)
                    let image: UIImage
                    if let host {
                        image = try await downloader.image(from: imageURL, host: host, options: options)
                    } else {
                        image = try await downloader.image(from: imageURL, options: options)
                    }
                    guard !Task.isCancelled else { return }
                    self?.onStateChanged(.success(image))
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.onStateChanged(.failure)
                }
            }
        }
    }
}
