
class AnnouncementCell: UITableViewCell {

    // MARK: - View elements
    private lazy var headingLabel: UILabel = {
        return makeLabel(font: Appearance.headingFont)
    }()

    private lazy var subHeadingLabel: UILabel = {
        return makeLabel(font: Appearance.subHeadingFont, color: .textSubtle)
    }()

    private lazy var descriptionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headingLabel, subHeadingLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var announcementImageView: UIImageView = {
        return UIImageView()
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [announcementImageView, descriptionStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.setCustomSpacing(Appearance.imageTextSpacing, after: announcementImageView)
        return stackView
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(mainStackView)
        contentView.pinSubviewToSafeArea(mainStackView, insets: Appearance.mainStackViewInsets)

        NSLayoutConstraint.activate([
            announcementImageView.heightAnchor.constraint(equalToConstant: Appearance.announcementImageSize),
            announcementImageView.widthAnchor.constraint(equalToConstant: Appearance.announcementImageSize)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(feature: WordPressKit.Feature) {
        if let url = URL(string: feature.iconUrl) {
            announcementImageView.af_setImage(withURL: url)
        }
        headingLabel.text = feature.title
        subHeadingLabel.text = feature.subtitle
        // TODO - WHATSNEW: - remove when images will be passed
        announcementImageView.backgroundColor = .accent
    }
}


// MARK: Helpers
private extension AnnouncementCell {

    func makeLabel(font: UIFont, color: UIColor? = nil) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = font
        if let color = color {
            label.textColor = color
        }
        return label
    }
}


// MARK: - Appearance
private extension AnnouncementCell {
    enum Appearance {
        // heading
        static let headingFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline), size: 17)

        // sub-heading
        static let subHeadingFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline), size: 15)

        // announcement image
        static let announcementImageSize: CGFloat = 48

        // main stack view
        static let imageTextSpacing: CGFloat = 16
        static let mainStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
    }
}
