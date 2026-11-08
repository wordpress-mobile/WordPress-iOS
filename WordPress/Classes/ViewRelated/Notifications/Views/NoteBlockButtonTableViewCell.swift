import UIKit
import WordPressUI

class NoteBlockButtonTableViewCell: NoteBlockTableViewCell {

    let button: FancyButton = {
        let button = FancyButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isPrimary = true
        return button
    }()

    var title: String? {
        set {
            button.setTitle(newValue, for: .normal)
        }
        get {
            button.title(for: .normal)
        }
    }

    /// An block to be invoked when the button is tapped.
    var action: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(button)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.topAnchor.constraint(greaterThanOrEqualTo: margins.topAnchor),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: margins.leadingAnchor),
            margins.trailingAnchor.constraint(greaterThanOrEqualTo: button.trailingAnchor),
            margins.bottomAnchor.constraint(greaterThanOrEqualTo: button.bottomAnchor)
        ])

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonTapped() {
        action?()
    }
}
