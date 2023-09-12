import UIKit
import SwiftUI

final class BlogDashboardPersonalizeCardCell: DashboardCollectionViewCell {
    private var blog: Blog?
    private weak var presentingViewController: BlogDashboardViewController?

    private let personalizeButton = UIButton(type: .system)

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
        let titleLabel = UILabel()
        titleLabel.text = Strings.buttonTitle
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true

        let imageView = UIImageView(image: UIImage(named: "personalize")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = .label

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true

        let contents = UIStackView(arrangedSubviews: [titleLabel, spacer, imageView])
        contents.alignment = .center
        contents.isUserInteractionEnabled = false

        personalizeButton.accessibilityLabel = Strings.buttonTitle
        personalizeButton.setBackgroundImage(.renderBackgroundImage(fill: .tertiarySystemFill), for: .normal)
        personalizeButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        let container = UIView()
        container.layer.cornerRadius = 10
        container.addSubview(personalizeButton)
        container.addSubview(contents)

        personalizeButton.translatesAutoresizingMaskIntoConstraints = false
        container.pinSubviewToAllEdges(personalizeButton)

        contents.translatesAutoresizingMaskIntoConstraints = false
        container.pinSubviewToAllEdges(contents, insets: .init(allEdges: 16))

        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(container)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        personalizeButton.setBackgroundImage(.renderBackgroundImage(fill: .tertiarySystemFill), for: .normal)
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        self.blog = blog
        self.presentingViewController = viewController
    }

    // MARK: - Actions

    @objc private func buttonTapped() {
        guard let blog = blog, let siteID = blog.dotComID?.intValue else {
            return DDLogError("Failed to show dashboard personalization screen: siteID is missing")
        }
        WPAnalytics.track(.dashboardCardItemTapped, properties: ["type": DashboardCard.personalize.rawValue], blog: blog)
        let viewController = UIHostingController(rootView: NavigationView {
            BlogDashboardPersonalizationView(viewModel: .init(blog: blog, service: .init(siteID: siteID), quickStartType: blog.quickStartType))
        }.navigationViewStyle(.stack)) // .stack is required for iPad
        if UIDevice.isPad() {
            viewController.modalPresentationStyle = .formSheet
        }
        presentingViewController?.present(viewController, animated: true)
    }
}

private extension BlogDashboardPersonalizeCardCell {
    struct Strings {
        static let buttonTitle = NSLocalizedString("dasboard.personalizeHomeButtonTitle", value: "Personalize your home tab", comment: "Personialize home tab button title")
    }
}
