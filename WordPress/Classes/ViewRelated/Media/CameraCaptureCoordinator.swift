import MobileCoreServices

/// Encapsulates capturing media from a device camera
final class CameraCaptureCoordinator {
    private var capturePresenter: WPMediaCapturePresenter?

    func presentMediaCapture(origin: UIViewController, blog: Blog) {
        capturePresenter = WPMediaCapturePresenter(presenting: origin)
        capturePresenter!.completionBlock = { [weak self] mediaInfo in
            if let mediaInfo = mediaInfo as NSDictionary? {
                self?.processMediaCaptured(mediaInfo, blog: blog)
            }
            self?.capturePresenter = nil
        }

        capturePresenter!.presentCapture()
    }

    private func processMediaCaptured(_ mediaInfo: NSDictionary, blog: Blog) {
        let completionBlock: WPMediaAddedBlock = { media, error in
            if error != nil || media == nil {
                print("Adding media failed: ", error?.localizedDescription ?? "no media")
                return
            }
            guard let media = media as? PHAsset else {
                    return
            }

            let info = MediaAnalyticsInfo(origin: .mediaLibrary(.camera), selectionMethod: .fullScreenPicker)
            MediaCoordinator.shared.addMedia(from: media, to: blog, analyticsInfo: info)
        }

        guard let mediaType = mediaInfo[UIImagePickerController.InfoKey.mediaType.rawValue] as? String else { return }

        switch mediaType {
        case String(kUTTypeImage):
            if let image = mediaInfo[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage,
                let metadata = mediaInfo[UIImagePickerController.InfoKey.mediaMetadata.rawValue] as? [AnyHashable: Any] {
                WPPHAssetDataSource().add(image, metadata: metadata, completionBlock: completionBlock)
            }
        case String(kUTTypeMovie):
            if let mediaURL = mediaInfo[UIImagePickerController.InfoKey.mediaURL.rawValue] as? URL {
                WPPHAssetDataSource().addVideo(from: mediaURL, completionBlock: completionBlock)
            }
        default:
            break
        }
    }
}
