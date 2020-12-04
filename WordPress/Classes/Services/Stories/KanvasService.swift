import Foundation
import KanvasCamera
import Photos

protocol CameraHandlerDelegate: class {
    func didCreateMedia(media: [(KanvasCameraMedia?, Error?)])
}

class KanvasService {
    weak var delegate: CameraHandlerDelegate?

    static var cameraSettings: CameraSettings {
        let settings = CameraSettings()
        settings.features.ghostFrame = true
        settings.features.metalPreview = true
        settings.features.metalFilters = true
        settings.features.openGLPreview = false
        settings.features.openGLCapture = false
        settings.features.cameraFilters = false
        settings.features.experimentalCameraFilters = true
        settings.features.editor = true
        settings.features.editorGIFMaker = false
        settings.features.editorFilters = false
        settings.features.editorText = true
        settings.features.editorMedia = true
        settings.features.editorDrawing = true
        settings.features.mediaPicking = true
        settings.features.editorPublishing = true
        settings.features.editorPostOptions = false
        settings.features.newCameraModes = true
        settings.features.gifs = false
        settings.features.multipleExports = true
        settings.crossIconInEditor = true
        settings.enabledModes = [.normal]
        settings.defaultMode = .normal
        settings.animateEditorControls = false
        settings.fontSelectorUsesFont = true
        settings.features.muteButton = true

        return settings
    }

    func controller(blog: Blog, context: NSManagedObjectContext, completion: @escaping (Result<Post, Error>) -> Void) -> StoryEditor {
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        return controller(post: post, publishOnCompletion: true, completion: completion)
    }

    func controller(post: AbstractPost, publishOnCompletion: Bool = false, completion: @escaping (Result<Post, Error>) -> Void) -> StoryEditor {
        KanvasCameraColors.shared = KanvasCameraCustomUI.shared.cameraColors()
        KanvasCameraFonts.shared = KanvasCameraCustomUI.shared.cameraFonts()
        let controller = StoryEditor(post: post,
                                     onClose: nil,
                                     settings: KanvasService.cameraSettings,
                                     stickerProvider: EmojiStickerProvider(),
                                     analyticsProvider: KanvasCameraAnalyticsStub(),
                                     quickBlogSelectorCoordinator: nil,
                                     tagCollection: nil,
                                     publishOnCompletion: publishOnCompletion,
                                     completion: completion)
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
        if let editor = cameraController as? StoryEditor {
            editor.cancelEditing()
        } else {
            cameraController.dismiss(animated: true, completion: nil)
        }
    }

    func tagButtonPressed() {

    }

    func editorDismissed(_ cameraController: CameraController) {
        if let editor = cameraController as? StoryEditor {
            editor.cancelEditing()
        }
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
