import UIKit
import SwiftUI

final class DashboardGoogleDomainsCardCell: DashboardCollectionViewCell {
    private let frameView = BlogDashboardCardFrameView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        // TODO: Implement update configuration
    }

    private func setupView() {
        let hostingController = UIHostingController(rootView: DashboardGoogleDomainsCardView())
        guard let cardView = hostingController.view else {
            return
        }

        frameView.setTitle(Strings.cardTitle)
        frameView.add(subview: cardView)
        frameView.onEllipsisButtonTap = { }
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        // TODO: Assign menu
        // frameView.ellipsisButton.menu = contextMenu

        cardView.backgroundColor = .clear
        frameView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(frameView)
        contentView.pinSubviewToAllEdges(frameView, priority: .defaultHigh)
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
