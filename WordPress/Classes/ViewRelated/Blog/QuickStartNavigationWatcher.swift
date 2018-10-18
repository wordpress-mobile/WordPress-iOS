@objc
class QuickStartNavigationWatcher: NSObject, UINavigationControllerDelegate {
    private weak var readerNav: UINavigationController?
    private var spotlightView: QuickStartSpotlightView?

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }

        switch viewController {
        case is BlogListViewController:
            tourGuide.visited(.noSuchElement)
            tourGuide.endCurrentTour()
        case is ReaderMenuViewController:
            tourGuide.visited(.readerBack)
            removeReaderSpotlight()
        case is ReaderSearchViewController, is ReaderStreamViewController, is ReaderSavedPostsViewController:
            readerNav = navigationController
            checkToSpotlightReader()
        default:
            break
        }
    }

    private func checkToSpotlightReader() {
        guard let tourGuide = QuickStartTourGuide.find(),
            tourGuide.isCurrentElement(.readerBack) else {
            return
        }

        spotlightReaderBackButton()
    }

    func spotlightReaderBackButton() {
        guard let readerNav = readerNav else {
            return
        }

        let newSpotlightView = QuickStartSpotlightView()
        newSpotlightView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11, *) {
            readerNav.navigationBar.addSubview(newSpotlightView)
            readerNav.navigationBar.addConstraints([
                    newSpotlightView.leadingAnchor.constraint(equalTo: readerNav.navigationBar.leadingAnchor, constant: 30.0),
                    newSpotlightView.topAnchor.constraint(equalTo: readerNav.navigationBar.topAnchor, constant: 15.0),
                ])
        } else {
            if let parentView = readerNav.navigationBar.window {
                parentView.addSubview(newSpotlightView)
                parentView.addConstraints([
                    newSpotlightView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 30.0),
                    newSpotlightView.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 15.0),
                    ])
            }
        }
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
