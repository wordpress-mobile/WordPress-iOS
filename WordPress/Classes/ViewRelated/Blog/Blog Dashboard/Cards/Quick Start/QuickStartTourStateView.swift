import UIKit

final class QuickStarTourStateView: UIView {

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            customizeChecklistView,
            growChecklistView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var customizeChecklistView: QuickStartChecklistView = {
        let view = QuickStartChecklistView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var growChecklistView: QuickStartChecklistView = {
        let view = QuickStartChecklistView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, sourceController: UIViewController) {

        customizeChecklistView.configure(
            tours: QuickStartTourGuide.shared.customizeListTours,
            blog: blog,
            title: Strings.customizeTitle,
            hint: Strings.customizeHint
        )

        customizeChecklistView.onTap = { [weak self] in
            self?.showQuickStart(with: .customize, from: sourceController, for: blog)
        }

        growChecklistView.configure(
            tours: QuickStartTourGuide.shared.growListTours,
            blog: blog,
            title: Strings.growTitle,
            hint: Strings.growHint
        )

        growChecklistView.onTap = { [weak self] in
            self?.showQuickStart(with: .grow, from: sourceController, for: blog)
        }
    }

}

// MARK: - Setup

extension QuickStarTourStateView {

    private func setupViews() {
        addSubview(stackView)
        pinSubviewToAllEdges(stackView)
    }
}

// MARK: - Actions

extension QuickStarTourStateView {

    private func showQuickStart(with type: QuickStartType, from sourceController: UIViewController, for blog: Blog) {
        let checklist = QuickStartChecklistViewController(blog: blog, type: type)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        sourceController.present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)
    }
}

// MARK: - Constants

extension QuickStarTourStateView {

    private enum Strings {
        static let customizeTitle = NSLocalizedString("Customize Your Site",
                                                      comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        static let customizeHint = NSLocalizedString("A series of steps showing you how to add a theme, site icon and more.",
                                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Customize Your Site' button.")
        static let growTitle = NSLocalizedString("Grow Your Audience",
                                                comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        static let growHint = NSLocalizedString("A series of steps to assist with growing your site's audience.",
                                                comment: "A VoiceOver hint to explain what the user gets when they select the 'Grow Your Audience' button.")
    }
}
