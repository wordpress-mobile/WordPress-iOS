import WordPressFlux
import Gridicons

@objc
open class QuickStartTourGuide: NSObject, UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        switch viewController {
        case is QuickStartChecklistViewController:
            dismissTestQuickStartNotice()
        default:
            break
        }
    }

    // MARK: Quick Start methods
    @objc
    func showTestQuickStartNotice() {
        let exampleLabelStr = QuickStartNoticeView.makeHighlightMessage(base: "Tap %@ to see your checklist", highlight: "Quick Start", icon: Gridicon.iconOfType(.listCheckmark))
        let notice = Notice(title: "Test Quick Start Notice", style: .quickStart(exampleLabelStr))
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    private func findNoticePresenter() -> NoticePresenter? {
        return (UIApplication.shared.delegate as? WordPressAppDelegate)?.noticePresenter
    }

    func dismissTestQuickStartNotice() {
        guard let presenter = findNoticePresenter() else {
            return
        }

        presenter.dismissCurrentNotice()
    }

    static let checklistTours: [QuickStartTour] = [
        QuickStartCreateTour(),
        QuickStartViewTour(),
        QuickStartThemeTour(),
        QuickStartCustomizeTour(),
        QuickStartShareTour(),
        QuickStartPublishTour(),
        QuickStartFollowTour()
    ]
}
