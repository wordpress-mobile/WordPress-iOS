import UIKit
import SwiftUI

final class DashboardGoogleDomainsCardCell: DashboardCollectionViewCell {
    private let frameView = BlogDashboardCardFrameView()
    private weak var presentingViewController: UIViewController?
    private var didConfigureHostingController = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFrameView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.presentingViewController = viewController

        if let presentingViewController, !didConfigureHostingController {
            let hostingController = UIHostingController(rootView: DashboardGoogleDomainsCardView())
            guard let cardView = hostingController.view else {
                return
            }

            frameView.add(subview: cardView)

            presentingViewController.addChild(hostingController)

            cardView.backgroundColor = .clear
            frameView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(frameView)
            contentView.pinSubviewToAllEdges(frameView, priority: .defaultHigh)
            hostingController.didMove(toParent: presentingViewController)
            didConfigureHostingController = true
        }
    }

    private func setupFrameView() {
        frameView.setTitle(Strings.cardTitle)
        frameView.onEllipsisButtonTap = { }
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        // TODO: Assign menu
        // frameView.ellipsisButton.menu = contextMenu
    }
}

private extension DashboardGoogleDomainsCardCell {
    enum Strings {
        static let cardTitle = NSLocalizedString(
            "mySite.domain.focus.card.title",
            value: "News",
            comment: "Title for the domain focus card on My Site"
        )
    }
}
