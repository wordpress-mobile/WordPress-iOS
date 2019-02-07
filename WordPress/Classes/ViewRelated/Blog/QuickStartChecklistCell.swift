import Gridicons

class QuickStartChecklistCell: UITableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var iconView: UIImageView?
    @IBOutlet private var stroke: UIView?

    private var bottomStrokeLeading: NSLayoutConstraint?
    private var contentViewLeadingAnchor: NSLayoutXAxisAnchor {
        return WPDeviceIdentification.isiPhone() ? contentView.leadingAnchor : contentView.readableContentGuide.leadingAnchor
    }
    private var contentViewTrailingAnchor: NSLayoutXAxisAnchor {
        return WPDeviceIdentification.isiPhone() ? contentView.trailingAnchor : contentView.readableContentGuide.trailingAnchor
    }

    public var completed = false {
        didSet {
            if completed {
                guard let titleText = tour?.title else {
                    return
                }

                if Feature.enabled(.quickStartV2) {
                    titleLabel.attributedText = NSAttributedString(string: titleText,
                                                                   attributes: [.strikethroughStyle: 1,
                                                                                .foregroundColor: WPStyleGuide.grey()])
                    descriptionLabel.textColor = WPStyleGuide.grey()
                } else {
                    titleLabel.attributedText = NSAttributedString(string: titleText, attributes: [.strikethroughStyle: 1])
                    accessoryView = UIImageView(image: Gridicon.iconOfType(.checkmark))
                }
            } else {
                if Feature.enabled(.quickStartV2) {
                    titleLabel.textColor = WPStyleGuide.darkGrey()
                    descriptionLabel.textColor = WPStyleGuide.darkGrey()
                } else {
                    accessoryView = nil
                }
            }
        }
    }
    public var tour: QuickStartTour? {
        didSet {
            titleLabel.text = tour?.title
            descriptionLabel.text = tour?.description
            iconView?.image = tour?.icon.imageWithTintColor(WPStyleGuide.greyLighten10())

            if !Feature.enabled(.quickStartV2) {
                accessoryType = .disclosureIndicator
            }
        }
    }

    public var lastRow: Bool = false {
        didSet {
            bottomStrokeLeading?.isActive = !lastRow && Feature.enabled(.quickStartV2)
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()

        if let stroke = stroke, Feature.enabled(.quickStartV2) {
            WPStyleGuide.configureLabel(titleLabel, textStyle: .headline)
            WPStyleGuide.configureLabel(descriptionLabel, textStyle: .subheadline)

            bottomStrokeLeading = stroke.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
            bottomStrokeLeading?.isActive = true
            let strokeSuperviewLeading = stroke.leadingAnchor.constraint(equalTo: contentViewLeadingAnchor)
            strokeSuperviewLeading.priority = UILayoutPriority(999.0)
            strokeSuperviewLeading.isActive = true
            stroke.trailingAnchor.constraint(equalTo: contentViewTrailingAnchor).isActive = true
        }
    }

    static let reuseIdentifier = "QuickStartChecklistCell"
}
