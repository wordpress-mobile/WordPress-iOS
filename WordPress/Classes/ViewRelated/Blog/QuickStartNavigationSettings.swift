class QuickStartNavigationSettings: NSObject {
    func updateWith(navigationController: UINavigationController, andViewController viewController: UIViewController) {

        switch viewController {
        case is BlogListViewController:
            QuickStartTourGuide.shared.visited(.noSuchElement)
            QuickStartTourGuide.shared.endCurrentTour()
        default:
            break
        }
    }
}
