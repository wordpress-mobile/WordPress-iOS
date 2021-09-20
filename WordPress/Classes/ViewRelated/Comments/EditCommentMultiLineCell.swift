import Foundation

protocol EditCommentMultiLineCellDelegate: AnyObject {
    func textViewHeightUpdated()
    func textUpdated(_ updatedText: String?)
}

class EditCommentMultiLineCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewMinHeightConstraint: NSLayoutConstraint!
    weak var delegate: EditCommentMultiLineCellDelegate?

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

extension EditCommentMultiLineCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        delegate?.textUpdated(textView.text)
        adjustHeight()
    }

}

// MARK: - Private Extension

private extension EditCommentMultiLineCell {

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
            delegate?.textViewHeightUpdated()
        }
    }

}
