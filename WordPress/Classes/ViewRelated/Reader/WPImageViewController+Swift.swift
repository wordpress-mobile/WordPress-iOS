import UIKit

extension WPImageViewController {
    @objc func loadOriginalImage(for media: Media, success: @escaping (UIImage) -> Void, failure: @escaping (Error) -> Void) {
        Task { @MainActor in
            do {
                let image = try await MediaImageService.shared.image(for: media, size: .original)
                success(image)
            } catch {
                failure(error)
            }
        }
    }

    @objc func startAnimationIfNeeded(for image: UIImage, in imageView: CachedAnimatedImageView?) {
        if let gif = image as? AnimatedImageWrapper, let data = gif.gifData {
            imageView?.animate(withGIFData: data)
        }
    }
}
