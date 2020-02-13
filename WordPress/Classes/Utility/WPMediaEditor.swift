import Foundation
import MediaEditor
import Gridicons

/**
 Displays the Media Editor with our custom styles and tracking
 */
class WPMediaEditor: MediaEditor {
    var alreadyPublishedImage: Bool = false {
        didSet {
            if alreadyPublishedImage {
                hub.doneButton.setTitle(Constants.doneLabel, for: .normal)
            }
        }
    }

    override var styles: MediaEditorStyles {
        get {
            return [
                .insertLabel: NSLocalizedString("Insert %@", comment: "Button title used in media editor. Placeholder will be the number of items that will be inserted."),
                .doneLabel: Constants.doneLabel,
                .cancelLabel: NSLocalizedString("Cancel", comment: "Cancel editing an image"),
                .errorLoadingImageMessage: NSLocalizedString("We couldn't retrieve this media.\nPlease tap to retry.", comment: "Description that appears when a media fails to load in the Media Editor."),
                .cancelColor: UIColor.white,
                .resetIcon: Gridicon.iconOfType(.undo),
                .doneIcon: Gridicon.iconOfType(.checkmark),
                .cancelIcon: Gridicon.iconOfType(.cross),
                .rotateClockwiseIcon: Gridicon.iconOfType(.rotate).withHorizontallyFlippedOrientation(),
                .rotateCounterclockwiseButtonHidden: true,
                .retryIcon: Gridicon.iconOfType(.refresh, withSize: CGSize(width: 48, height: 48))
            ]
        }

        set {
            // noop
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WPAnalytics.track(.mediaEditorShown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        trackUsage()
    }

    private func trackUsage() {
        guard !actions.isEmpty else {
            return
        }

        WPAnalytics.track(.mediaEditorUsed, withProperties: ["actions": actions.description])
    }

    private enum Constants {
        static var doneLabel = NSLocalizedString("Done", comment: "Done editing an image")
    }
}
