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
    static let mobileEditorKeyPath = "mobileEditor"
    static let webEditorKeyPath = "webEditor"

    /// The stored setting for the default mobile editor
    ///
    var mobileEditor: MobileEditor? {
        get {
            return rawValue(forKey: Blog.mobileEditorKeyPath)
        }
        set {
            setRawValue(newValue, forKey: Blog.mobileEditorKeyPath)
        }
    }

    /// The stored setting for the default web editor
    ///
    var webEditor: WebEditor? {
        get {
            return rawValue(forKey: Blog.webEditorKeyPath)
        }
        set {
            setRawValue(newValue, forKey: Blog.webEditorKeyPath)
        }
    }

    /// The editor to use when creating a new post
    ///
    var editor: MobileEditor {
        return mobileEditor ?? GutenbergSettings().getDefaultEditor(for: self)
    }

    @objc var isGutenbergEnabled: Bool {
        return editor == .gutenberg
    }
}
