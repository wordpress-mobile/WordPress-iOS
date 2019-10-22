import Foundation

class ChosenValueRow: UIView {
    weak var titleLabel: UILabel?
    weak var detailLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        
        let detailLabel = UILabel()
        detailLabel.textAlignment = .right
        detailLabel.textColor = .textSubtle
        
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            detailLabel
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        addConstraints([
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        self.titleLabel = titleLabel
        self.detailLabel = detailLabel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
