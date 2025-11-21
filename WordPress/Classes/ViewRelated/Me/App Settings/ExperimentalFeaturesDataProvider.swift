import Foundation
import WordPressUI
import UIKit
import SwiftUI

class ExperimentalFeaturesDataProvider: ExperimentalFeaturesViewModel.DataProvider {

    let flags: [OverridableFlag] = [
        FeatureFlag.intelligence,
        FeatureFlag.newStats,
        FeatureFlag.allowApplicationPasswords,
        RemoteFeatureFlag.newGutenberg,
        FeatureFlag.newSupport,
        FeatureFlag.pulse,
    ]

    private let flagStore = FeatureFlagOverrideStore()

    var notes: [String] {
        [Strings.editorNote]
    }

    func loadItems() throws -> [WordPressUI.Feature] {
        flags.map { flag in
            WordPressUI.Feature(
                name: flag.description,
                key: flag.key,
                isSuperExperimental: flag.key == FeatureFlag.pulse.key
            )
        }
    }

    func value(for feature: WordPressUI.Feature) -> Bool {
        let flag = flag(for: feature)
        return flagStore.overriddenValue(for: flag) ?? flag.originalValue
    }

    func didChangeValue(for feature: WordPressUI.Feature, to newValue: Bool) {
        flagStore.override(flag(for: feature), withValue: newValue)

        if feature.key == RemoteFeatureFlag.newGutenberg.key && !newValue {
            let alert = UIAlertController(title: Strings.editorFeedbackTitle, message: Strings.editorFeedbackMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.editorFeedbackDecline, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: Strings.editorFeedbackAccept, style: .default, handler: { _ in
                let feedbackViewController = SubmitFeedbackViewController(source: "experimental_features", feedbackPrefix: "Editor")
                self.presentViewController(feedbackViewController)
            }))

            self.presentViewController(alert)

            return
        }

        if feature.key == FeatureFlag.allowApplicationPasswords.key && newValue {
            let view = NavigationStack {
                ApplicationPasswordsInfoView()
            }
            self.presentViewController(UIHostingController(rootView: view))
            return
        }

        if feature.key == FeatureFlag.pulse.key && newValue {
            let alert = UIAlertController(title: Strings.pulseAlertTitle, message: Strings.pulseAlertMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.pulseAlertCancel, style: .cancel, handler: { _ in
                self.flagStore.override(self.flag(for: feature), withValue: false)
            }))
            alert.addAction(UIAlertAction(title: Strings.pulseAlertConfirm, style: .default, handler: { _ in
                fatalError("Restarting")
            }))

            self.presentViewController(alert)
            return
        }
    }

    private func flag(for feature: WordPressUI.Feature) -> OverridableFlag {
        guard let flag = flags.first(where: { $0.key == feature.key }) else {
            preconditionFailure("Invalid Feature Flag")
        }

        return flag
    }

    private func presentViewController(_ viewController: UIViewController) {
        DispatchQueue.main.async {
            if let windowScene = UIViewController.topViewController?.view.window?.windowScene,
               let topController = windowScene.windows.first?.rootViewController {
                topController.present(viewController, animated: true, completion: nil)
            }
        }
    }

    enum Strings {
        static let editorFeedbackTitle = NSLocalizedString("experimentalFeatures.editorFeedbackTitle", value: "Share Feedback", comment: "Title for the alert asking for feedback")
        static let editorFeedbackMessage = NSLocalizedString("experimentalFeatures.editorFeedbackMessage", value: "Are you willing to share feedback on the experimental editor?", comment: "Message for the alert asking for feedback on the experimental editor")
        static let editorFeedbackDecline = NSLocalizedString("experimentalFeatures.editorFeedbackDecline", value: "Not now", comment: "Dismiss button title for the alert asking for feedback")
        static let editorFeedbackAccept = NSLocalizedString("experimentalFeatures.editorFeedbackAccept", value: "Send feedback", comment: "Accept button title for the alert asking for feedback")
        static let editorNote = NSLocalizedString("experimentalFeatures.editorNote", value: "Experimental Block Editor will become the default in a future release and the ability to disable it will be removed.", comment: "Communicates the future removal of the option to disable the experimental editor, displayed beneath the experimental features list")

        static let pulseAlertTitle = NSLocalizedString("experimentalFeatures.pulse.alert.title", value: "Enable Pulse Logging?", comment: "Alert title when enabling Pulse logging feature")
        static let pulseAlertMessage = NSLocalizedString("experimentalFeatures.pulse.alert.message", value: "This will enable extensive local logging for debugging purposes and add a new Logger row in App Settings. This is not recommended unless you know what you're doing. The app will restart to apply changes.", comment: "Alert message explaining Pulse logging feature and warning users")
        static let pulseAlertConfirm = NSLocalizedString("experimentalFeatures.pulse.alert.confirm", value: "Apply & Restart", comment: "Button to confirm enabling Pulse logging and restart the app")
        static let pulseAlertCancel = NSLocalizedString("experimentalFeatures.pulse.alert.cancel", value: "Cancel", comment: "Button to cancel enabling Pulse logging")
    }
}
