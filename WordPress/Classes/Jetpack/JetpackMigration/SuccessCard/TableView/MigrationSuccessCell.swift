import UIKit

@objc
public class MigrationSuccessCell: UITableViewCell {

    var onTap: (() -> Void)?
    var cardView: MigrationSuccessCardView?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let view = MigrationSuccessCardView() {
            self.onTap?()
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        contentView.pinSubviewToAllEdges(view)
        cardView = view
    }

    @objc public func configureForSidebarMode() {
        cardView?.backgroundColor = .clear
    }

    @objc(configureWithViewController:)
    public func configure(with viewController: UIViewController) {
        self.onTap = { [weak viewController] in
            guard let viewController else {
                return
            }
            let handler = MigrationSuccessActionHandler()
            handler.showDeleteWordPressOverlay(with: viewController)
        }
    }
}
