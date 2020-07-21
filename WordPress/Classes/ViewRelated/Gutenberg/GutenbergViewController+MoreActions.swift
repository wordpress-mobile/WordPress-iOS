import Foundation
import AutomatticTracks

/// This extension handles the "more" actions triggered by the top right
/// navigation bar button of Gutenberg editor.
extension GutenbergViewController {

    private enum ErrorCode: Int {
        case expectedSecondaryAction = 1
    }

    func displayMoreSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if mode == .richText, let contentInfo = contentInfo {
            // NB : This is a candidate for plurality via .stringsdict, but is limited by https://github.com/wordpress-mobile/WordPress-iOS/issues/6327
            let textCounterTitle = String(format: NSLocalizedString("Content Structure\nBlocks: %li, Words: %li, Characters: %li", comment: "Displays the number of blocks, words and characters in text"), contentInfo.blockCount, contentInfo.wordCount, contentInfo.characterCount)

            alert.title = textCounterTitle
        }

        if postEditorStateContext.isSecondaryPublishButtonShown,
            let buttonTitle = postEditorStateContext.secondaryPublishButtonText {

            alert.addDefaultActionWithTitle(buttonTitle) { _ in
                self.secondaryPublishButtonTapped()
            }
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.classicTitle) { [unowned self] _ in
            self.savePostEditsAndSwitchToAztec()
        }

        let toggleModeTitle: String = {
            if mode == .richText {
                return MoreSheetAlert.htmlTitle
            } else {
                return MoreSheetAlert.richTitle
            }
        }()

        alert.addDefaultActionWithTitle(toggleModeTitle) { [unowned self] _ in
            self.toggleEditingMode()
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.previewTitle) { [weak self] _ in
            self?.displayPreview()
        }

        if (post.revisions ?? []).count > 0 {
            alert.addDefaultActionWithTitle(MoreSheetAlert.historyTitle) { [weak self] _ in
                self?.displayHistory()
            }
        }

        alert.addDefaultActionWithTitle(MoreSheetAlert.postSettingsTitle) { [weak self] _ in
            self?.displayPostSettings()
        }

        alert.addCancelActionWithTitle(MoreSheetAlert.keepEditingTitle)

        if #available(iOS 14.0, *),
            let button = navigationBarManager.moreBarButtonItem.customView {
            // Required to work around an issue present in iOS 14 beta 2
            // https://github.com/wordpress-mobile/WordPress-iOS/issues/14460
            alert.popoverPresentationController?.sourceRect = button.convert(button.bounds, to: navigationController?.navigationBar)
            alert.popoverPresentationController?.sourceView = navigationController?.navigationBar
            alert.view.accessibilityIdentifier = MoreSheetAlert.accessibilityIdentifier
        } else {
            alert.popoverPresentationController?.barButtonItem = navigationBarManager.moreBarButtonItem
        }

        present(alert, animated: true)
    }

    func secondaryPublishButtonTapped() {
        guard let action = self.postEditorStateContext.secondaryPublishButtonAction else {
            // If the user tapped on the secondary publish action button, it means we should have a secondary publish action.
            let error = NSError(domain: errorDomain, code: ErrorCode.expectedSecondaryAction.rawValue, userInfo: nil)
            CrashLogging.logError(error)
            return
        }

        let secondaryStat = self.postEditorStateContext.secondaryPublishActionAnalyticsStat

        let publishPostClosure = { [unowned self] in
            self.publishPost(
                action: action,
                dismissWhenDone: action.dismissesEditor,
                analyticsStat: secondaryStat)
        }

        if presentedViewController != nil {
            dismiss(animated: true, completion: publishPostClosure)
        } else {
            publishPostClosure()
        }
    }
}

// MARK: - Constants

extension GutenbergViewController {
    struct MoreSheetAlert {
        static let classicTitle = NSLocalizedString(
            "Switch to classic editor",
            comment: "Switches from Gutenberg mobile to the classic editor"
        )
        static let htmlTitle = NSLocalizedString("Switch to HTML Mode", comment: "Switches the Editor to HTML Mode")
        static let richTitle = NSLocalizedString("Switch to Visual Mode", comment: "Switches the Editor to Rich Text Mode")
        static let previewTitle = NSLocalizedString("Preview", comment: "Displays the Post Preview Interface")
        static let historyTitle = NSLocalizedString("History", comment: "Displays the History screen from the editor's alert sheet")
        static let postSettingsTitle = NSLocalizedString("Post Settings", comment: "Name of the button to open the post settings")
        static let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Goes back to editing the post.")
        static let accessibilityIdentifier = "MoreSheetAccessibilityIdentifier"
    }
}
