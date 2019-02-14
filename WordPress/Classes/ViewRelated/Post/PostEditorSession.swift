import Foundation

struct PostEditorSession {
    private let sessionId = UUID().uuidString
    let postType: String
    let blogType: String
    let contentType: String
    var started = false
    var currentEditor: Editor
    var hasUnsupportedBlocks = false

    init(editor: Editor, post: AbstractPost) {
        currentEditor = editor
        postType = post.analyticsPostType ?? "unsupported"
        blogType = post.blog.analyticsType.rawValue
        contentType = ContentType(post: post).rawValue
    }

    mutating func start(hasUnsupportedBlocks: Bool) {
        assert(!started, "An editor session was attempted to start more than once")
        self.hasUnsupportedBlocks = hasUnsupportedBlocks
        WPAppAnalytics.track(.editorSessionStart, withProperties: commonProperties)
        started = true
    }

    mutating func `switch`(editor: Editor) {
        currentEditor = editor
        WPAppAnalytics.track(.editorSessionSwitchEditor, withProperties: commonProperties)
    }

    func end(reason: EndReason) {
        let properties = [
            Property.reason: reason.rawValue,
            ].merging(commonProperties, uniquingKeysWith: { $1 })

        WPAppAnalytics.track(.editorSessionEnd, withProperties: properties)
    }
}

private extension PostEditorSession {
    enum Property {
        static let blogType = "blog_type"
        static let contentType = "content_type"
        static let editor = "editor"
        static let hasUnsupportedBlocks = "has_unsupported_blocks"
        static let postType = "post_type"
        static let reason = "reason"
        static let sessionId = "session_id"
    }

    var commonProperties: [String: String] {
        return [
            Property.editor: currentEditor.rawValue,
            Property.contentType: contentType,
            Property.postType: postType,
            Property.blogType: blogType,
            Property.sessionId: sessionId,
            Property.hasUnsupportedBlocks: hasUnsupportedBlocks ? "1" : "0"
        ]
    }
}

extension PostEditorSession {
    enum Editor: String {
        case gutenberg
        case classic
        case html
    }

    enum ContentType: String {
        case new
        case gutenberg
        case classic

        init(post: AbstractPost) {
            if post.isContentEmpty() {
                self = .new
            } else if post.containsGutenbergBlocks() {
                self = .gutenberg
            } else {
                self = .classic
            }
        }
    }

    enum EndReason: String {
        case cancel
        case discard
        case save
        case publish
    }
}
