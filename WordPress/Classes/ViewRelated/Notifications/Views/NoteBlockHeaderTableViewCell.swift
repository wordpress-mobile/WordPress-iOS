import Foundation
import WordPressShared.WPStyleGuide
import WordPressUI
import Gravatar
import SwiftUI
import DesignSystem

// MARK: - NoteBlockHeaderTableViewCell
//
class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell {
    private var hostViewController: UIHostingController<HeaderView>?

    func configure(text: String, avatarURL: URL?, action: @escaping () -> Void) {
        let headerView = HeaderView(image: avatarURL, text: text, action: action)
        hostViewController = UIHostingController(rootView: headerView)
        guard let hostViewController = hostViewController else { return }
        hostViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostViewController.view)
        contentView.pinSubviewToAllEdges(hostViewController.view)
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
        ContentPreview(image: image, text: text, action: action)
            .padding(EdgeInsets(top: 16.0, leading: 16.0, bottom: 8.0, trailing: 16.0))
    }
}
