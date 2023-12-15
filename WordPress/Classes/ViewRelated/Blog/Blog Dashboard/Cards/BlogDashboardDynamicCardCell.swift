import UIKit

final class BlogDashboardDynamicCardCell: DashboardCollectionViewCell {
    private let frameView = BlogDashboardCardFrameView()
    private weak var presentingViewController: UIViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupFrameView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardDynamicCardModel) {
        self.presentingViewController = viewController
        self.configureMoreButton(with: blog)

        if let title = model.payload.title {
            self.frameView.setTitle(title)
        }
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
