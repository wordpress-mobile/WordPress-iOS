import UIKit

class JetpackNewUsersOverlaySecondaryView: UIView {

    // MARK: Lazy Loading View

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.directionalLayoutMargins = Metrics.stackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews(featureRows)
        return stackView
    }()

    private lazy var featureRows: [UIView] = {
        return [statsDetailsRow, readerDetailsRow, notificationsDetailsRow]
    }()

    private lazy var statsDetailsRow: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    private lazy var readerDetailsRow: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    private lazy var notificationsDetailsRow: UIView = {
        let view = UIView()
        view.backgroundColor = .blue
        view.heightAnchor.constraint(equalToConstant: Metrics.rowHeight).isActive = true
        return view
    }()

    // MARK: Initializers

    init() {
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }

    // MARK: Helpers

    private func configureView() {
        addSubview(containerStackView)
        pinSubviewToAllEdges(containerStackView)
    }
}

private extension JetpackNewUsersOverlaySecondaryView {
    enum Metrics {
        static let stackViewSpacing: CGFloat = 30
        static let stackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 30, leading: 0, bottom: 0, trailing: 0)
        static let rowHeight: CGFloat = 60
    }

    enum Strings {

    }
}
