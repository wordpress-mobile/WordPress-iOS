import SwiftUI
import WordPressData

/// A SwiftUI wrapper for LightboxViewController
struct LightboxView: UIViewControllerRepresentable {
    let media: Media
    var thumbnail: UIImage?

    func makeUIViewController(context: Context) -> LightboxViewController {
        let controller = LightboxViewController(media: media)
        controller.thumbnail = thumbnail
        return controller
    }

    func updateUIViewController(_ uiViewController: LightboxViewController, context: Context) {
        // No updates needed
    }
}
