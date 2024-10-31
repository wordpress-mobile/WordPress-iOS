import UIKit

class ReaderStreamBaseCell: UITableViewCell {
    static let insets = UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 16)

    var isCompact: Bool = true {
        didSet {
            guard oldValue != isCompact else { return }
            didUpdateCompact(isCompact)
        }
    }

    var isSeparatorHidden = false {
        didSet {
            guard oldValue != isSeparatorHidden else { return }
            updateSeparatorsInsets()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.opaqueSeparator.withAlphaComponent(0.2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateSeparatorsInsets()
    }

    private func updateSeparatorsInsets() {
        separatorInset = UIEdgeInsets(.leading, isSeparatorHidden ? 9999 : Self.insets.left + (isCompact ? 0 : contentView.readableContentGuide.layoutFrame.minX))
    }

    func didUpdateCompact(_ isCompact: Bool) {
        // Do nothing
    }
}
