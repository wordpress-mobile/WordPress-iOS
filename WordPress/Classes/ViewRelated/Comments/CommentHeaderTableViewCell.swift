import UIKit
import DesignSystem

final class CommentHeaderTableViewCell: HostingTableViewCell<ContentPreview>, Reusable {

    // MARK: Initialization

    required init() {
        super.init(style: .subtitle, reuseIdentifier: Self.defaultReuseID)
        self.selectionStyle = .none
        self.contentView.directionalLayoutMargins = .init(
            top: CGFloat.DS.Padding.double,
            leading: 0,
            bottom: CGFloat.DS.Padding.double,
            trailing: 0
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(imageURL: URL?, text: String, parent: UIViewController) {
        let content = ContentPreview(image: imageURL, text: text) {
            print("Hello World")
        }
        self.host(content, parent: parent)
    }

    // MARK: - Layout

    override func layout(hostingView view: UIView) {
        self.contentView.pinSubviewToAllEdgeMargins(view)
    }
}
