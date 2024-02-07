//
//  GravatarInfoRow.swift
//  WordPress
//
//  Created by Pinar Olguc on 6.02.2024.
//  Copyright © 2024 WordPress. All rights reserved.
//

import Foundation
import WordPressShared
import DesignSystem

struct GravatarInfoRow: ImmuTableRow {
    var action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? GravatarInfoCell else { return }
        cell.applyColors()
        cell.selectionStyle = .none
    }

    static let cell = ImmuTableCell.class(GravatarInfoCell.self)
}

class GravatarInfoCell: WPTableViewCellDefault {

    private enum Constants {
        static let appLogo: UIImage? = AppConfiguration.isJetpack ? UIImage(named: "jetpack-circular") : UIImage(named: "wordpress-circular")
        static let gravatarLogo: UIImage? = UIImage(named: "gravatar-circular")
        static let externalLinkLogo: UIImage? = UIImage(named: "icon-post-actionbar-view")?.withRenderingMode(.alwaysTemplate)
        static let infoText = NSLocalizedString("Gravatar keeps your profile information safe and up to date, automatically syncing any updates made here with your Gravatar profile.", comment: "This text is shown in the profile editing page to let the user know about Gravatar.")
        static let linkText = NSLocalizedString("Learn more on Gravatar.com", comment: "This is a link that takes the user to the external Gravatar website")
        static let cardCornerRadius: CGFloat = Length.Radius.medium
        static let font = TextStyle.caption.uiFont
        static let gravatarLink = "https://gravatar.com"
    }

    private var infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Constants.font
        label.text = Constants.infoText
        label.numberOfLines = 0
        return label
    }()

    private var linkTextView: UITextView = {
        let text = UITextView()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.isUserInteractionEnabled = true
        text.isEditable = false
        text.isScrollEnabled = false
        text.isSelectable = true
        text.backgroundColor = .clear
        text.textContainerInset = .zero
        text.textContainer.lineFragmentPadding = 0
        text.textDragInteraction?.isEnabled = false
        return text
    }()

    private var logosView: GravatarInterceptingLogosView = {
        let view = GravatarInterceptingLogosView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [logosView, infoLabel, linkTextView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Length.Padding.split
        stackView.alignment = .leading
        return stackView
    }()

    private lazy var cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verticalStackView)
        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Length.Padding.double),
            verticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Length.Padding.double),
            verticalStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Length.Padding.double),
            verticalStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Length.Padding.double),
        ])
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        applyColors()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyColors() {
        infoLabel.textColor = UIColor.DS.Foreground.primary
        linkTextView.tintColor = UIColor.primary

        let infoText = NSMutableAttributedString(string: Constants.linkText,
                                                             attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                          .font: Constants.font
                                                                         ])
        if let linkImage = Constants.externalLinkLogo {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = linkImage
            imageAttachment.bounds = CGRect(x: 0, y: (Constants.font.capHeight - linkImage.size.height).rounded() / 2, width: linkImage.size.width, height: linkImage.size.height)

            let imageString = NSAttributedString(attachment: imageAttachment)
            infoText.append(NSAttributedString(string: " "))
            infoText.append(imageString)
        }

        infoText.addAttributes([.link: Constants.gravatarLink], range: NSRange(location: 0, length: infoText.length))
        linkTextView.attributedText = infoText
    }
}
