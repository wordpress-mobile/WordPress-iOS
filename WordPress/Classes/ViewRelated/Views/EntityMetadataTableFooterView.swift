import UIKit

final class EntityMetadataTableFooterView: UIView {
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        textLabel.textColor = .tertiaryLabel
        textLabel.font = .preferredFont(forTextStyle: .footnote)
        textLabel.textAlignment = .center

        addSubview(textLabel)
        textLabel.pinEdges(insets: UIEdgeInsets(.all, 8))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func make(id: NSNumber) -> UIView {
        let footerView = EntityMetadataTableFooterView()
        footerView.textLabel.text = "\(Strings.id) \(id)"
        return footerView
    }
}

private enum Strings {
    static let id = NSLocalizedString("entityMetadataFooterView.id", value: "ID", comment: "A name of the ID field (it's a technical field, has to be short, displayed below everything else)")
}
