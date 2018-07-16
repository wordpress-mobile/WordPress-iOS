import WordPressFlux

class BlogNavigationController: UINavigationController {

    // MARK: Quick Start methods
    @objc
    func showTestQuickStartNotice() {
        let notice = Notice(title: "Test Quick Start Notice", message: "Quick start tour notices will look similar to this", style: .quickStart)
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}
