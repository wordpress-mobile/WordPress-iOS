import XCTest
@testable import GutenbergProcessors
import SwiftSoup

class GutenbergContentParserTests: XCTestCase {
    let singleBlock = """
        <!-- wp:block {"id":1} -->
        <div class="wp-block"><p>Hello world!</p></div>
        <!-- /wp:block -->
        """

    let nestedBlock = """
        <!-- wp:parent-block {"name":"parent"} -->
        <div class="wp-block parent-block">
            <div class="wrapper">
                <h1>Title</h1>

                <!-- wp:nested-block {"id":1,"name":"block1"} -->
                <figure class="wp-block"><p>This is a nested block.</p></figure>
                <!-- /wp:nested-block -->

                <hr />

                <h2>Subtitle</h2>

                <!-- wp:nested-block {"id":2,"name":"block2"} -->
                <figure class="wp-block"><p>This is another nested block.</p></figure>
                <!-- /wp:nested-block -->

                <p>Footer</p>
            </div>
        </div>
        <!-- /wp:parent-block -->
        """

    func testParserSingleBlock() {
        let parser = GutenbergContentParser(for: singleBlock)
        let blocks = parser.blocks

        let expectedBlockContent = """
            <div class="wp-block"><p>Hello world!</p></div>
            """

        XCTAssertEqual(blocks.count, 1, "Should return one block")

        XCTAssertEqual(blocks[0].name, "wp:block", "Name should match block's name")
        XCTAssertEqual(blocks[0].content, expectedBlockContent, "Content should match block's content")
        XCTAssertEqual(blocks[0].attributes.count, 1, "Attributes should contain one item")
        XCTAssertEqual(blocks[0].attributes["id"] as? Int, 1, "Id attribute matches block's attribute")
        XCTAssertEqual(blocks[0].blocks.count, 0, "Shouldn't contain nested blocks")
    }

    func testParserSingleBlockToHTML() {
        let parser = GutenbergContentParser(for: singleBlock)
        XCTAssertEqual(parser.html(), singleBlock, "Parsed content should match the original HTML")
    }

    func testParserNestedBlock() {
        let parser = GutenbergContentParser(for: nestedBlock)
        let blocks = parser.blocks

        let expectedParentBlockContent = """
            <div class="wp-block parent-block">
                <div class="wrapper">
                    <h1>Title</h1>

                    <!-- wp:nested-block {"id":1,"name":"block1"} -->
                    <figure class="wp-block"><p>This is a nested block.</p></figure>
                    <!-- /wp:nested-block -->

                    <hr />

                    <h2>Subtitle</h2>

                    <!-- wp:nested-block {"id":2,"name":"block2"} -->
                    <figure class="wp-block"><p>This is another nested block.</p></figure>
                    <!-- /wp:nested-block -->

                    <p>Footer</p>
                </div>
            </div>
            """
        let expectedNestedBlock1Content = """
            <figure class="wp-block"><p>This is a nested block.</p></figure>
            """
        let expectedNestedBlock2Content = """
            <figure class="wp-block"><p>This is another nested block.</p></figure>
            """

        let parentBlock = blocks[0]
        let nestedBlock1 = parentBlock.blocks[0]
        let nestedBlock2 = parentBlock.blocks[1]

        XCTAssertEqual(blocks.count, 3, "Should return parent block and nested blocks")
        XCTAssertEqual(blocks[1].content, nestedBlock1.content, "Nested block is present at root level")
        XCTAssertEqual(blocks[2].content, nestedBlock2.content, "Nested block is present at root level")

        XCTAssertEqual(parentBlock.name, "wp:parent-block", "Name should match block's name")
        XCTAssertEqual(parentBlock.content, expectedParentBlockContent, "Content should match block's content")
        XCTAssertEqual(parentBlock.attributes.count, 1, "Attributes should contain one item")
        XCTAssertEqual(parentBlock.attributes["name"] as? String, "parent", "Name attribute matches block's attribute")
        XCTAssertEqual(parentBlock.blocks.count, 2, "Should contain nested blocks")

        XCTAssertEqual(nestedBlock1.name, "wp:nested-block", "Name should match block's name")
        XCTAssertEqual(nestedBlock1.content, expectedNestedBlock1Content, "Content should match block's content")
        XCTAssertEqual(nestedBlock1.attributes.count, 2, "Attributes should contain two items")
        XCTAssertEqual(nestedBlock1.attributes["id"] as? Int, 1, "Id attribute matches block's attribute")
        XCTAssertEqual(nestedBlock1.attributes["name"] as? String, "block1", "Name attribute matches block's attribute")
        XCTAssertEqual(nestedBlock1.blocks.count, 0, "Shouldn't contain nested blocks")
        XCTAssertEqual(
            nestedBlock1.parentBlock?.content,
            parentBlock.content,
            "Should have a parent block and matches parent's content"
        )

        XCTAssertEqual(nestedBlock2.name, "wp:nested-block", "Name should match block's name")
        XCTAssertEqual(nestedBlock2.content, expectedNestedBlock2Content, "Content should match block's content")
        XCTAssertEqual(nestedBlock2.attributes.count, 2, "Attributes should contain two items")
        XCTAssertEqual(nestedBlock2.attributes["id"] as? Int, 2, "Id attribute matches block's attribute")
        XCTAssertEqual(nestedBlock2.attributes["name"] as? String, "block2", "Name attribute matches block's attribute")
        XCTAssertEqual(nestedBlock2.blocks.count, 0, "Shouldn't contain nested blocks")
        XCTAssertEqual(
            nestedBlock2.parentBlock?.content,
            parentBlock.content,
            "Should have a parent block and matches parent's content"
        )
    }

    func testParserNestedBlockToHTML() {
        let parser = GutenbergContentParser(for: nestedBlock)
        XCTAssertEqual(parser.html(), nestedBlock, "Parsed content should match the original HTML")
    }

    func testParserModifyAttributes() {
        let parser = GutenbergContentParser(for: nestedBlock)
        let blocks = parser.blocks
        let parentBlock = blocks[0]
        parentBlock.attributes["name"] = "new-parent"
        parentBlock.attributes["newId"] = 1001

        let expectedResult = """
            <!-- wp:parent-block {"name":"new-parent","newId":1001} -->
            <div class="wp-block parent-block">
                <div class="wrapper">
                    <h1>Title</h1>

                    <!-- wp:nested-block {"id":1,"name":"block1"} -->
                    <figure class="wp-block"><p>This is a nested block.</p></figure>
                    <!-- /wp:nested-block -->

                    <hr />

                    <h2>Subtitle</h2>

                    <!-- wp:nested-block {"id":2,"name":"block2"} -->
                    <figure class="wp-block"><p>This is another nested block.</p></figure>
                    <!-- /wp:nested-block -->

                    <p>Footer</p>
                </div>
            </div>
            <!-- /wp:parent-block -->
            """

        XCTAssertEqual(parser.html(), expectedResult, "Parsed content should contain the modifications")
    }

    func testParserModifyHTML() {
        let parser = GutenbergContentParser(for: nestedBlock)
        let blocks = parser.blocks
        let parentBlock = blocks[0]
        try! parentBlock.elements.select("div").first()?.addClass("new-class")

        let expectedResult = """
            <!-- wp:parent-block {"name":"parent"} -->
            <div class="wp-block parent-block new-class">
                <div class="wrapper">
                    <h1>Title</h1>

                    <!-- wp:nested-block {"id":1,"name":"block1"} -->
                    <figure class="wp-block"><p>This is a nested block.</p></figure>
                    <!-- /wp:nested-block -->

                    <hr />

                    <h2>Subtitle</h2>

                    <!-- wp:nested-block {"id":2,"name":"block2"} -->
                    <figure class="wp-block"><p>This is another nested block.</p></figure>
                    <!-- /wp:nested-block -->

                    <p>Footer</p>
                </div>
            </div>
            <!-- /wp:parent-block -->
            """

        XCTAssertEqual(parser.html(), expectedResult, "Parsed content should contain the modifications")
    }

    // MARK: - Serialization contract

    func testVoidElementsAreSelfClosed() {
        let input = """
            <!-- wp:x -->
            <div><hr><input type="text" required></div>
            <!-- /wp:x -->
            """
        let expected = """
            <!-- wp:x -->
            <div><hr /><input type="text" required /></div>
            <!-- /wp:x -->
            """
        XCTAssertEqual(GutenbergContentParser(for: input).html(), expected)
    }

    func testEntitiesArePreserved() {
        let content = """
            <!-- wp:x -->
            <a href="?a=1&amp;b=2">Fish &amp; chips</a>
            <!-- /wp:x -->
            """
        XCTAssertEqual(GutenbergContentParser(for: content).html(), content)
    }

    func testRawTextElementsAreNotEscaped() {
        // Regressing here would corrupt Custom HTML / embedded scripts.
        let content = """
            <!-- wp:html -->
            <script>if (1 < 2 && 3 > 2) { doThing(); }</script>
            <!-- /wp:html -->
            """
        XCTAssertTrue(GutenbergContentParser(for: content).html().contains("1 < 2 && 3 > 2"))
    }

    func testPreformattedWhitespaceIsPreserved() {
        let content = """
            <!-- wp:preformatted -->
            <pre>line one
              indented	tabbed</pre>
            <!-- /wp:preformatted -->
            """
        XCTAssertEqual(GutenbergContentParser(for: content).html(), content)
    }

    func testUnicodeIsPreserved() {
        let content = """
            <!-- wp:x -->
            <p>café ☕ 日本語 — Alşksdf</p>
            <!-- /wp:x -->
            """
        XCTAssertEqual(GutenbergContentParser(for: content).html(), content)
    }

    func testContentWithoutBlockCommentsIsPassedThrough() {
        let content = "<p>hello world</p>"
        XCTAssertEqual(GutenbergContentParser(for: content).html(), content)
    }

    func testEmptyContentProducesEmptyOutput() {
        XCTAssertTrue(GutenbergContentParser(for: "").html().isEmpty)
    }

    func testMultipleSiblingBlocksArePreserved() {
        let content = """
            <!-- wp:a -->
            <p>one</p>
            <!-- /wp:a -->
            <!-- wp:b -->
            <p>two</p>
            <!-- /wp:b -->
            """
        XCTAssertEqual(GutenbergContentParser(for: content).html(), content)
    }

    func testHTMLIsIdempotent() {
        let parser = GutenbergContentParser(for: singleBlock)
        XCTAssertEqual(parser.html(), parser.html())
    }

    // MARK: - Mutation propagation (SwiftSoup 2.12+ serialization-cache regression)

    func testModifyNestedElementAttribute() throws {
        // The mutated <img> is nested inside <figure>; unlike a top-level element,
        // its change is dropped by SwiftSoup 2.12+ unless html() re-renders it.
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:image -->
                <figure><img src="local://old.jpg"/></figure>
                <!-- /wp:image -->
                """
        )
        let image = try XCTUnwrap(parser.blocks.first?.elements.select("img").first())
        try image.attr("src", "https://example.com/new.jpg")

        let output = parser.html()
        XCTAssertTrue(output.contains("src=\"https://example.com/new.jpg\""))
        XCTAssertFalse(output.contains("local://old.jpg"))
    }

    func testModifyDeeplyNestedElement() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:gallery -->
                <figure><ul><li><a href="old"><img src="local://old.jpg"/></a></li></ul></figure>
                <!-- /wp:gallery -->
                """
        )
        let image = try XCTUnwrap(parser.blocks.first?.elements.select("img").first())
        try image.attr("src", "https://example.com/deep.jpg")

        XCTAssertTrue(parser.html().contains("https://example.com/deep.jpg"))
    }

    // MARK: - Attribute parsing

    func testMissingAttributesParseToEmptyDictionary() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:spacer -->
                <div></div>
                <!-- /wp:spacer -->
                """
        )
        XCTAssertTrue(try XCTUnwrap(parser.blocks.first).attributes.isEmpty)
    }

    func testMalformedAttributesParseToEmptyDictionary() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:x {not valid json} -->
                <div></div>
                <!-- /wp:x -->
                """
        )
        XCTAssertTrue(try XCTUnwrap(parser.blocks.first).attributes.isEmpty)
    }

    func testWrittenAttributesEscapeSlashesAndSortKeys() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:file -->
                <div></div>
                <!-- /wp:file -->
                """
        )
        try XCTUnwrap(parser.blocks.first).attributes = ["id": 100, "href": "https://example.com/f.pdf"]
        // JSONSerialization `.sortedKeys` orders "href" before "id" and escapes slashes.
        XCTAssertTrue(parser.html().contains(#"{"href":"https:\/\/example.com\/f.pdf","id":100}"#))
    }
}
