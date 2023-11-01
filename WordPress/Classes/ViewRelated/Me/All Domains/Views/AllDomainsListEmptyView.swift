import UIKit
import WordPressUI

final class AllDomainsListEmptyView: UIView {

    typealias ViewModel = AllDomainsListEmptyStateViewModel

    private enum Appearance {
        static let labelsSpacing: CGFloat = Length.Padding.single
        static let labelsButtonSpacing: CGFloat = Length.Padding.medium
        static let titleLabelFont: UIFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
        static let descriptionLabelFont: UIFont = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        static let buttonLabelFont: UIFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let titleLabelColor: UIColor? = UIColor.DS.Foreground.secondary
        static let descriptionLabelColor: UIColor? = UIColor.DS.Foreground.secondary
    }

    // MARK: - Actions

    private var buttonAction: (() -> Void)?

    // MARK: - Views

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = Appearance.titleLabelFont
        label.textColor = Appearance.titleLabelColor
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = Appearance.descriptionLabelFont
        label.textColor = Appearance.descriptionLabelColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let button: UIButton = {
        let button = FancyButton()
        button.titleLabel?.font = Appearance.buttonLabelFont
        button.isPrimary = true
        return button
    }()

    // MARK: - Init

    init(viewModel: ViewModel? = nil) {
        super.init(frame: .zero)
        self.render(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Rendering

    private func render(with viewModel: ViewModel?) {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, button])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Appearance.labelsSpacing
        stackView.setCustomSpacing(Appearance.labelsButtonSpacing, after: descriptionLabel)
        self.addSubview(stackView)
        self.pinSubviewToAllEdges(stackView)
        self.button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.update(with: viewModel)
    }

    func update(with viewModel: ViewModel?) {
        self.titleLabel.text = viewModel?.title
        self.descriptionLabel.text = viewModel?.description
        self.button.setTitle(viewModel?.button.title, for: .normal)
        self.buttonAction = viewModel?.button.action
    }

    // MARK: - User Interaction

    @objc private func didTapButton() {
        self.buttonAction?()
    }
}
