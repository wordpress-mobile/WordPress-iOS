class RevisionsTableViewCell: UITableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subTitleLabel: UILabel!
    @IBOutlet var avatarImageView: CircularImageView!

    var modifiedDate: String? {
        didSet {
            titleLabel.text = modifiedDate
        }
    }

    var createdDate: String? {
        didSet {
            subTitleLabel.text = createdDate
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        WPStyleGuide.configureTableViewCell(self)
        titleLabel.textColor = WPStyleGuide.darkGrey()
        subTitleLabel.textColor = WPStyleGuide.greyDarken10()
    }

    static let reuseIdentifier = "RevisionsTableViewCellIdentifier"
}
