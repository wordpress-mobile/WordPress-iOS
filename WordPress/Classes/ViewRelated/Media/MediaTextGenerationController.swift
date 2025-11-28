import UIKit
import SVProgressHUD
import WordPressData
import WordPressShared
import WordPressIntelligence

@available(iOS 26, *)
@MainActor
final class MediaTextGenerationController {

    enum GenerationType {
        case altText
        case caption
    }

    private let media: Media
    private let onMetadataUpdated: (GenerationType, String) -> Void

    init(media: Media, onMetadataUpdated: @escaping (GenerationType, String) -> Void) {
        self.media = media
        self.onMetadataUpdated = onMetadataUpdated
    }

    /// Configures a settings controller with a generate button
    func configure(_ controller: SettingsTextViewController, for type: GenerationType) {
        guard IntelligenceService.isSupported else { return }

        let button = makeGenerateButton(for: controller, type: type)
        controller.navigationItem.rightBarButtonItem = button
    }

    private func makeGenerateButton(for controller: SettingsTextViewController, type: GenerationType) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "sparkles"),
            style: .plain,
            target: nil,
            action: nil
        )
        button.accessibilityLabel = Strings.generate
        button.primaryAction = UIAction { [weak self, weak controller, weak button] _ in
            guard let self, let controller, let button else { return }
            self.handleGenerate(controller: controller, button: button, type: type)
        }
        return button
    }

    private func handleGenerate(controller: SettingsTextViewController, button: UIBarButtonItem, type: GenerationType) {
        setGenerating(true, button: button)

        Task {
            do {
                let generatedText = try await generateText(for: type)
                controller.text = generatedText
                onMetadataUpdated(type, generatedText)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            setGenerating(false, button: button)
        }
    }

    private func generateText(for type: GenerationType) async throws -> String {
        // Load image from media
        guard let imageURL = media.absoluteThumbnailLocalURL ?? media.absoluteLocalURL,
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw NSError(domain: "MediaTextGenerationController", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to load image for analysis"
            ])
        }

        // Build metadata (without imageAnalysis - Vision analysis will be performed automatically)
        let presenter = MediaMetadataPresenter(media: media)
        let metadata = MediaMetadata(
            filename: media.filename,
            title: media.title,
            caption: media.caption,
            description: media.desc,
            altText: media.alt,
            fileType: presenter.fileType,
            dimensions: presenter.dimensions,
            imageAnalysis: nil  // Will be populated automatically by convenience API
        )

        // Use convenience API that handles VisionKit analysis automatically
        switch type {
        case .altText:
            return try await ImageAltTextGenerator().generate(cgImage: cgImage, metadata: metadata)
        case .caption:
            return try await ImageCaptionGenerator().generate(cgImage: cgImage, metadata: metadata)
        }
    }

    private func setGenerating(_ isGenerating: Bool, button: UIBarButtonItem) {
        if isGenerating {
            let indicator = UIActivityIndicatorView()
            indicator.startAnimating()
            indicator.frame = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
            button.customView = indicator
        } else {
            button.customView = nil
        }
        button.isEnabled = !isGenerating
    }
}

private enum Strings {
    static let generate = NSLocalizedString(
        "media.textGeneration.generate",
        value: "Generate",
        comment: "Accessibility label for the generate button in media alt text/caption editor"
    )
}
