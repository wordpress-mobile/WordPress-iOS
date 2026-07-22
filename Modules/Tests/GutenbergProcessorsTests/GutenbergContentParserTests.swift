import Testing
@testable import GutenbergProcessors
import SwiftSoup

struct GutenbergContentParserTests {
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

    @Test func testParserSingleBlock() {
        let parser = GutenbergContentParser(for: singleBlock)
        let blocks = parser.blocks

        let expectedBlockContent = """
            <div class="wp-block"><p>Hello world!</p></div>
            """

        #expect(blocks.count == 1, "Should return one block")

        #expect(blocks[0].name == "wp:block", "Name should match block's name")
        #expect(blocks[0].content == expectedBlockContent, "Content should match block's content")
        #expect(blocks[0].attributes.count == 1, "Attributes should contain one item")
        #expect((blocks[0].attributes["id"] as? Int) == 1, "Id attribute matches block's attribute")
        #expect(blocks[0].blocks.isEmpty, "Shouldn't contain nested blocks")
    }

    @Test func testParserSingleBlockToHTML() {
        let parser = GutenbergContentParser(for: singleBlock)
        #expect(parser.html() == singleBlock, "Parsed content should match the original HTML")
    }

    @Test func testParserNestedBlock() {
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

        #expect(blocks.count == 3, "Should return parent block and nested blocks")
        #expect(blocks[1].content == nestedBlock1.content, "Nested block is present at root level")
        #expect(blocks[2].content == nestedBlock2.content, "Nested block is present at root level")

        #expect(parentBlock.name == "wp:parent-block", "Name should match block's name")
        #expect(parentBlock.content == expectedParentBlockContent, "Content should match block's content")
        #expect(parentBlock.attributes.count == 1, "Attributes should contain one item")
        #expect((parentBlock.attributes["name"] as? String) == "parent", "Name attribute matches block's attribute")
        #expect(parentBlock.blocks.count == 2, "Should contain nested blocks")

        #expect(nestedBlock1.name == "wp:nested-block", "Name should match block's name")
        #expect(nestedBlock1.content == expectedNestedBlock1Content, "Content should match block's content")
        #expect(nestedBlock1.attributes.count == 2, "Attributes should contain two items")
        #expect((nestedBlock1.attributes["id"] as? Int) == 1, "Id attribute matches block's attribute")
        #expect((nestedBlock1.attributes["name"] as? String) == "block1", "Name attribute matches block's attribute")
        #expect(nestedBlock1.blocks.isEmpty, "Shouldn't contain nested blocks")
        #expect(
            nestedBlock1.parentBlock?.content == parentBlock.content,
            "Should have a parent block and matches parent's content"
        )

        #expect(nestedBlock2.name == "wp:nested-block", "Name should match block's name")
        #expect(nestedBlock2.content == expectedNestedBlock2Content, "Content should match block's content")
        #expect(nestedBlock2.attributes.count == 2, "Attributes should contain two items")
        #expect((nestedBlock2.attributes["id"] as? Int) == 2, "Id attribute matches block's attribute")
        #expect((nestedBlock2.attributes["name"] as? String) == "block2", "Name attribute matches block's attribute")
        #expect(nestedBlock2.blocks.isEmpty, "Shouldn't contain nested blocks")
        #expect(
            nestedBlock2.parentBlock?.content == parentBlock.content,
            "Should have a parent block and matches parent's content"
        )
    }

    @Test func testParserNestedBlockToHTML() {
        let parser = GutenbergContentParser(for: nestedBlock)
        #expect(parser.html() == nestedBlock, "Parsed content should match the original HTML")
    }

    @Test func testParserModifyAttributes() {
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

        #expect(parser.html() == expectedResult, "Parsed content should contain the modifications")
    }

    @Test func testParserModifyHTML() {
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

        #expect(parser.html() == expectedResult, "Parsed content should contain the modifications")
    }

    // MARK: - Serialization contract

    @Test func testVoidElementsAreSelfClosed() {
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
        #expect(GutenbergContentParser(for: input).html() == expected)
    }

    @Test func testEntitiesArePreserved() {
        let content = """
            <!-- wp:x -->
            <a href="?a=1&amp;b=2">Fish &amp; chips</a>
            <!-- /wp:x -->
            """
        #expect(GutenbergContentParser(for: content).html() == content)
    }

    @Test func testRawTextElementsAreNotEscaped() {
        // Regressing here would corrupt Custom HTML / embedded scripts.
        let content = """
            <!-- wp:html -->
            <script>if (1 < 2 && 3 > 2) { doThing(); }</script>
            <!-- /wp:html -->
            """
        #expect(GutenbergContentParser(for: content).html().contains("1 < 2 && 3 > 2"))
    }

    @Test func testPreformattedWhitespaceIsPreserved() {
        let content = """
            <!-- wp:preformatted -->
            <pre>line one
              indented	tabbed</pre>
            <!-- /wp:preformatted -->
            """
        #expect(GutenbergContentParser(for: content).html() == content)
    }

    @Test func testUnicodeIsPreserved() {
        let content = """
            <!-- wp:x -->
            <p>café ☕ 日本語 — Alşksdf</p>
            <!-- /wp:x -->
            """
        #expect(GutenbergContentParser(for: content).html() == content)
    }

    @Test func testContentWithoutBlockCommentsIsPassedThrough() {
        let content = "<p>hello world</p>"
        #expect(GutenbergContentParser(for: content).html() == content)
    }

    @Test func testEmptyContentProducesEmptyOutput() {
        #expect(GutenbergContentParser(for: "").html().isEmpty)
    }

    @Test func testMultipleSiblingBlocksArePreserved() {
        let content = """
            <!-- wp:a -->
            <p>one</p>
            <!-- /wp:a -->
            <!-- wp:b -->
            <p>two</p>
            <!-- /wp:b -->
            """
        #expect(GutenbergContentParser(for: content).html() == content)
    }

    @Test func testHTMLIsIdempotent() {
        let parser = GutenbergContentParser(for: singleBlock)
        #expect(parser.html() == parser.html())
    }

    // MARK: - Mutation propagation (SwiftSoup 2.12+ serialization-cache regression)

    @Test func testModifyNestedElementAttribute() throws {
        // The mutated <img> is nested inside <figure>; unlike a top-level element,
        // its change is dropped by SwiftSoup 2.12+ unless html() re-renders it.
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:image -->
                <figure><img src="local://old.jpg"/></figure>
                <!-- /wp:image -->
                """
        )
        let image = try #require(parser.blocks.first?.elements.select("img").first())
        try image.attr("src", "https://example.com/new.jpg")

        let output = parser.html()
        #expect(output.contains("src=\"https://example.com/new.jpg\""))
        #expect(!(output.contains("local://old.jpg")))
    }

    @Test func testModifyDeeplyNestedElement() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:gallery -->
                <figure><ul><li><a href="old"><img src="local://old.jpg"/></a></li></ul></figure>
                <!-- /wp:gallery -->
                """
        )
        let image = try #require(parser.blocks.first?.elements.select("img").first())
        try image.attr("src", "https://example.com/deep.jpg")

        #expect(parser.html().contains("https://example.com/deep.jpg"))
    }

    // MARK: - Attribute parsing

    @Test func testMissingAttributesParseToEmptyDictionary() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:spacer -->
                <div></div>
                <!-- /wp:spacer -->
                """
        )
        #expect(try #require(parser.blocks.first).attributes.isEmpty)
    }

    @Test func testMalformedAttributesParseToEmptyDictionary() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:x {not valid json} -->
                <div></div>
                <!-- /wp:x -->
                """
        )
        #expect(try #require(parser.blocks.first).attributes.isEmpty)
    }

    @Test func testWrittenAttributesEscapeSlashesAndSortKeys() throws {
        let parser = GutenbergContentParser(
            for: """
                <!-- wp:file -->
                <div></div>
                <!-- /wp:file -->
                """
        )
        try #require(parser.blocks.first).attributes = ["id": 100, "href": "https://example.com/f.pdf"]
        // JSONSerialization `.sortedKeys` orders "href" before "id" and escapes slashes.
        #expect(parser.html().contains(#"{"href":"https:\/\/example.com\/f.pdf","id":100}"#))
    }
}
