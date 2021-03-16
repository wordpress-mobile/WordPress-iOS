import Kanvas

/// Handles basic `CameraControllerDelegate` methods and calls `createdMedia` on export.
class CameraHandler: CameraControllerDelegate {

    let createdMedia: (CameraController.MediaOutput) -> Void

    init(created: @escaping (CameraController.MediaOutput) -> Void) {
        createdMedia = created
    }

    func getQuickPostButton() -> UIView {
        return UIView()
    }

    func getBlogSwitcher() -> UIView {
        return UIView()
    }

    func didCreateMedia(_ cameraController: CameraController, media: CameraController.MediaOutput, exportAction: KanvasExportAction) {
        createdMedia(media)
    }

    private func showDiscardAlert(on: UIViewController, discard: @escaping () -> Void) {
        let title = NSLocalizedString("You have unsaved changes.", comment: "Title of message with options that shown when there are unsaved changes and the author is trying to move away from the post.")
        let cancelTitle = NSLocalizedString("Keep Editing", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")
        let discardTitle = NSLocalizedString("Discard", comment: "Button shown if there are unsaved changes and the author is trying to move away from the post.")

        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.view.accessibilityIdentifier = "post-has-changes-alert"

        // Button: Keep editing
        alertController.addCancelActionWithTitle(cancelTitle)

        alertController.addDestructiveActionWithTitle(discardTitle) { _ in
            discard()
        }

        on.present(alertController, animated: true, completion: nil)
    }

    private func endEditing(editor: StoryEditor, onDismiss: @escaping () -> Void) {
        showDiscardAlert(on: editor.topmostPresentedViewController) {
            if editor.presentingViewController is AztecNavigationController == false {
                editor.cancelEditing()
                editor.post.managedObjectContext?.delete(editor.post)
            }
            onDismiss()
        }
    }

    func dismissButtonPressed(_ cameraController: CameraController) {
        if let editor = cameraController as? StoryEditor {
            endEditing(editor: editor) {
                cameraController.dismiss(animated: true, completion: nil)
            }
        } else {
            cameraController.dismiss(animated: true, completion: nil)
        }
    }

    func tagButtonPressed() {

    }

    func editorDismissed(_ cameraController: CameraController) {
        if let editor = cameraController as? StoryEditor {
            endEditing(editor: editor) {
                cameraController.dismiss(animated: true, completion: {
                    cameraController.dismiss(animated: false)
                })
            }
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
