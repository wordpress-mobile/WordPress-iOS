class QuickStartNavigationSettings: NSObject {
    private weak var readerNav: UINavigationController?
    private var spotlightView: QuickStartSpotlightView?

    func updateWith(navigationController: UINavigationController, andViewController viewController: UIViewController) {
        guard let tourGuide = QuickStartTourGuide.find() else {
            return
        }

        switch viewController {
        case is BlogListViewController:
            tourGuide.visited(.noSuchElement)
            tourGuide.endCurrentTour()
        default:
            break
        }
    }
}

private extension QuickStartNavigationSettings {

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

    func removeReaderSpotlight() {
        guard let spotlight = spotlightView else {
            return
        }

        spotlight.removeFromSuperview()
        spotlightView = nil
    }

}
