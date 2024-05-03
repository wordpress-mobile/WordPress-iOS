import Foundation
import WordPressShared.WPStyleGuide
import WordPressUI
import Gravatar
import SwiftUI
import DesignSystem

// MARK: - NoteBlockHeaderTableViewCell
//
class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {
    typealias Constants = ContentPreview.Constants
    typealias Avatar = ContentPreview.ImageConfiguration.Avatar

    private var controller: UIHostingController<HeaderView>?

    func configure(post: String, action: @escaping () -> Void, parent: UIViewController) {
        let content = ContentPreview(text: post, action: action)
        host(HeaderView(preview: content), parent: parent)
    }

    func configure(avatar: Avatar, comment: String, action: @escaping () -> Void, parent: UIViewController) {
        let content = ContentPreview(image: .init(avatar: avatar), text: comment, action: action)
        host(HeaderView(preview: content), parent: parent)
    }

    private func host(_ content: HeaderView, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = content
            controller.view.layoutIfNeeded()
        } else {
            let cellViewController = UIHostingController(rootView: content)
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
    private let preview: ContentPreview

    public init(preview: ContentPreview) {
        self.preview = preview
    }

    var body: some View {
        preview.padding(EdgeInsets(top: 16.0, leading: 16.0, bottom: 8.0, trailing: 16.0))
    }
}
