class QuickStartChecklistCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var iconView: UIImageView?
    public var completed = false {
        didSet {
            if completed {
                guard let titleText = tour?.title else {
                    return
                }

                titleLabel?.attributedText = NSAttributedString(string: titleText, attributes: [.strikethroughStyle: 1])
            }
        }
    }

    public var tour: QuickStartTour? {
        didSet {
            titleLabel?.text = tour?.title
            descriptionLabel?.text = tour?.description
            iconView?.image = tour?.icon.imageWithTintColor(WPStyleGuide.greyLighten10())
            accessoryType = .disclosureIndicator
        }
    }

    static let reuseIdentifier = "QuickStartChecklistCell"
}
