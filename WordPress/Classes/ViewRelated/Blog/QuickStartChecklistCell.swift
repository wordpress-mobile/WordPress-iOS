class QuickStartChecklistCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var iconView: UIImageView?

    public var tour: QuickStartTour? {
        didSet {
            titleLabel?.text = tour?.title
            descriptionLabel?.text = tour?.description
            iconView?.image = tour?.icon
        }
    }

    static let reuseIdentifier = "QuickStartChecklistCell"
}
