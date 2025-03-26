import Foundation
import AutomatticTracks
import WordPressFlux

/// This extension handles the "more" actions triggered by the top right
/// navigation bar button of Gutenberg editor.
extension GutenbergViewController {
    func makeMoreMenu() -> UIMenu {
        UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
            UIDeferredMenuElement.uncached { [weak self] callback in
                // Common actions at the top so they are always in the same
                // relative place.
                callback(self?.makeMoreMenuMainSections() ?? [])
            },
            UIDeferredMenuElement.uncached { [weak self] callback in
                // Dynamic actions at the bottom. The actions are loaded asynchronously
                // because they need the latest post content from the editor
                // to display the correct state.
                self?.requestHTML {
                    callback(self?.makeMoreMenuAsyncSections() ?? [])
                }
            }
        ])
    }

    private func makeMoreMenuMainSections() -> [UIMenuElement] {
        return  [
            UIMenu(title: "", subtitle: "", options: .displayInline, children: makeMoreMenuActions()),
        ]
    }

    private func makeMoreMenuAsyncSections() -> [UIMenuElement] {
        var sections: [UIMenuElement] = [
            // Dynamic actions at the bottom
            UIMenu(title: "", subtitle: "", options: .displayInline, children: makeMoreMenuSecondaryActions())
        ]
        if let string = makeContextStructureString() {
            sections.append(UIAction(subtitle: string, attributes: [.disabled], handler: { _ in }))
        }
        return sections
    }

    private func makeMoreMenuSecondaryActions() -> [UIAction] {
        var actions: [UIAction] = []
        if post.original().isStatus(in: [.draft, .pending]) {
            actions.append(UIAction(title: Strings.saveDraft, image: UIImage(systemName: "doc"), attributes: (editorHasChanges && editorHasContent) ? [] : [.disabled]) { [weak self] _ in
                self?.buttonSaveDraftTapped()
            })
        }
        return actions
    }

    private func makeMoreMenuActions() -> [UIAction] {
        var actions: [UIAction] = []

        let toggleModeTitle = mode == .richText ? Strings.codeEditor : Strings.visualEditor
        let toggleModeIconName = mode == .richText ? "curlybraces" : "doc.richtext"
        actions.append(UIAction(title: toggleModeTitle, image: UIImage(systemName: toggleModeIconName)) { [weak self] _ in
            self?.toggleEditingMode()
        })

        actions.append(UIAction(title: Strings.preview, image: UIImage(systemName: "safari")) { [weak self] _ in
            self?.displayPreview()
        })

        let revisionCount = (post.revisions ?? []).count
        if revisionCount > 0 {
            actions.append(UIAction(title: Strings.revisions + " (\(revisionCount))", image: UIImage(systemName: "clock.arrow.circlepath")) { [weak self] _ in
                self?.displayRevisionsList()
            })
        }

        let settingsTitle = self.post is Page ? Strings.pageSettings : Strings.postSettings
        actions.append(UIAction(title: settingsTitle, image: UIImage(systemName: "gearshape")) { [weak self] _ in
            self?.displayPostSettings()
        })
        let helpTitle = JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() ? Strings.helpAndSupport : Strings.help
        actions.append(UIAction(title: helpTitle, image: UIImage(systemName: "questionmark.circle")) { [weak self] _ in
            self?.showEditorHelp()
        })
        return actions
    }

    private func makeContextStructureString() -> String? {
        guard mode == .richText, let contentInfo else {
            return nil
        }
        return String(format: Strings.contentStructure, contentInfo.blockCount, contentInfo.wordCount, contentInfo.characterCount)
    }
}

private enum Strings {
    static let codeEditor = NSLocalizedString("postEditor.moreMenu.codeEditor", value: "Code Editor", comment: "Post Editor / Button in the 'More' menu")
    static let visualEditor = NSLocalizedString("postEditor.moreMenu.visualEditor", value: "Visual Editor", comment: "Post Editor / Button in the 'More' menu")
    static let preview = NSLocalizedString("postEditor.moreMenu.preview", value: "Preview", comment: "Post Editor / Button in the 'More' menu")
    static let revisions = NSLocalizedString("postEditor.moreMenu.revisions", value: "Revisions", comment: "Post Editor / Button in the 'More' menu")
    static let pageSettings = NSLocalizedString("postEditor.moreMenu.pageSettings", value: "Page Settings", comment: "Post Editor / Button in the 'More' menu")
    static let postSettings = NSLocalizedString("postEditor.moreMenu.postSettings", value: "Post Settings", comment: "Post Editor / Button in the 'More' menu")
    static let helpAndSupport = NSLocalizedString("postEditor.moreMenu.helpAndSupport", value: "Help & Support", comment: "Post Editor / Button in the 'More' menu")
    static let help = NSLocalizedString("postEditor.moreMenu.help", value: "Help", comment: "Post Editor / Button in the 'More' menu")
    static let saveDraft = NSLocalizedString("postEditor.moreMenu.saveDraft", value: "Save Draft", comment: "Post Editor / Button in the 'More' menu")
    static let contentStructure = NSLocalizedString("postEditor.moreMenu.contentStructure", value: "Blocks: %li, Words: %li, Characters: %li", comment: "Post Editor / 'More' menu details labels with 'Blocks', 'Words' and 'Characters' counts as parameters (in that order)")
}
