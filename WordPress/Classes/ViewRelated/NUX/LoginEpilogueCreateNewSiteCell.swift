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
//        selectionStyle = .none
        setupDividerView()
        setupCreateNewSiteButton()
        contentView.isUserInteractionEnabled = true
    }

    func setupDividerView() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            dividerView.heightAnchor.constraint(equalToConstant: 48)
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
            createNewSiteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            createNewSiteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            createNewSiteButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor),
            createNewSiteButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    @objc func didTapCreateNewSiteButton() {
        delegate?.didTapCreateNewSite()
    }
}
