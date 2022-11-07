import UIKit
import WordPressUI

final class MigrationActionsView: UIView {

    // MARK: - Views

    let primaryButton: UIButton = MigrationActionsView.primaryButton()

    let secondaryButton: UIButton = MigrationActionsView.secondaryButton()

    private let visualEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.spacing
        return stackView
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        // Set properties
        self.directionalLayoutMargins = Constants.insets

        // Layout visual effect view
        self.addSubview(visualEffectView)
        self.pinSubviewToAllEdges(visualEffectView)

        // Layout separator view
        self.addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: Constants.separatorHeight)
        ])

        // Layout buttons
        self.stackView.addArrangedSubviews([primaryButton, secondaryButton])
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            primaryButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Button Factory

    private static func primaryButton() -> UIButton {
        let button = FancyButton()
        button.isPrimary = true
        return button
    }

    private static func secondaryButton() -> UIButton {
        let button = UIButton()
        let font = WPStyleGuide.fontForTextStyle(.headline)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.font = font
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }

    // MARK: - Configuring Intrinsic Size

    override var intrinsicContentSize: CGSize {
        return .init(width: UIView.noIntrinsicMetric, height: stackView.intrinsicContentSize.height)
    }

    // MARK: - Constants

    private struct Constants {
        static let separatorHeight = CGFloat(0.5)
        static let insets = NSDirectionalEdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30)
        static let spacing = CGFloat(10)
    }
}
