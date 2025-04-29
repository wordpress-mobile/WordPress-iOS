import Foundation
import WordPressShared

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

    @objc public var isGutenbergEnabled: Bool {
        return editor == .gutenberg
    }

    /// - warning: Decoding can take a non-trivial amount of time.
    func getBlockEditorSettings() -> [String: Any]? {
        guard let data = rawBlockEditorSettings?.data else {
            return nil
        }
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            guard let settings = object as? [String: Any] else {
                wpAssertionFailure("invalid block editor settings object")
                return nil
            }
            return settings
        } catch {
            wpAssertionFailure("failed to decode block editor settings", userInfo: ["error": "\(error)"])
        }
        return nil
    }

    func setBlockEditorSettings(_ settings: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(settings) else {
            return wpAssertionFailure("invalid block editor settings object")
        }
        guard let context = managedObjectContext else {
            return wpAssertionFailure("missing managed object context")
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: settings, options: [])
            let blob = NSEntityDescription.insertNewObject(forEntityName: "BlobEntity", into: context) as! BlobEntity
            blob.data = data
            self.rawBlockEditorSettings = blob
        } catch {
            wpAssertionFailure("failed to encode block editor settings", userInfo: ["error": "\(error)"])
        }
    }
}
