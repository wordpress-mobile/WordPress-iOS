import Kanvas
import Gridicons
import Photos
import PhotosUI

final class WPMediaPickerForKanvas: MediaPicker {
    public static func present(on presentingViewController: UIViewController,
                               with settings: CameraSettings,
                               delegate: KanvasMediaPickerViewControllerDelegate,
                               completion: @escaping () -> Void) {

        guard let blog = (presentingViewController as? StoryEditor)?.post.blog else {
            DDLogWarn("No blog for Kanvas Media Picker")
            return
        }

        let pickerDelegate = MediaPickerDelegate(kanvasDelegate: delegate, blog: blog)

        let photosPicker = PHPickerViewController(configuration: {
            var configuration = PHPickerConfiguration()
            configuration.preferredAssetRepresentationMode = .current
            configuration.selection = .ordered
            configuration.selectionLimit = 0
            return configuration
        }())
        photosPicker.delegate = pickerDelegate

        presentingViewController.present(photosPicker, animated: true, completion: completion)

        objc_setAssociatedObject(presentingViewController, &WPMediaPickerForKanvas.delegateAssociatedKey, pickerDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private static var delegateAssociatedKey: UInt8 = 0
}

final class MediaPickerDelegate: PHPickerViewControllerDelegate {
    private weak var kanvasDelegate: KanvasMediaPickerViewControllerDelegate?
    private let blog: Blog

    init(kanvasDelegate: KanvasMediaPickerViewControllerDelegate,
         blog: Blog) {
        self.kanvasDelegate = kanvasDelegate
        self.blog = blog
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            picker.presentingViewController?.dismiss(animated: true)
            return
        }
        Task {
            await process(results, picker: picker)
        }
    }

    @MainActor
    private func process(_ results: [PHPickerResult], picker: PHPickerViewController) async {
        startLoading(in: picker)
        defer { stopLoading() }

        do {
            let selection = try await exportPickedMedia(from: results, blog: blog)
            picker.presentingViewController?.dismiss(animated: true)
            kanvasDelegate?.didPick(media: selection)
        } catch {
            if let error = error as? AssetExportError,
               case .videoLengthLimitExceeded = error {
                presentVideoLimitExceededFromPicker(on: picker)
            } else {
                showError(error, in: picker)
            }
        }
    }

    // MARK: - Helpers

    private func startLoading(in viewController: UIViewController) {
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setContainerView(viewController.view)
        SVProgressHUD.showProgress(-1)
    }

    private func stopLoading() {
        SVProgressHUD.dismiss()
    }

    private func showError(_ error: Error, in viewController: UIViewController) {
        let title = NSLocalizedString("mediaPicker.failedMediaExportAlert.title", value: "Failed Media Export", comment: "Error title when picked media cannot be imported into stories.")
        let message = NSLocalizedString("mediaPicker.failedMediaExportAlert.message", value: "Your media could not be exported. If the problem persists you can contact us via the Me > Help & Support screen.", comment: "Error message when picked media cannot be imported into stories.")
        let dismissTitle = NSLocalizedString(
            "mediaPicker.failedMediaExportAlert.dismissButton",
            value: "Dismiss",
            comment: "The title of the button to dismiss the alert shown when the picked media cannot be imported into stories."
        )
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismiss = UIAlertAction(title: dismissTitle, style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismiss)
        viewController.present(alert, animated: true, completion: nil)

        DDLogError("Failed to export picked Stories media: \(error)")
    }
}

// MARK: - Helpers

@MainActor
private func exportPickedMedia(from results: [PHPickerResult], blog: Blog) async throws -> [PickedMedia] {
    try await withThrowingTaskGroup(of: PickedMedia.self) { group in
        for result in results {
            group.addTask { @MainActor in
                try await exportPickedMedia(from: result.itemProvider, blog: blog)
            }
        }
        var selection: [PickedMedia] = []
        for try await media in group {
            selection.append(media)
        }
        return selection
    }
}

// Isolating it on the @MainActor because NSItemProvider is non-Sendable.
@MainActor
private func exportPickedMedia(from provider: NSItemProvider, blog: Blog) async throws -> PickedMedia {
    if provider.hasConformingType(.image) {
        let image = try await NSItemProvider.image(for: provider)
        let imageSize = image.size.scaled(by: image.scale)
        let targetSize = getTargetSize(forImageSize: imageSize, targetSize: CGSize(width: 2048, height: 2048))
        let resized = await Task.detached {
            image.resizedImage(targetSize, interpolationQuality: .default)
        }.value
        return PickedMedia.image(resized ?? image, nil)
    } else if provider.hasConformingType(.movie) || provider.hasConformingType(.video) {
        let videoURL = try await NSItemProvider.video(for: provider)
        guard blog.canUploadVideo(from: videoURL) else {
            throw AssetExportError.videoLengthLimitExceeded
        }
        let asset = AVAsset(url: videoURL)
        // important: Kanvas doesn't support video orientation!
        guard asset.tracks(withMediaType: .video).first?.preferredTransform != .identity else {
            return PickedMedia.video(videoURL)
        }
        defer { try? FileManager.default.removeItem(at: videoURL) }
        let exportURL = try await asset.exportFixingOrientation(to: videoURL
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString))
        return PickedMedia.video(exportURL)
    } else {
        throw AssetExportError.unexpectedAssetType
    }
}

/// - parameter imageSize: Image size in pixels.
private func getTargetSize(forImageSize imageSize: CGSize, targetSize originalTargetSize: CGSize) -> CGSize {
    guard imageSize.width > 0 && imageSize.height > 0 else {
        return originalTargetSize
    }
    // Scale image to fit the target size but avoid upscaling
    let scale = min(1, min(
        originalTargetSize.width / imageSize.width,
        originalTargetSize.height / imageSize.height
    ))
    return imageSize.scaled(by: scale).rounded()
}

// MARK: - User messages for video limits allowances

extension MediaPickerDelegate: VideoLimitsAlertPresenter {}

// MARK: Media Export extensions

private extension AVAsset {
    func exportFixingOrientation(to exportURL: URL) async throws -> URL {
        let exportURL = exportURL.deletingPathExtension().appendingPathExtension("mov")
        let (composition, videoComposition) = try rotate()

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1920x1080) else {
            throw AssetExportError.videoAssetExportFailed
        }
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mov
        await exportSession.export()
        if let error = exportSession.error {
            throw error
        }
        return exportURL
    }

    /// Applies the `preferredTransform` of the video track.
    /// - Returns: Returns both an AVMutableComposition containing video + audio and an AVVideoComposition of the rotate video.
    private func rotate() throws -> (AVMutableComposition, AVVideoComposition) {
        guard let videoTrack = tracks(withMediaType: .video).first else {
            throw AssetExportError.assetMissingVideoTrack
        }

        let videoComposition = AVMutableVideoComposition(propertiesOf: self)
        let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        videoComposition.renderSize = CGSize(width: abs(size.width), height: abs(size.height))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: videoTrack.timeRange.duration)

        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        transformer.setTransform(videoTrack.preferredTransform, at: .zero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]

        let composition = AVMutableComposition()

        let mutableVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? mutableVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, end: videoTrack.timeRange.duration), of: videoTrack, at: .zero)

        if let audioTrack = tracks(withMediaType: .audio).first {
            let mutableAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? mutableAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: audioTrack.timeRange.duration), of: audioTrack, at: .zero)
        }

        return (composition, videoComposition)
    }
}

private enum AssetExportError: Error {
    case videoLengthLimitExceeded
    case videoAssetExportFailed
    case assetMissingVideoTrack
    case unexpectedAssetType
}

extension MediaLibraryGroup {

    @objc(getMediaLibraryCountForMediaTypes:ofBlog:success:failure:)
    func getMediaLibraryCount(forMediaTypes types: Set<NSNumber>, of blog: Blog, success: @escaping (Int) -> Void, failure: @escaping (Error) -> Void) {
        guard let remote = MediaServiceRemoteFactory().remote(for: blog) else {
            DispatchQueue.main.async {
                failure(MediaRepository.Error.remoteAPIUnavailable)
            }
            return
        }

        let mediaTypes = types.compactMap {
            MediaType(rawValue: $0.uintValue)
        }

        Task { @MainActor in
            do {
                let total = try await remote.getMediaLibraryCount(forMediaTypes: mediaTypes)
                success(total)
            } catch {
                failure(error)
            }
        }
    }

}
