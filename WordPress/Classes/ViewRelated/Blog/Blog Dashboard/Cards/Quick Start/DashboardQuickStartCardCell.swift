import UIKit

final class DashboardQuickStartCardCell: UICollectionViewCell, Reusable, BlogDashboardCardConfigurable {

    private var onTapCustomize: (() -> Void)?
    private var onTapGrow: (() -> Void)?

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.title = Strings.nextSteps
        frameView.icon = UIImage.gridicon(.listOrdered, size: Metrics.iconSize)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        return frameView
    }()

    // FIXME: temporary placeholder view -- will refine design later
    private lazy var customizeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Customize Your Site", for: .normal)
        button.addTarget(self, action: #selector(didTapCustomizeButton), for: .touchUpInside)
        return button
    }()

    // FIXME: temporary place holder view -- will refine design later
    private lazy var growButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Grow Your Audience", for: .normal)
        button.addTarget(self, action: #selector(didTapGrowButton), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController = viewController else {
            return
        }

        onTapCustomize = { [weak self] in
            self?.showQuickStart(with: .customize, from: viewController, for: blog)
        }

        onTapGrow = { [weak self] in
            self?.showQuickStart(with: .grow, from: viewController, for: blog)
        }
    }

    private func setupViews() {
        contentView.addSubview(cardFrameView)
        contentView.pinSubviewToAllEdges(cardFrameView)

        cardFrameView.add(subview: customizeButton)
        cardFrameView.add(subview: growButton)
    }

}

// MARK: - Actions

extension DashboardQuickStartCardCell {

    @objc private func didTapCustomizeButton() {
        onTapCustomize?()
    }

    @objc private func didTapGrowButton() {
        onTapGrow?()
    }

    private func showQuickStart(with type: QuickStartType, from sourceController: UIViewController, for blog: Blog) {
        let checklist = QuickStartChecklistViewController(blog: blog, type: type)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        sourceController.present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)
    }
}

// MARK: - Constants

extension DashboardQuickStartCardCell {

    private enum Strings {
        static let nextSteps = NSLocalizedString("Next Steps", comment: "Title for the Quick Start dashboard card.")
    }

    private enum Metrics {
        static let iconSize = CGSize(width: 18, height: 18)
    }
}
