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
        default:
            break
        }
    }
}
