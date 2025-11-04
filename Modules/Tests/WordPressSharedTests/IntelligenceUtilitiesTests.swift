import Testing
@testable import WordPressShared

struct IntelligenceUtilitiesTests {
    @Test func extractRelevantText() throws {
        let text = try IntelligenceUtilities.extractRelevantText(from: IntelligenceUtilities.post)

        #expect(text == """
        <h1>The Art of Making Perfect Sourdough Bread at Home</h1>
        <p>After years of trial and error, I've finally cracked the code to making restaurant-quality sourdough bread in my own kitchen. Today, I'm sharing everything I've learned about this ancient craft that has seen a remarkable revival in recent years.</p>
        <img alt="A golden-brown sourdough loaf with a crispy crust">
        <figcaption>My latest sourdough creation - crusty on the outside, soft and airy inside</figcaption>
        <h2>Why Sourdough?</h2>
        <p>Sourdough bread isn't just a trendy food item - it's a healthier alternative to commercial bread. The natural fermentation process breaks down gluten, making it easier to digest, while also creating that distinctive tangy flavor we all love.</p>
        <li>Better digestibility due to fermentation</li>
        <li>Lower glycemic index than regular bread</li>
        <li>No commercial yeast required</li>
        <li>Incredible depth of flavor</li>
        <li>Longer shelf life naturally</li>
        <h2>Essential Equipment</h2>
        <p>You don't need fancy equipment to get started, but a few key tools will make your journey much easier:</p>
        <h3>Must-Haves</h3>
        <li>Kitchen scale</li>
        <li>Mixing bowls</li>
        <li>Bench scraper</li>
        <li>Dutch oven</li>
        <h3>Nice-to-Haves</h3>
        <li>Banneton proofing basket</li>
        <li>Lame (scoring tool)</li>
        <li>Dough whisk</li>
        <li>Thermometer</li>
        <blockquote>"The secret to great sourdough isn't just in the recipe - it's in understanding the rhythm of fermentation and learning to read your dough." - Sarah Mitchell, Artisan Baker</blockquote>
        <h2>My Go-To Recipe</h2>
        <p>This recipe yields one large loaf and has never failed me. The key is maintaining consistent temperatures and being patient with the process.</p>
        <th>Ingredient</th>
        <th>Amount</th>
        <th>Baker's Percentage</th>
        <td>Bread flour</td>
        <td>500g</td>
        <td>100%</td>
        <td>Water</td>
        <td>375g</td>
        <td>75%</td>
        <td>Starter</td>
        <td>100g</td>
        <td>20%</td>
        <td>Salt</td>
        <td>10g</td>
        <td>2%</td>
        """)
    }

    /// Blockquote contain nested block and the implementation should account for that.
    @Test func blockquotes() throws {
        let text = try IntelligenceUtilities.extractRelevantText(from: """
        <!-- wp:paragraph -->
        <p>Welcome to <strong><em>WordPress</em></strong>! This is your first post. Edit or delete it to take the first step in your blogging journey.</p>
        <!-- /wp:paragraph -->
        <!-- wp:quote -->
        <blockquote class="wp-block-quote"><!-- wp:quote -->
        <blockquote class="wp-block-quote"><!-- wp:quote -->
        <blockquote class="wp-block-quote"><!-- wp:paragraph -->
        <p>Welcome to <strong><em>WordPress</em></strong>!</p>
        <!-- /wp:paragraph --></blockquote>
        <!-- /wp:quote --></blockquote>
        <!-- /wp:quote --></blockquote>
        <!-- /wp:quote -->
        """)

        print(text)
    }

    @Test func extractRelevantTextFromPlainText() throws {
        let text = try IntelligenceUtilities.extractRelevantText(from: "This is a plain text post")

        #expect(text == "This is a plain text post")
    }
}

extension IntelligenceUtilities {
    static let post = """
    <!-- wp:heading {"level":1} -->
    <h1>The Art of Making Perfect Sourdough Bread at Home</h1>
    <!-- /wp:heading -->

    <!-- wp:paragraph -->
    <p>After years of trial and error, I've finally cracked the code to making restaurant-quality sourdough bread in my own kitchen. Today, I'm sharing everything I've learned about this ancient craft that has seen a remarkable revival in recent years.</p>
    <!-- /wp:paragraph -->

    <!-- wp:image {"id":1234,"sizeSlug":"large","linkDestination":"none"} -->
    <figure class="wp-block-image size-large"><img src="sourdough-loaf.jpg" alt="A golden-brown sourdough loaf with a crispy crust" class="wp-image-1234"/><figcaption>My latest sourdough creation - crusty on the outside, soft and airy inside</figcaption></figure>
    <!-- /wp:image -->

    <!-- wp:heading {"level":2} -->
    <h2>Why Sourdough?</h2>
    <!-- /wp:heading -->

    <!-- wp:paragraph -->
    <p>Sourdough bread isn't just a trendy food item - it's a healthier alternative to commercial bread. The natural fermentation process breaks down gluten, making it easier to digest, while also creating that distinctive tangy flavor we all love.</p>
    <!-- /wp:paragraph -->

    <!-- wp:list -->
    <ul>
    <li>Better digestibility due to fermentation</li>
    <li>Lower glycemic index than regular bread</li>
    <li>No commercial yeast required</li>
    <li>Incredible depth of flavor</li>
    <li>Longer shelf life naturally</li>
    </ul>
    <!-- /wp:list -->

    <!-- wp:heading {"level":2} -->
    <h2>Essential Equipment</h2>
    <!-- /wp:heading -->

    <!-- wp:paragraph -->
    <p>You don't need fancy equipment to get started, but a few key tools will make your journey much easier:</p>
    <!-- /wp:paragraph -->

    <!-- wp:columns -->
    <div class="wp-block-columns">
    <!-- wp:column -->
    <div class="wp-block-column">
    <!-- wp:heading {"level":3} -->
    <h3>Must-Haves</h3>
    <!-- /wp:heading -->

    <!-- wp:list -->
    <ul>
    <li>Kitchen scale</li>
    <li>Mixing bowls</li>
    <li>Bench scraper</li>
    <li>Dutch oven</li>
    </ul>
    <!-- /wp:list -->
    </div>
    <!-- /wp:column -->

    <!-- wp:column -->
    <div class="wp-block-column">
    <!-- wp:heading {"level":3} -->
    <h3>Nice-to-Haves</h3>
    <!-- /wp:heading -->

    <!-- wp:list -->
    <ul>
    <li>Banneton proofing basket</li>
    <li>Lame (scoring tool)</li>
    <li>Dough whisk</li>
    <li>Thermometer</li>
    </ul>
    <!-- /wp:list -->
    </div>
    <!-- /wp:column -->
    </div>
    <!-- /wp:columns -->

    <!-- wp:quote -->
    <blockquote class="wp-block-quote">
    <p>"The secret to great sourdough isn't just in the recipe - it's in understanding the rhythm of fermentation and learning to read your dough."</p>
    <cite>- Sarah Mitchell, Artisan Baker</cite>
    </blockquote>
    <!-- /wp:quote -->

    <!-- wp:heading {"level":2} -->
    <h2>My Go-To Recipe</h2>
    <!-- /wp:heading -->

    <!-- wp:paragraph -->
    <p>This recipe yields one large loaf and has never failed me. The key is maintaining consistent temperatures and being patient with the process.</p>
    <!-- /wp:paragraph -->

    <!-- wp:table -->
    <figure class="wp-block-table"><table>
    <thead>
    <tr>
    <th>Ingredient</th>
    <th>Amount</th>
    <th>Baker's Percentage</th>
    </tr>
    </thead>
    <tbody>
    <tr>
    <td>Bread flour</td>
    <td>500g</td>
    <td>100%</td>
    </tr>
    <tr>
    <td>Water</td>
    <td>375g</td>
    <td>75%</td>
    </tr>
    <tr>
    <td>Starter</td>
    <td>100g</td>
    <td>20%</td>
    </tr>
    <tr>
    <td>Salt</td>
    <td>10g</td>
    <td>2%</td>
    </tr>
    </tbody>
    </table></figure>
    <!-- /wp:table -->

    <!-- wp:separator -->
    <hr class="wp-block-separator"/>
    <!-- /wp:separator -->

    <!-- wp:buttons -->
    <div class="wp-block-buttons">
    <!-- wp:button -->
    <div class="wp-block-button"><a class="wp-block-button__link">Download Recipe PDF</a></div>
    <!-- /wp:button -->
    </div>
    <!-- /wp:buttons -->
    """
}
