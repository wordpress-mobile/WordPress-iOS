import Foundation
import WordPressShared.WPStyleGuide
import WordPressUI
import Gravatar
import SwiftUI
import DesignSystem

// MARK: - NoteBlockHeaderTableViewCell
//
class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {
    private var controller: UIHostingController<HeaderView>?

    func configure(text: String, avatarURL: URL?, action: @escaping () -> Void, parent: UIViewController) {
        let headerView = HeaderView(image: avatarURL, text: text, action: action)
        if let controller = controller {
            controller.rootView = headerView
            controller.view.layoutIfNeeded()
        } else {
            let cellViewController = UIHostingController(rootView: headerView)
            controller = cellViewController

            parent.addChild(cellViewController)
            contentView.addSubview(cellViewController.view)
            cellViewController.view.translatesAutoresizingMaskIntoConstraints = false
            layout(hostingView: cellViewController.view)

            cellViewController.didMove(toParent: parent)
        }
    }

    func layout(hostingView view: UIView) {
        self.contentView.pinSubviewToAllEdges(view)
    }
}

private struct HeaderView: View {
    private let image: URL?
    private let text: String
    private let action: () -> Void

    public init(image: URL?, text: String, action: @escaping () -> Void) {
        self.image = image
        self.text = text
        self.action = action
    }

    var body: some View {
        ContentPreview(image: image != nil ? .init(url: image) : nil, text: text, action: action)
            .padding(EdgeInsets(top: 16.0, leading: 16.0, bottom: 8.0, trailing: 16.0))
    }
}
