class StatsGhostTwoColumnCell: UITableViewCell, NibLoadable {
    private typealias Style = WPStyleGuide.Stats

    override func awakeFromNib() {
        super.awakeFromNib()
        Style.configureCell(self)
    }
}
