class QuickStartCongratulationsCell: UITableViewCell {
    @IBOutlet var topLabel: UILabel?
    @IBOutlet var bottomLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()

        topLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
        bottomLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)

        let tour = QuickStartCongratulationsTour()

        topLabel?.text = tour.title
        bottomLabel?.text = tour.description
    }

    static let reuseIdentifier = "QuickStartCongratulationsCell"
}
