@objc
class QuickStartNavigationWatcher: NSObject, UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }

        switch viewController {
        case is QuickStartChecklistViewController:
            tourGuide.visited(.checklist)
        case is BlogListViewController:
            tourGuide.visited(.noSuchElement)
            tourGuide.endCurrentTour()
        case is ThemeBrowserViewController:
            tourGuide.visited(.themes)
        case is SharingViewController:
            tourGuide.visited(.sharing)
        case is ReaderMenuViewController:
            tourGuide.visited(.readerBack)
            tourGuide.readerNeedsBack = false
        case is ReaderSearchViewController:
            tourGuide.visited(.readerSearch)
            fallthrough
        case is ReaderStreamViewController, is ReaderSavedPostsViewController:
            tourGuide.readerNeedsBack = true
        default:
            break
        }
    }
}
