import Foundation
import Kanvas
import Photos

protocol CameraHandlerDelegate: class {
    func didCreateMedia(media: [(KanvasCameraMedia?, Error?)])
}

class KanvasService {
    weak var delegate: CameraHandlerDelegate?

    var cameraSettings: CameraSettings {
        let settings = CameraSettings()
        settings.features.ghostFrame = true
//        settings.features.metalPreview = true
//        settings.features.metalFilters = true
        settings.features.openGLPreview = true
        settings.features.openGLCapture = true
        settings.features.cameraFilters = true
        settings.features.experimentalCameraFilters = true
        settings.features.editor = true
        settings.features.editorGIFMaker = true
        settings.features.editorFilters = true
        settings.features.editorText = true
        settings.features.editorMedia = true
        settings.features.editorDrawing = true
        settings.features.mediaPicking = true
        settings.features.editorPosting = true
        settings.features.editorSaving = true
        settings.features.editorPostOptions = false
        settings.features.newCameraModes = true
        settings.features.gifs = true
//        settings.features.multipleExports = true
        settings.enabledModes = [.photo, .normal]
        settings.defaultMode = .photo
        return settings
    }

    func controller() -> CameraController {
        let controller = CameraController(settings: cameraSettings, stickerProvider: ExperimentalStickerProvider(), analyticsProvider: KanvasCameraAnalyticsStub(), quickBlogSelectorCoordinator: nil)
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        return controller
    }
}

extension KanvasService: CameraControllerDelegate {
    func didCreateMedia(_ cameraController: CameraController, media: [(KanvasCameraMedia?, Error?)], exportAction: KanvasExportAction) {
        delegate?.didCreateMedia(media: media)
    }

    func dismissButtonPressed(_ cameraController: CameraController) {
        cameraController.dismiss(animated: true, completion: nil)
    }

    func tagButtonPressed() {

    }

    func editorDismissed() {
    }

    func didDismissWelcomeTooltip() {

    }

    func cameraShouldShowWelcomeTooltip() -> Bool {
        return false
    }

    func didDismissColorSelectorTooltip() {

    }

    func editorShouldShowColorSelectorTooltip() -> Bool {
        return true
    }

    func didEndStrokeSelectorAnimation() {

    }

    func editorShouldShowStrokeSelectorAnimation() -> Bool {
        return true
    }

    func provideMediaPickerThumbnail(targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {

        PHPhotoLibrary.requestAuthorization { status in
            completion(nil)
        }
    }

    func didBeginDragInteraction() {

    }

    func didEndDragInteraction() {

    }

    func openAppSettings(completion: ((Bool) -> ())?) {

    }
}
