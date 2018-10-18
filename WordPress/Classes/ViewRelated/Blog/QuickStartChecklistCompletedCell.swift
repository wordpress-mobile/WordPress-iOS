class QuickStartChecklistCompletedCell: UITableViewCell {
    @IBOutlet var topLabel: UILabel?
    @IBOutlet var bottomLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()

        topLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        bottomLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)

        topLabel?.text = NSLocalizedString("Congrats on finishing Quick Start  🎉", comment: "Headline shown to users when they complete all Quick Start items")
        bottomLabel?.text = NSLocalizedString("doesn’t it feel good to cross things off a list?", comment: "subhead shown to users when they complete all Quick Start items")
    }

    static let reuseIdentifier = "QuickStartChecklistCompletedCell"
}
