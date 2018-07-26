import WordPressFlux

@objc
open class QuickStartTourGuide: NSObject, UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        switch viewController {
        case is StatsViewController:
            dismissTestQuickStartNotice()
        default:
            break
        }
    }

    // MARK: Quick Start methods
    @objc
    func showTestQuickStartNotice() {
        let notice = Notice(title: "Test Quick Start Notice", message: "Tap stats to dismiss this example message.", style: .quickStart)
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
