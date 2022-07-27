import Foundation

// UITableViewCell that displays an editable UITextView to allow text to be modified inline.
// The cell height resizes as the text is modified.
// The delegate is notified when:
// - The height is updated.
// - The text is updated.

protocol InlineEditableMultiLineCellDelegate: AnyObject {
    func textViewHeightUpdatedForCell(_ cell: InlineEditableMultiLineCell)
    func textUpdatedForCell(_ cell: InlineEditableMultiLineCell)
}

class InlineEditableMultiLineCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewMinHeightConstraint: NSLayoutConstraint!
    weak var delegate: InlineEditableMultiLineCellDelegate?

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
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
        textView.textColor = .text
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
