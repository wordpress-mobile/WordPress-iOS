import UIKit

class DashboardCustomAnnouncementCell: AnnouncementTableViewCell {

    // MARK: - View elements
    private lazy var headingLabel: UILabel = {
        return makeLabel(font: Appearance.headingFont, color: .secondaryLabel)
    }()

    private lazy var headingLabelView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(headingLabel)
        view.pinSubviewToAllEdges(headingLabel, insets: Appearance.headingLabelInsets)
        return view
    }()

    private lazy var imageBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .quaternarySystemFill
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 10
        view.addSubview(announcementImageView)
        return view
    }()

    private lazy var announcementImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headingLabelView, imageBackgroundView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Appearance.imageTextSpacing
        return stackView
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(mainStackView)
        contentView.pinSubviewToSafeArea(mainStackView, insets: Appearance.mainStackViewInsets)


        NSLayoutConstraint.activate([
            imageBackgroundView.heightAnchor.constraint(equalToConstant: Appearance.announcementImageHeight),
            imageBackgroundView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            announcementImageView.topAnchor.constraint(equalTo: imageBackgroundView.topAnchor),
            announcementImageView.bottomAnchor.constraint(equalTo: imageBackgroundView.bottomAnchor),
            announcementImageView.centerXAnchor.constraint(equalTo: imageBackgroundView.centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the labels and image views using the data from a `WordPressKit.Feature` object.
    /// - Parameter feature: The `feature` containing the information to fill the cell with.
    func configure(feature: WordPressKit.Feature) {

        if let url = URL(string: feature.iconUrl) {
            announcementImageView.af_setImage(withURL: url, completion: { [weak self] response in

                guard let self,
                      let width = response.value?.size.width,
                      let height = response.value?.size.height else {
                    return
                }

                let aspectRatio = width / height

                NSLayoutConstraint.activate([
                    self.announcementImageView.widthAnchor.constraint(equalTo: self.announcementImageView.heightAnchor, multiplier: aspectRatio)
                ])
            })
        }
        headingLabel.text = feature.subtitle
    }
}


// MARK: Helpers
private extension DashboardCustomAnnouncementCell {

    func makeLabel(font: UIFont, color: UIColor? = nil) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = font
        label.textAlignment = .center
        if let color = color {
            label.textColor = color
        }
        return label
    }
}


// MARK: - Appearance
private extension DashboardCustomAnnouncementCell {
    enum Appearance {
        // heading
        static let headingFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body), size: 17)
        static let headingLabelInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        // announcement image
        static let announcementImageHeight: CGFloat = 155

        // main stack view
        static let imageTextSpacing: CGFloat = 12
        static let mainStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
    }
}
