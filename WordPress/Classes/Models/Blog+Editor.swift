import Foundation

enum MobileEditor: String {
    case aztec
    case gutenberg
}

enum WebEditor: String {
    case classic
    case gutenberg
}

extension Blog {
    struct Editor {
        fileprivate let blog: Blog
        var mobile: MobileEditor? {
            return MobileEditor(rawValue: blog.mobileEditor ?? "")
        }
        var web: WebEditor? {
            return WebEditor(rawValue: blog.webEditor ?? "")
        }
        func setMobileEditor(_ newValue: MobileEditor) {
            blog.mobileEditor = newValue.rawValue
        }
    }

    var editor: Editor {
        return Editor(blog: self)
    }

    @objc var isGutenbergEnabled: Bool {
        guard let selectedEditor = editor.mobile else {
            return GutenbergSettings().getDefaultEditor(for: self) == .gutenberg
        }
        return selectedEditor == .gutenberg
    }
}
