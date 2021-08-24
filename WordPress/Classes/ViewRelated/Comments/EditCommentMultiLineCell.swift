import Foundation

protocol EditCommentMultiLineCellDelegate: AnyObject {
    func textViewHeightUpdated()
}

class EditCommentMultiLineCell: UITableViewCell, NibReusable {

    // MARK: - Properties

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewMinHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!
    private var textViewPadding: CGFloat = 0
    weak var delegate: EditCommentMultiLineCellDelegate?

    // MARK: - View

    override func awakeFromNib() {
        super.awakeFromNib()
        configureCell()
        textViewPadding = textViewTopConstraint.constant * 2
    }

    func configure(text: String? = nil) {
        textView.text = text
        adjustHeight()
    }

}

// MARK: - UITextViewDelegate

extension EditCommentMultiLineCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
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
        let originalCellHeight = frame.size.height
        let textViewSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        let textViewHeight = ceilf(Float(max(textViewSize.height, textViewMinHeightConstraint.constant)))
        let newCellHeight = CGFloat(textViewHeight) + textViewPadding
        frame.size.height = newCellHeight

        if newCellHeight != originalCellHeight {
            delegate?.textViewHeightUpdated()
        }
    }

}
