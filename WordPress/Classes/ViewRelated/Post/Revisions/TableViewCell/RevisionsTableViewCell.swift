class RevisionsTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?

    var revisionNum: Int? {
        didSet {
            titleLabel?.text = "Revision \(revisionNum ?? -2)"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    static let reuseIdentifier = "RevisionsTableViewCell"
}
