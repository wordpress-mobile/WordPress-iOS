import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

@MainActor
struct PostEditorRouterTests {
    @Test("selects Core REST for sites using Custom Post Types views")
    func selectsCoreREST() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        blog.isXMLRPCDisabled = true
        #expect(PostEditorRouter.destination(for: blog) == .coreREST)
    }

    @Test("selects legacy for other sites")
    func selectsLegacy() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        blog.isXMLRPCDisabled = false
        #expect(PostEditorRouter.destination(for: blog) == .legacy)
    }

    @Test("converts title content and tags for Core REST")
    func convertsCoreRESTValues() throws {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        let context = NewPostEditorContext(
            title: "Title",
            content: "<!-- wp:paragraph --><p>Body</p><!-- /wp:paragraph -->",
            tags: "swift, ios"
        )

        #expect(try context.makeEditorContent().title == "Title")
        #expect(try context.makeEditorContent().content.contains("Body"))
        #expect(
            context.makePostSettings(for: blog).tags == [
                PostSettings.Term(id: 0, name: "swift"),
                PostSettings.Term(id: 0, name: "ios")
            ]
        )
    }

    @Test("uses voice output instead of seeded content")
    func usesVoiceContent() throws {
        let context = NewPostEditorContext(content: "old", voiceContent: "voice blocks")

        #expect(try context.makeEditorContent().content == "voice blocks")
    }

    @Test("preserves initial media order as Core REST blocks")
    func preservesMediaOrder() throws {
        let contextManager = ContextManager.forTesting()
        let first = MediaBuilder(contextManager.mainContext).build()
        first.mediaID = 1
        first.mediaType = .image
        first.remoteURL = "https://example.com/one.jpg"
        let second = MediaBuilder(contextManager.mainContext).build()
        second.mediaID = 2
        second.mediaType = .video
        second.remoteURL = "https://example.com/two.mp4"

        let html = try NewPostEditorContext(initialMedia: [first, second])
            .makeEditorContent()
            .content
        let firstRange = try #require(html.range(of: "one.jpg"))
        let secondRange = try #require(html.range(of: "two.mp4"))

        #expect(firstRange.lowerBound < secondRange.lowerBound)
        #expect(html.contains("<!-- wp:image"))
        #expect(html.contains("<!-- wp:video"))
    }

    @Test("maps audio and PowerPoint media to Core REST blocks")
    func mapsRemainingMediaTypes() throws {
        let contextManager = ContextManager.forTesting()
        let audio = MediaBuilder(contextManager.mainContext).build()
        audio.mediaID = 3
        audio.mediaType = .audio
        audio.remoteURL = "https://example.com/episode.mp3"
        let presentation = MediaBuilder(contextManager.mainContext).build()
        presentation.mediaID = 4
        presentation.mediaType = .powerpoint
        presentation.filename = "Slides.pptx"
        presentation.remoteURL = "https://example.com/slides.pptx"

        let html = try NewPostEditorContext(initialMedia: [audio, presentation])
            .makeEditorContent()
            .content

        #expect(html.contains("<!-- wp:audio"))
        #expect(html.contains(#"<audio controls src="https://example.com/episode.mp3"></audio>"#))
        #expect(html.contains("<!-- wp:file"))
        #expect(html.contains(#"<a href="https://example.com/slides.pptx">Slides.pptx</a>"#))
    }

    @Test("throws for invalid uploaded Core REST media")
    func rejectsInvalidMedia() {
        let contextManager = ContextManager.forTesting()
        let media = MediaBuilder(contextManager.mainContext).build()
        media.mediaID = 1
        media.mediaType = .image

        var didThrow = false
        do {
            _ = try NewPostEditorContext(initialMedia: [media]).makeEditorContent()
        } catch {
            didThrow = true
        }

        #expect(didThrow)
    }

    @Test("throws for an empty Core REST media URL")
    func rejectsEmptyMediaURL() {
        let contextManager = ContextManager.forTesting()
        let media = MediaBuilder(contextManager.mainContext).build()
        media.mediaID = 1
        media.mediaType = .image
        media.remoteURL = ""

        #expect(throws: (any Error).self) {
            try NewPostEditorContext(initialMedia: [media]).makeEditorContent()
        }
    }

    @Test("throws for a relative Core REST media URL")
    func rejectsRelativeMediaURL() {
        let contextManager = ContextManager.forTesting()
        let media = MediaBuilder(contextManager.mainContext).build()
        media.mediaID = 1
        media.mediaType = .image
        media.remoteURL = "uploads/image.jpg"

        #expect(throws: (any Error).self) {
            try NewPostEditorContext(initialMedia: [media]).makeEditorContent()
        }
    }

    @Test("serializes the normalized Core REST media URL")
    func serializesNormalizedMediaURL() throws {
        let contextManager = ContextManager.forTesting()
        let media = MediaBuilder(contextManager.mainContext).build()
        media.mediaID = 3
        media.mediaType = .document
        media.filename = "July Summary.pdf"
        media.remoteURL = "https://example.com/July Summary.pdf?download=1&source=app"

        let html = try NewPostEditorContext(initialMedia: [media])
            .makeEditorContent()
            .content

        #expect(
            html.contains(
                #"<!-- wp:file {"id":3,"href":"https://example.com/July%20Summary.pdf?download=1&source=app"} -->"#
            )
        )
        #expect(
            html.contains(
                #"<a href="https://example.com/July%20Summary.pdf?download=1&amp;source=app">July Summary.pdf</a>"#
            )
        )
    }

    @Test("preserves blogging prompts through both editor adapters")
    func preservesBloggingPrompt() throws {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        let prompt = try #require(BloggingPrompt.newObject(in: contextManager.mainContext))
        prompt.promptID = 42
        prompt.text = "What did you learn today?"
        prompt.additionalPostTags = ["learning", "daily"]
        let context = NewPostEditorContext(prompt: prompt)

        let settings = context.makePostSettings(for: blog)
        #expect(settings.bloggingPromptID == "42")
        #expect(
            settings.makeCreateParameters().meta?
                .valueForKey(
                    key: "_jetpack_blogging_prompt_key"
                ) == .string("42")
        )
        #expect(try context.makeEditorContent().content.contains(prompt.text))
        #expect(
            settings.tags.map(\.name) == [
                "dailyprompt", "dailyprompt-42", "learning", "daily"
            ]
        )

        let post = blog.createDraftPost()
        context.applyLegacyValues(to: post)
        #expect(post.bloggingPromptID == "42")
        #expect(post.content?.contains(prompt.text) == true)
        #expect(post.tags == "dailyprompt, dailyprompt-42, learning, daily")
    }

    @Test("builds Core REST editor session attribution without a post")
    func buildsCoreRESTEditorSessionAttribution() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        blog.dotComID = 42
        let entryPoint = PostEditorEntryPoint.bloggingPromptsDashboardCard

        let session = PostEditorAnalyticsSession(
            editor: .gutenbergKit,
            blog: blog,
            postType: "post",
            contentType: .new,
            entryPoint: entryPoint
        )

        #expect(session.blogID == 42)
        #expect(session.postType == "post")
        #expect(session.contentType == PostEditorAnalyticsSession.ContentType.new.rawValue)
        #expect(session.entryPoint == entryPoint)
        #expect(session.started == false)
    }

    @Test("runs the Core REST dismissal callback once after view disappearance")
    func callsCoreRESTDismissalOnceAfterViewDisappears() {
        var callbackCount = 0
        let controller = CoreRESTPostEditorHostingController {
            callbackCount += 1
        }

        #expect(callbackCount == 0)
        controller.viewDidDisappear(false)
        controller.viewDidDisappear(false)
        #expect(callbackCount == 1)
    }

    @Test("applies values through the legacy adapter")
    func appliesLegacyPostValues() {
        let contextManager = ContextManager.forTesting()
        let blog = BlogBuilder(contextManager.mainContext).build()
        let context = NewPostEditorContext(title: "Title", content: "Body", tags: "swift")
        let post = blog.createDraftPost()
        context.applyLegacyValues(to: post)

        #expect(post.postTitle == "Title")
        #expect(post.content == "Body")
        #expect(post.tags == "swift")
    }
}
