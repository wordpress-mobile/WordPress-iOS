import XCTest
@testable import WordPress

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
        XCTAssertEqual(nestedBlock1.parentBlock?.content, parentBlock.content, "Should have a parent block and matches parent's content")

        XCTAssertEqual(nestedBlock2.name, "wp:nested-block", "Name should match block's name")
        XCTAssertEqual(nestedBlock2.content, expectedNestedBlock2Content, "Content should match block's content")
        XCTAssertEqual(nestedBlock2.attributes.count, 2, "Attributes should contain two items")
        XCTAssertEqual(nestedBlock2.attributes["id"] as? Int, 2, "Id attribute matches block's attribute")
        XCTAssertEqual(nestedBlock2.attributes["name"] as? String, "block2", "Name attribute matches block's attribute")
        XCTAssertEqual(nestedBlock2.blocks.count, 0, "Shouldn't contain nested blocks")
        XCTAssertEqual(nestedBlock2.parentBlock?.content, parentBlock.content, "Should have a parent block and matches parent's content")
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
}
