class StatsStackViewCell: UITableViewCell, NibLoadable {
    private typealias Style = WPStyleGuide.Stats
    
    @IBOutlet private(set) var stackView: UIStackView! {
        didSet {
            contentView.addTopBorder(withColor: Style.separatorColor)
            contentView.addBottomBorder(withColor: Style.separatorColor)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Style.configureCell(self)
    }
    
    func insert(view: UIView, animated: Bool = true) {
        if !stackView.subviews.isEmpty {
            stackView.removeAllSubviews()
        }
        if animated {
            view.startGhostAnimation()
        } else {
            view.stopGhostAnimation()
        }
        stackView.addArrangedSubview(view)
    }
}
