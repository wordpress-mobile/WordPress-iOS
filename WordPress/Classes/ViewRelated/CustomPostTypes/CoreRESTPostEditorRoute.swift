import SwiftUI
import UIKit
import WordPressData

struct CoreRESTPostEditorRoute: View {
    let blog: Blog
    let postType: PinnedPostType
    let initialContent: EditorContent?
    weak var presentingViewController: UIViewController?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let presentingViewController {
                content(presentingViewController: presentingViewController)
            }
        }
    }

    @ViewBuilder
    private func content(presentingViewController: UIViewController) -> some View {
        ApplicationPasswordRequiredView(
            blog: blog,
            localizedFeatureName: Strings.featureName,
            source: "block_editor",
            presentingViewController: presentingViewController
        ) { [weak presentingViewController] client in
            if let presentingViewController {
                PinnedPostTypeView<AnyView>(
                    blog: blog,
                    service: CustomPostTypeService(client: client, blog: blog),
                    postType: postType,
                    presentingViewController: presentingViewController
                ) { resolved in
                    AnyView(
                        CustomPostEditor(
                            wpService: resolved.wpService,
                            client: client,
                            post: nil,
                            details: resolved.details,
                            blog: blog,
                            initialSettings: nil,
                            initialContent: initialContent
                        )
                        .toolbar(.hidden, for: .navigationBar)
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.Button.close) {
                    dismiss()
                }
            }
        }
    }
}

private enum Strings {
    static let featureName = NSLocalizedString(
        "applicationPasswordRequired.feature.blockEditor",
        value: "Block Editor",
        comment: "Feature name for the block editor in application password required prompt"
    )
}
