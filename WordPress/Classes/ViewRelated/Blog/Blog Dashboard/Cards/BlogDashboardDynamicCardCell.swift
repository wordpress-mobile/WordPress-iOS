import UIKit
import SwiftUI

final class BlogDashboardDynamicCardCell: DashboardCollectionViewCell {

    // MARK: - Views

    private let frameView = BlogDashboardCardFrameView()
    private weak var presentingViewController: UIViewController?
    private var hostingController: UIHostingController<DynamicDashboardCard>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupFrameView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardDynamicCardModel) {
        self.presentingViewController = viewController
        self.configureMoreButton(with: blog)

        if let title = model.payload.title {
            self.frameView.setTitle(title)
        }

        if let viewController {
            self.configureHostingController(with: model, parent: viewController)
        }
    }

    private func configureHostingController(with model: DashboardDynamicCardModel, parent: UIViewController) {
        let content = DynamicDashboardCard(model: model) {

        }

        if let hostingController {
            hostingController.rootView = content
        } else {
            let hostingController = DynamicDashboardCardViewController(rootView: content)
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.willMove(toParent: parent)
            parent.addChild(hostingController)
            self.frameView.add(subview: hostingController.view)
            hostingController.didMove(toParent: parent)
            self.hostingController = hostingController
        }

        self.hostingController?.view?.invalidateIntrinsicContentSize()
    }

    private func setupFrameView() {
//        self.frameView.ellipsisButton.showsMenuAsPrimaryAction = true
//        self.frameView.onEllipsisButtonTap = { }
//        self.frameView.onViewTap = { }
        self.frameView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(frameView)
        self.contentView.pinSubviewToAllEdges(frameView, priority: .defaultHigh)
    }

    private func configureMoreButton(with blog: Blog) {
//        self.frameView.addMoreMenu(
//            items:
//                [
//                    UIMenu(
//                        options: .displayInline,
//                        children: [
//                            BlogDashboardHelpers.makeHideCardAction(for: .googleDomains, blog: blog)
//                        ]
//                    )
//                ],
//            card: .googleDomains
//        )
    }
}

// MARK: - DynamicDashboardCard Extension

private extension DynamicDashboardCard {

    init(model: DashboardDynamicCardModel, callback: (() -> Void)?) {
        let payload = model.payload

        let featureImageURL = URL(string: payload.featuredImage ?? "")
        let rows = (payload.rows ?? []).map {
            Input.Row(
                title: $0.title,
                description: $0.description,
                imageURL: URL(string: $0.icon ?? "")
            )
        }
        let action: Input.Action? = {
            guard let title = payload.action, let callback else {
                return nil
            }
            return .init(title: title, callback: callback)
        }()

        let input = Input(featureImageURL: featureImageURL, rows: rows, action: action)
        self.init(input: input)
    }
}
