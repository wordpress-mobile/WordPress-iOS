import SwiftUI
import UIKit

/// - warning: Some of the SwiftUI lifestyle callbacks, like `onAppear`, are
/// not guaranteed to function correctly.
public final class UIHostingView<Content: View>: UIView {
    let view: Content
    let hostingController: UIHostingController<Content>

    public init(view: Content) {
        self.view = view
        self.hostingController = UIHostingController(rootView: view)

        super.init(frame: .zero)

        addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(hostingController.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
