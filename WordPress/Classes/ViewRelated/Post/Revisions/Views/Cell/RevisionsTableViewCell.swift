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

    var avatarURL: String? {
        didSet {
            avatarImageView.image = UIImage(named: "gravatar")

            if let avatarURL = avatarURL,
                let placeholder = UIImage(named: "gravatar") {
                let url = URL(string: avatarURL)
                avatarImageView.downloadGravatar(url.flatMap { Gravatar($0) },
                                                 placeholder: placeholder,
                                                 animate: false)
            }
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyles()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let previouslyHighlighted = self.isHighlighted
        super.setHighlighted(highlighted, animated: animated)

        if previouslyHighlighted != highlighted {
            addOperation.internalView.type = .add
            delOperation.internalView.type = .del
        }
    }
}


private extension RevisionsTableViewCell {
    private func setupStyles() {
        // Setup cell style
        WPStyleGuide.configureTableViewCell(self)
        contentView.backgroundColor = .listForeground

        // Setup labels
        titleLabel.backgroundColor = .listForeground
        titleLabel.textColor = .text
        subTitleLabel.backgroundColor = .listForeground
        subTitleLabel.textColor = .textSubtle

        // Setup del operations
        delOperation = RevisionOperation(.del)
        addOperation = RevisionOperation(.add)

        stackView.addArrangedSubview(addOperation.internalView)
        stackView.addArrangedSubview(delOperation.internalView)
    }
}
