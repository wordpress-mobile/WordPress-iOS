import UIKit

final class DashboardActivityLogCardCell: DashboardCollectionViewCell {

    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    private func setupView() {
        // FIXME: setup view
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController

        // FIXME: configure card using api response
        // Expecting a list of type [Activity]
    }
}
