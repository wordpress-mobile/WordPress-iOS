import UITestsFoundation
import XCTest

class EditorGutenbergTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        try await WireMock.setUpScenario(scenario: "new_post_flow")
        setUpTestSuite(selectWPComSite: WPUITestCredentials.testWPcomPaidSite)

        try MySiteScreen()
            .goToBlockEditorScreen()
    }

    let postTitle = "Rich post title"
    let postContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam congue efficitur leo eget porta."
    let videoUrlPath = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    let audioUrlPath = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
}

class EditorGutenbergTests_01: EditorGutenbergTests {
    func testTextPostPublish() throws {
        try BlockEditorScreen()
            .enterTextInTitle(text: postTitle)
            .addParagraphBlock(withText: postContent)
            .verifyContentStructure(blocks: 1, words: postContent.components(separatedBy: " ").count, characters: postContent.count)
            .postAndViewEpilogue(action: .publish)
            .verifyEpilogueDisplays(postTitle: postTitle, siteAddress: WPUITestCredentials.testWPcomPaidSite)
            .tapDone()
    }

    func testUndoRedo() throws {
        try BlockEditorScreen()
            .verifyUndoIsDisabled()
            .verifyRedoIsDisabled()
            .enterTextInTitle(text: postTitle)
            .addParagraphBlock(withText: postContent)
            .verifyContentStructure(blocks: 1, words: postContent.components(separatedBy: " ").count, characters: postContent.count)
            .undo()
            .undo()
            .verifyContentStructure(blocks: 0, words: 0, characters: 0)
            .redo()
            .redo()
            .verifyContentStructure(blocks: 1, words: postContent.components(separatedBy: " ").count, characters: postContent.count)
            .switchToHTMLMode()
            .verifyUndoIsHidden()
            .verifyRedoIsHidden()
            .switchToVisualMode()
            .verifyUndoIsVisible()
            .verifyRedoIsVisible()
    }
}

// The slowest one are in separate for better parallelization
class EditorGutenbergTests_02: EditorGutenbergTests {
    func testBasicPostPublishWithCategoryAndTag() throws {
        try BlockEditorScreen()
            .enterTextInTitle(text: postTitle)
            .addParagraphBlock(withText: postContent)
            .addImage()
            .verifyContentStructure(blocks: 2, words: postContent.components(separatedBy: " ").count, characters: postContent.count)
            .openPostSettings()
            .selectCategory(name: "Wedding")
            .addTag(name: "tag \(Date().toString())")
            .closePostSettings()
            .postAndViewEpilogue(action: .publish)
            .verifyEpilogueDisplays(postTitle: postTitle, siteAddress: WPUITestCredentials.testWPcomPaidSite)
            .tapDone()
    }
}

class EditorGutenbergTests_03: EditorGutenbergTests {
    func testAddRemoveFeaturedImage() throws {
        try BlockEditorScreen()
            .enterTextInTitle(text: postTitle)
            .addParagraphBlock(withText: postContent)
            .verifyContentStructure(blocks: 1, words: postContent.components(separatedBy: " ").count, characters: postContent.count)
            .openPostSettings()
            .setFeaturedImage()
            .verifyPostSettings(hasImage: true)
            .removeFeatureImage()
            .verifyPostSettings(hasImage: false)
            .setFeaturedImage()
            .verifyPostSettings(hasImage: true)
            .closePostSettings()
    }
}

class EditorGutenbergTests_04: EditorGutenbergTests {
    func testAddGalleryBlock() throws {
        try BlockEditorScreen()
            .enterTextInTitle(text: postTitle)
            .addParagraphBlock(withText: postContent)
            .addImageGallery()
            .verifyContentStructure(blocks: 5, words: postContent.components(separatedBy: " ").count, characters: postContent.count)
    }

    func testAddMediaBlocks() throws {
        try BlockEditorScreen()
            .addImage()
            .addVideoFromUrl(urlPath: videoUrlPath)
            .addAudioFromUrl(urlPath: audioUrlPath)
            .verifyMediaBlocksDisplayed()
    }
}
