import Foundation
import WordPressData

struct PostEditorAnalyticsSession {
    private let sessionId = UUID().uuidString
    let postType: String
    let blogID: NSNumber?
    let blogType: String
    let contentType: String
    var started = false
    var currentEditor: Editor
    var hasUnsupportedBlocks = false
    var outcome: Outcome? = nil
    var entryPoint: PostEditorEntryPoint?
    private let startTime = DispatchTime.now().uptimeNanoseconds

    init(editor: Editor, post: AbstractPost) {
        self.init(
            editor: editor,
            blog: post.blog,
            postType: post.analyticsPostType ?? "unsupported",
            contentType: ContentType(post: post)
        )
    }

    init(
        editor: Editor,
        blog: Blog,
        postType: String,
        contentType: ContentType,
        entryPoint: PostEditorEntryPoint? = nil
    ) {
        self.currentEditor = editor
        self.postType = postType
        self.blogID = blog.dotComID
        self.blogType = blog.analyticsType.rawValue
        self.contentType = contentType.rawValue
        self.entryPoint = entryPoint
    }

    mutating func start(unsupportedBlocks: [String] = []) {
        assert(!started, "An editor session was attempted to start more than once")
        hasUnsupportedBlocks = !unsupportedBlocks.isEmpty

        let properties = startEventProperties(with: unsupportedBlocks)

        WPAppAnalytics.track(.editorSessionStart, withProperties: properties)
        started = true
    }

    private func startEventProperties(with unsupportedBlocks: [String]) -> [String: Any] {
        // On Android, we are tracking this in milliseconds, which seems like a good enough time scale
        // Let's make sure to round the value and send an integer for consistency
        let startupTimeNanoseconds = DispatchTime.now().uptimeNanoseconds - startTime
        let startupTimeMilliseconds = Int(Double(startupTimeNanoseconds) / 1_000_000)
        var properties: [String: Any] = [Property.startupTime: startupTimeMilliseconds]

        // Tracks custom event types can't be arrays so we need to convert this to JSON
        if let data = try? JSONSerialization.data(withJSONObject: unsupportedBlocks, options: .fragmentsAllowed) {
            let blocksJSON = String(data: data, encoding: .utf8)
            properties[Property.unsupportedBlocks] = blocksJSON
        }

        properties[Property.entryPoint] = (entryPoint ?? .unknown).rawValue

        return properties.merging(commonProperties, uniquingKeysWith: { $1 })
    }

    mutating func `switch`(editor: Editor) {
        currentEditor = editor
        WPAppAnalytics.track(.editorSessionSwitchEditor, withProperties: commonProperties)
    }

    func end(outcome endOutcome: Outcome) {
        let outcome = self.outcome ?? endOutcome
        let properties: [String: Any] = [
            Property.outcome: outcome.rawValue,
            Property.entryPoint: (entryPoint ?? .unknown).rawValue
        ]
        .merging(commonProperties, uniquingKeysWith: { $1 })

        WPAppAnalytics.track(.editorSessionEnd, withProperties: properties)
    }
}

private extension PostEditorAnalyticsSession {
    enum Property {
        static let blogID = "blog_id"
        static let blogType = "blog_type"
        static let contentType = "content_type"
        static let editor = "editor"
        static let hasUnsupportedBlocks = "has_unsupported_blocks"
        static let unsupportedBlocks = "unsupported_blocks"
        static let postType = "post_type"
        static let outcome = "outcome"
        static let sessionId = "session_id"
        static let template = "template"
        static let startupTime = "startup_time_ms"
        static let entryPoint = "entry_point"
    }

    var commonProperties: [String: String] {
        [
            Property.editor: currentEditor.rawValue,
            Property.contentType: contentType,
            Property.postType: postType,
            Property.blogID: blogID?.stringValue,
            Property.blogType: blogType,
            Property.sessionId: sessionId,
            Property.hasUnsupportedBlocks: hasUnsupportedBlocks ? "1" : "0"
        ]
        .compactMapValues { $0 }
    }
}

extension PostEditorAnalyticsSession {
    enum Editor: String {
        case gutenberg
        case gutenbergKit = "gutenberg_kit"
        case classic
        case html
    }

    enum ContentType: String {
        case new
        case gutenberg
        case classic

        init(post: AbstractPost) {
            self.init(content: post.content)
        }

        init(content: String?) {
            // A duplication of `BasePost.isContentEmpty`
            let emptyGutenbergParagraph = "<!-- wp:paragraph -->\n<p></p>\n<!-- /wp:paragraph -->"
            if content?.isEmpty != false || content == emptyGutenbergParagraph {
                self = .new
            } else if content?.contains("<!-- wp:") == true {
                self = .gutenberg
            } else {
                self = .classic
            }
        }
    }

    enum Outcome: String {
        case cancel
        case discard
        case save
        case publish
    }
}
