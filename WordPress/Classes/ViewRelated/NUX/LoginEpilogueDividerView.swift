import UIKit
import WordPressAuthenticator

final class LoginEpilogueDividerView: UIView {
    private let leadingDividerLine = UIView()
    private let trailingDividerLine = UIView()
    private let dividerLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Methods
private extension LoginEpilogueDividerView {
    func setupViews() {
        setupTitleLabel()
        setupLeadingDividerLine()
        setupTrailingDividerLine()
    }

    func setupTitleLabel() {
        dividerLabel.textColor = .divider
        dividerLabel.font = .preferredFont(forTextStyle: .footnote)
        dividerLabel.text = NSLocalizedString("Or", comment: "Divider on initial auth view separating auth options.").localizedUppercase
        dividerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerLabel)
        NSLayoutConstraint.activate([
            dividerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dividerLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupLeadingDividerLine() {
        leadingDividerLine.backgroundColor = .divider
        leadingDividerLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leadingDividerLine)
        NSLayoutConstraint.activate([
            leadingDividerLine.centerYAnchor.constraint(equalTo: dividerLabel.centerYAnchor),
            leadingDividerLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            leadingDividerLine.trailingAnchor.constraint(equalTo: dividerLabel.leadingAnchor, constant: -4),
            leadingDividerLine.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth)
        ])
    }

    func setupTrailingDividerLine() {
        trailingDividerLine.backgroundColor = .divider
        trailingDividerLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingDividerLine)
        NSLayoutConstraint.activate([
            trailingDividerLine.centerYAnchor.constraint(equalTo: dividerLabel.centerYAnchor),
            trailingDividerLine.leadingAnchor.constraint(equalTo: dividerLabel.trailingAnchor, constant: 4),
            trailingDividerLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingDividerLine.heightAnchor.constraint(equalToConstant: .hairlineBorderWidth)
        ])
    }
}
