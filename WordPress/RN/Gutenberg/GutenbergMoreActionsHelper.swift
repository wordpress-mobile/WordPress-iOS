import Foundation

/// This class handles the "more" actions triggered by the top right
/// navigation bar button of Gutenberg editor.
class GutenbergMoreActionsHelper: NSObject {

    private enum ErrorCode: Int {
        case expectedSecondaryAction = 1
    }

    private let postEditorUtil: PostEditorUtil

    private var context: PostEditorViewControllerType {
        return postEditorUtil.context
    }

    private var post: AbstractPost {
        return context.post
    }

    private var postEditorStateContext: PostEditorStateContext {
        return context.postEditorStateContext
    }

    init(postEditorUtil: PostEditorUtil) {
        self.postEditorUtil = postEditorUtil

        super.init()
    }

    func displayMoreSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        /*if mode == .richText {
            // NB : This is a candidate for plurality via .stringsdict, but is limited by https://github.com/wordpress-mobile/WordPress-iOS/issues/6327
            let textCounterTitle = String(format: NSLocalizedString("%li words, %li characters", comment: "Displays the number of words and characters in text"), richTextView.wordCount, richTextView.characterCount)
            
            alert.title = textCounterTitle
        }*/

        if postEditorStateContext.isSecondaryPublishButtonShown,
            let buttonTitle = postEditorStateContext.secondaryPublishButtonText {

            alert.addDefaultActionWithTitle(buttonTitle) { _ in
                self.secondaryPublishButtonTapped()
            }
        }

        /*let toggleModeTitle: String = {
            if mode == .richText {
                return MoreSheetAlert.htmlTitle
            } else {
                return MoreSheetAlert.richTitle
            }
        }()
        
        alert.addDefaultActionWithTitle(toggleModeTitle) { [unowned self] _ in
            self.toggleEditingMode()
        }*/
        /*
        alert.addDefaultActionWithTitle(MoreSheetAlert.previewTitle) { [unowned self] _ in
            self.displayPreview()
        }
 
        if Feature.enabled(.revisions) && (post.revisions ?? []).count > 0 {
            alert.addDefaultActionWithTitle(MoreSheetAlert.historyTitle) { [unowned self] _ in
                self.displayHistory()
            }
        }
        
        alert.addDefaultActionWithTitle(MoreSheetAlert.postSettingsTitle) { [unowned self] _ in
            self.displayPostSettings()
        }*/

        alert.addCancelActionWithTitle(MoreSheetAlert.keepEditingTitle)

        alert.popoverPresentationController?.barButtonItem = context.navigationBarManager.moreBarButtonItem

        context.present(alert, animated: true)
    }

    func secondaryPublishButtonTapped() {
        guard let action = self.postEditorStateContext.secondaryPublishButtonAction else {
            // If the user tapped on the secondary publish action button, it means we should have a secondary publish action.
            let error = NSError(domain: context.errorDomain, code: ErrorCode.expectedSecondaryAction.rawValue, userInfo: nil)
            Crashlytics.sharedInstance().recordError(error)
            return
        }

        let secondaryStat = self.postEditorStateContext.secondaryPublishActionAnalyticsStat

        let publishPostClosure = { [unowned self] in
            self.postEditorUtil.publishPost(
                action: action,
                dismissWhenDone: action.dismissesEditor,
                analyticsStat: secondaryStat)
        }

        if context.presentedViewController != nil {
            context.dismiss(animated: true, completion: publishPostClosure)
        } else {
            publishPostClosure()
        }
    }
}

extension GutenbergMoreActionsHelper {
    private struct MoreSheetAlert {
        static let htmlTitle = NSLocalizedString("Switch to HTML Mode", comment: "Switches the Editor to HTML Mode")
        static let richTitle = NSLocalizedString("Switch to Visual Mode", comment: "Switches the Editor to Rich Text Mode")
        static let previewTitle = NSLocalizedString("Preview", comment: "Displays the Post Preview Interface")
        static let historyTitle = NSLocalizedString("History", comment: "Displays the History screen from the editor's alert sheet")
        static let postSettingsTitle = NSLocalizedString("Post Settings", comment: "Name of the button to open the post settings")
        static let keepEditingTitle = NSLocalizedString("Keep Editing", comment: "Goes back to editing the post.")
    }
}
