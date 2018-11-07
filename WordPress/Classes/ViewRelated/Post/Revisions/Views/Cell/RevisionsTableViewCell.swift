import Gridicons

class RevisionsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "RevisionsTableViewCellIdentifier"

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subTitleLabel: UILabel!
    @IBOutlet private var avatarImageView: CircularImageView!
    @IBOutlet private var stackView: UIStackView!

    private var delOperation: RevisionOperation!
    private var addOperation: RevisionOperation!

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var subtitle: String? {
        didSet {
            subTitleLabel.text = subtitle
        }
    }

    var totalDel: Int? {
        didSet {
            delOperation.internalView.total = totalDel ?? 0
        }
    }

    var totalAdd: Int? {
        didSet {
            addOperation.internalView.total = totalAdd ?? 0
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyles()
    }
}


private extension RevisionsTableViewCell {
    private func setupStyles() {
        // Setup cell style
        WPStyleGuide.configureTableViewCell(self)

        // Setup labels
        titleLabel.textColor = WPStyleGuide.darkGrey()
        subTitleLabel.textColor = WPStyleGuide.greyDarken10()

        // Setup del operations
        delOperation = RevisionOperation(.del)
        addOperation = RevisionOperation(.add)

        stackView.addArrangedSubview(addOperation.internalView)
        stackView.addArrangedSubview(delOperation.internalView)
    }
}
