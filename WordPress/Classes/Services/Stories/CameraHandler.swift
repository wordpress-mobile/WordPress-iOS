import Kanvas

class CameraHandler: CameraControllerDelegate {

    let createdMedia: ([Result<KanvasMedia?, Error>]) -> Void

    init(created: @escaping ([Result<KanvasMedia?, Error>]) -> Void) {
        createdMedia = created
    }

    func getQuickPostButton() -> UIView {
        return UIView()
    }

    func getBlogSwitcher() -> UIView {
        return UIView()
    }

    func didCreateMedia(_ cameraController: CameraController, media: [Result<KanvasMedia?, Error>], exportAction: KanvasExportAction) {
        createdMedia(media)
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
        if let targetURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(targetURL)
        } else {
            assertionFailure("Couldn't unwrap Settings URL")
        }
    }
}
