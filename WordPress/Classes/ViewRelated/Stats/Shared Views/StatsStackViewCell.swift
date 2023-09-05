class StatsStackViewCell: StatsBaseCell, NibLoadable {
    private typealias Style = WPStyleGuide.Stats

    @IBOutlet private(set) var stackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        Style.configureCell(self)
        stackView.removeAllSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.removeAllSubviews()
    }

    func insert(view: UIView, animated: Bool = true) {
        stackView.addArrangedSubview(view)
    }
}
