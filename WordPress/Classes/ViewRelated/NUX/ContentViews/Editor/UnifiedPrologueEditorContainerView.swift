import UIKit
import SwiftUI

/// Prologue editor container view - Needed to bridge SwiftUI to UIKit
class UnifiedPrologueEditorContainerView: UIView {

    init() {
        super.init(frame: .zero)
        let controller = UIHostingController(rootView: UnifiedPrologueEditorContentView())
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        addSubview(controller.view)
        pinSubviewToAllEdges(controller.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
