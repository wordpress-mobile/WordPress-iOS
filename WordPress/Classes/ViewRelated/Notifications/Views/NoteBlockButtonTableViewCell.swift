import UIKit

class NoteBlockButtonTableViewCell: NoteBlockTableViewCell {

    @IBOutlet weak var button: FancyButton!

    var title: String? {
        set {
            button.setTitle(newValue, for: .normal)
        }
        get {
            return button.title(for: .normal)
        }
    }

    /// An block to be invoked when the button is tapped.
    var action: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        selectionStyle = .none

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc
    private func buttonTapped() {
        action?()
    }
}
