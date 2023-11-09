import UIKit
import SwiftUI

protocol DashboardGoogleDomainsCardCellProtocol: AnyObject {
    func presentGoogleDomainsWebView(with url: URL)
}

final class DashboardGoogleDomainsCardCell: DashboardCollectionViewCell {
    private let frameView = BlogDashboardCardFrameView()
    private weak var presentingViewController: UIViewController?
    private var didConfigureHostingController = false

    var viewModel: DashboardGoogleDomainsViewModel?

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
            self.viewModel = DashboardGoogleDomainsViewModel()
            self.viewModel?.cell = self

            let hostingController = UIHostingController(rootView: DashboardGoogleDomainsCardView(buttonAction: { [weak self] in
                self?.viewModel?.didTapTransferDomains()
            }))

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
            configureMoreButton(with: blog)

            viewModel?.didShowCard()

            didConfigureHostingController = true
        }
    }

    private func setupFrameView() {
        frameView.setTitle(Strings.cardTitle)
        frameView.onEllipsisButtonTap = { [weak self] in
            self?.viewModel?.didTapMore()
        }
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.onViewTap = { [weak self] in
            guard let self else {
                return
            }

            self.viewModel?.didTapTransferDomains()
        }
    }

    private func configureMoreButton(with blog: Blog) {
        frameView.addMoreMenu(
            items:
                [
                    UIMenu(
                        options: .displayInline,
                        children: [
                            BlogDashboardHelpers.makeHideCardAction(for: .googleDomains, blog: blog)
                        ]
                    )
                ],
            card: .googleDomains
        )
    }
}

extension DashboardGoogleDomainsCardCell: DashboardGoogleDomainsCardCellProtocol {
    func presentGoogleDomainsWebView(with url: URL) {
        // TODO: Use `TransferDomainsWebViewController` instead.
        let webViewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(
            url: url,
            source: "domain_focus_card"
        )
        let navController = UINavigationController(rootViewController: webViewController)
        presentingViewController?.present(navController, animated: true)
    }
}

private extension DashboardGoogleDomainsCardCell {
    enum Strings {
        static let cardTitle = NSLocalizedString(
            "mySite.domain.focus.cardCell.title",
            value: "News",
            comment: "Title for the domain focus card on My Site"
        )
    }
}
