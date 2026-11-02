import UIKit

// UITableViewCell that displays an editable UITextView to allow text to be modified inline.
// The cell height resizes as the text is modified.
// The delegate is notified when:
// - The height is updated.
// - The text is updated.

protocol InlineEditableMultiLineCellDelegate: AnyObject {
    func textViewHeightUpdatedForCell(_ cell: InlineEditableMultiLineCell)
    func textUpdatedForCell(_ cell: InlineEditableMultiLineCell)
}

class InlineEditableMultiLineCell: UITableViewCell, Reusable {

    // MARK: - Properties

    let textView: UITextView = {
        // Start at the size the xib gave it: `adjustHeight()` reads the frame before the first layout pass.
        let textView = UITextView(frame: CGRect(x: 16, y: 11, width: 332, height: 130))
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.contentInsetAdjustmentBehavior = .never
        textView.adjustsFontForContentSizeCategory = true
        textView.autocapitalizationType = .sentences
        return textView
    }()
    private lazy var textViewMinHeightConstraint = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 130)
    weak var delegate: InlineEditableMultiLineCellDelegate?

    // MARK: - View

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        clipsToBounds = true
        preservesSuperviewLayoutMargins = true
        selectionStyle = .none
        contentView.isOpaque = false
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.preservesSuperviewLayoutMargins = true
        contentView.insetsLayoutMarginsFromSafeArea = false

        textView.delegate = self
        contentView.addSubview(textView)
        NSLayoutConstraint.activate([
            textViewMinHeightConstraint,
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: 11)
        ])

        configureCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String? = nil) {
        textView.text = text
        adjustHeight()
    }
}

// MARK: - UITextViewDelegate

extension InlineEditableMultiLineCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        delegate?.textUpdatedForCell(self)
        adjustHeight()
    }
}

// MARK: - Private Extension

private extension InlineEditableMultiLineCell {

    func configureCell() {
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.backgroundColor = .clear
    }

    func adjustHeight() {
        let originalHeight = textView.frame.size.height
        textView.sizeToFit()
        let textViewHeight = ceilf(Float(max(textView.frame.size.height, textViewMinHeightConstraint.constant)))
        textView.frame.size.height = CGFloat(textViewHeight)

        if textViewHeight != Float(originalHeight) {
            delegate?.textViewHeightUpdatedForCell(self)
        }
    }
}
