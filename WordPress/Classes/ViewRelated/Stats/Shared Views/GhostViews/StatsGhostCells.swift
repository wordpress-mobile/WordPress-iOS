class StatsGhostBaseCell: UITableViewCell {
    private typealias Style = WPStyleGuide.Stats

    override func awakeFromNib() {
        super.awakeFromNib()
        Style.configureCell(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopGhostAnimation()
    }
}

class StatsGhostTwoColumnCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTopCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostTabbedCell: StatsGhostBaseCell, NibLoadable { }
class StatsGhostPostingActivityCell: StatsGhostBaseCell, NibLoadable { }
