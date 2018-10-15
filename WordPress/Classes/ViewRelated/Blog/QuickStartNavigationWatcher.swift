@objc
class QuickStartNavigationWatcher: NSObject, UINavigationControllerDelegate {
    private weak var readerNav: UINavigationController?
    private var spotlightView: QuickStartSpotlightView?

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {


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
            removeReaderSpotlight()
        case is ReaderSearchViewController:
            tourGuide.visited(.readerSearch)
            fallthrough
        case is ReaderStreamViewController, is ReaderSavedPostsViewController:
            tourGuide.readerNeedsBack = true
            readerNav = navigationController
        default:
            break
        }
    }

    func spotlightReaderBackButton() {
        guard let readerNav = readerNav else {
            return
        }

        let newSpotlightView = QuickStartSpotlightView()
        newSpotlightView.translatesAutoresizingMaskIntoConstraints = false
        readerNav.navigationBar.addSubview(newSpotlightView)
        readerNav.navigationBar.addConstraints([
                newSpotlightView.leadingAnchor.constraint(equalTo: readerNav.navigationBar.leadingAnchor, constant: 30.0),
                newSpotlightView.topAnchor.constraint(equalTo: readerNav.navigationBar.topAnchor, constant: 15.0),
            ])
        spotlightView = newSpotlightView
    }

    private func removeReaderSpotlight() {
        guard let spotlight = spotlightView else {
            return
        }

        spotlight.removeFromSuperview()
        spotlightView = nil
    }
}
