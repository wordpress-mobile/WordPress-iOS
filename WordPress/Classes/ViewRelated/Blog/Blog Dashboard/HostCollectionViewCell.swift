import UIKit
import SwiftUI

protocol Hostable {
    associatedtype Content: View
    var hostController: UIHostingController<Content>? { get }
    var hostedView: Content? { get set }
}

/// A generic UICollectionViewCell that hosts a SwiftUI view.
///
/// Create a HostCollectionViewCell when you want to integrate SwiftUI views into a UIKit view hierarchy.
/// At creation time, specify the SwiftUI view you want to use as the content view for this cell.
class HostCollectionViewCell<Content>: UICollectionViewCell, Hostable where Content: View {

    var hostController: UIHostingController<Content>?

    var hostedView: Content? {
        willSet {
            guard let view = newValue else {
                return
            }
            hostController = UIHostingController(rootView: view)
            if let hostView = hostController?.view {
                contentView.addSubview(hostView)
                hostView.translatesAutoresizingMaskIntoConstraints = false
                contentView.pinSubviewToAllEdges(hostView)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
        hostController = nil
    }
}

extension HostCollectionViewCell: Reusable { }

extension HostCollectionViewCell: BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?) {
        hostedView = QuickLinksView(title: "Quick Links") as? Content
    }
}
