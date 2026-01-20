import UIKit
import WordPressData

class DashboardExtensionLoggingCardCell: UICollectionViewCell, Reusable {

    private lazy var cardView: DashboardExtensionLoggingCardView = {
        let view = DashboardExtensionLoggingCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private weak var presenterViewController: BlogDashboardViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: UILayoutPriority(999))

        cardView.onTurnOffTapped = { [weak self] in
            self?.handleTurnOffTapped()
        }
    }

    private func handleTurnOffTapped() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.presenterViewController?.reloadCardsLocally(animated: true)
        }
    }
}

extension DashboardExtensionLoggingCardCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.presenterViewController = viewController
    }
}
