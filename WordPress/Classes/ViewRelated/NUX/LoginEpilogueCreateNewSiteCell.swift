import UIKit
import WordPressUI

protocol LoginEpilogueCreateNewSiteCellDelegate: AnyObject {
    func didTapCreateNewSite()
}

final class LoginEpilogueCreateNewSiteCell: UITableViewCell {
    private let dividerView = LoginEpilogueDividerView()
    private let createNewSiteButton = FancyButton()
    weak var delegate: LoginEpilogueCreateNewSiteCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Methods
private extension LoginEpilogueCreateNewSiteCell {
    func setupViews() {
        selectionStyle = .none
        setupDividerView()
        setupCreateNewSiteButton()
    }

    func setupDividerView() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dividerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.dividerViewTopMargin),
            dividerView.heightAnchor.constraint(equalToConstant: Constants.dividerViewHeight)
        ])
    }

    func setupCreateNewSiteButton() {
        createNewSiteButton.setTitle(NSLocalizedString("Create a new site", comment: "A button title"), for: .normal)
        createNewSiteButton.accessibilityIdentifier = "Create a new site"
        createNewSiteButton.isPrimary = false
        createNewSiteButton.addTarget(self, action: #selector(didTapCreateNewSiteButton), for: .touchUpInside)
        createNewSiteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(createNewSiteButton)
        NSLayoutConstraint.activate([
            createNewSiteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.createNewSiteButtonHorizontalMargin),
            createNewSiteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.createNewSiteButtonHorizontalMargin),
            createNewSiteButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor),
            createNewSiteButton.heightAnchor.constraint(equalToConstant: Constants.createNewSiteButtonHeight),
            createNewSiteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @objc func didTapCreateNewSiteButton() {
        delegate?.didTapCreateNewSite()
    }

    private enum Constants {
        static let dividerViewTopMargin: CGFloat = 20.0
        static let dividerViewHeight: CGFloat = 48.0
        static let createNewSiteButtonHorizontalMargin: CGFloat = 20.0
        static let createNewSiteButtonHeight: CGFloat = 44.0
    }
}
