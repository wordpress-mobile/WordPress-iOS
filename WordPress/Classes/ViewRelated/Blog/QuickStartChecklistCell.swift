import Gridicons

class QuickStartChecklistCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var iconView: UIImageView?

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
                    titleLabel?.attributedText = NSAttributedString(string: titleText, attributes: [.strikethroughStyle: 1])
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
            titleLabel?.text = tour?.title
            descriptionLabel?.text = tour?.description

            if Feature.enabled(.quickStartV2) {
                imageView?.image = tour?.icon.imageWithTintColor(WPStyleGuide.greyLighten10())
            } else {
                iconView?.image = tour?.icon.imageWithTintColor(WPStyleGuide.greyLighten10())
                accessoryType = .disclosureIndicator
            }
        }
    }

    public var lastRow: Bool = false {
        didSet {
            if lastRow, Feature.enabled(.quickStartV2) {
                separatorInset = .zero
            }
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()

        if Feature.enabled(.quickStartV2) {
            WPStyleGuide.configureLabel(titleLabel, textStyle: .headline)
            WPStyleGuide.configureLabel(descriptionLabel, textStyle: .subheadline)
        }
    }

    static let reuseIdentifier = "QuickStartChecklistCell"
}
