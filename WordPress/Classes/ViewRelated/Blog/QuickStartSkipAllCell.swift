class QuickStartSkipAllCell: UITableViewCell {
    @IBOutlet var skipAllLabel: UILabel?
    var onTap: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        let title = AppLocalizedString("Skip All", comment: "Label for button that will allow the user to skip all items in the Quick Start checklist")
        skipAllLabel?.text = title
    }

    static let reuseIdentifier = "QuickStartSkipAllCell"
}
