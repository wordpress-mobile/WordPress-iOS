import Foundation
import NaturalLanguage

/// Test content with title and body for intelligence service tests.
struct TestContent {
    let title: String
    let content: String
    let languageCode: NLLanguage
}

/// Shared test data for intelligence service tests.
///
/// This enum provides sample content in multiple languages for testing
/// excerpt generation, post summarization, and tag suggestion features.
enum TestData {
    // MARK: - English Content

    static let englishPostWithHTML = TestContent(
        title: "English Post with HTML",
        content: """
        <!-- wp:heading {"level":1} -->
        <h1>The Art of Sourdough Bread Making</h1>
        <!-- /wp:heading -->

        <!-- wp:paragraph -->
        <p>Sourdough bread has experienced a remarkable revival in recent years, with home bakers
        around the world rediscovering this ancient craft. The natural fermentation process creates
        a distinctive tangy flavor and numerous health benefits that make it worth the extra effort.</p>
        <!-- /wp:paragraph -->

        <!-- wp:heading {"level":2} -->
        <h2>Essential Ingredients</h2>
        <!-- /wp:heading -->

        <!-- wp:list -->
        <ul>
        <li>Active sourdough starter</li>
        <li>500g bread flour</li>
        <li>350ml filtered water</li>
        <li>10g sea salt</li>
        <li>Optional: seeds or grains for texture</li>
        </ul>
        <!-- /wp:list -->

        <!-- wp:paragraph -->
        <p>The key to successful sourdough lies in maintaining a healthy starter culture and
        understanding the fermentation process. Temperature and timing are crucial factors that
        will determine the final texture and flavor of your bread.</p>
        <!-- /wp:paragraph -->
        """,
        languageCode: .english
    )

    static let veryShortEnglishContent = TestContent(
        title: "Very Short English Content",
        content: "Artificial intelligence is transforming our world in unprecedented ways.",
        languageCode: .english
    )

    // MARK: - Spanish Content

    static let spanishPost = TestContent(
        title: "Spanish Post",
        content: """
        La paella valenciana es uno de los platos más emblemáticos de la gastronomía española.
        Originaria de Valencia, esta receta tradicional combina arroz, azafrán, y una variedad
        de ingredientes que pueden incluir pollo, conejo, judías verdes, y garrofón.

        La clave para una paella perfecta está en el sofrito inicial y en el punto exacto del arroz.
        El azafrán no solo aporta ese característico color dorado, sino también un sabor único
        e inconfundible.

        Es importante utilizar un buen caldo casero y arroz de calidad, preferiblemente de la
        variedad bomba o senia. El fuego debe ser fuerte al principio y suave al final para
        conseguir el socarrat, esa capa crujiente de arroz que se forma en el fondo de la paellera.
        """,
        languageCode: .spanish
    )

    static let spanishReaderArticle = TestContent(
        title: "Spanish Reader Article",
        content: """
        El cambio climático está afectando de manera significativa a los ecosistemas marinos
        del Mediterráneo. Científicos del CSIC han documentado un aumento de 2 grados en la
        temperatura media del agua durante los últimos 30 años, lo que ha provocado cambios
        en las rutas migratorias de varias especies de peces y la proliferación de especies
        invasoras procedentes de aguas más cálidas.
        """,
        languageCode: .spanish
    )

    // MARK: - English Content

    static let englishTechPost = TestContent(
        title: "English Tech Post",
        content: """
        Quantum computing represents a paradigm shift in how we approach computational problems. Unlike
        classical computers that use bits (0s and 1s), quantum computers leverage qubits that can exist
        in superposition, simultaneously representing multiple states.

        This fundamental difference enables quantum computers to tackle problems that are intractable
        for classical machines. Drug discovery, cryptography, optimization, and climate modeling are
        just a few domains poised for revolutionary breakthroughs.

        However, significant challenges remain. Quantum systems are incredibly fragile, requiring
        near-absolute-zero temperatures and isolation from environmental interference. Error correction
        is another major hurdle, as quantum states are prone to decoherence.
        """,
        languageCode: .english
    )

    static let englishAcademicPost = TestContent(
        title: "English Academic Post",
        content: """
        The phenomenon of linguistic relativity, often referred to as the Sapir-Whorf hypothesis,
        posits that the structure of a language influences its speakers' worldview and cognition.
        While the strong version of this hypothesis has been largely discredited, contemporary research
        suggests more nuanced relationships between language and thought.

        Recent studies in cognitive linguistics have demonstrated that language can indeed affect
        perception and categorization, particularly in domains like color perception, spatial reasoning,
        and temporal cognition. However, these effects are context-dependent and vary significantly
        across different cognitive domains.

        Cross-linguistic research continues to provide valuable insights into the universal and
        language-specific aspects of human cognition, challenging researchers to refine their
        theoretical frameworks and methodological approaches.
        """,
        languageCode: .english
    )

    static let englishStoryPost = TestContent(
        title: "English Story Post",
        content: """
        The old lighthouse keeper had seen many storms in his forty years tending the beacon, but
        none quite like the tempest that rolled in that October evening. Dark clouds gathered on
        the horizon like an invading army, their edges tinged with an unsettling green hue.

        As the first drops of rain pelted the lighthouse windows, Magnus checked the lamp one final
        time. The beam cut through the gathering darkness, a lifeline for any vessels brave or foolish
        enough to be out on such a night. He'd heard the coastguard warnings on the radio—winds
        exceeding 90 miles per hour, waves reaching heights of 30 feet.

        Down in the keeper's quarters, Magnus brewed strong coffee and settled into his worn leather
        chair. Outside, the wind howled like a wounded beast, but within these thick stone walls,
        he felt safe. This lighthouse had withstood two centuries of nature's fury; it would stand
        through one more night.
        """,
        languageCode: .english
    )

    static let englishPost = TestContent(
        title: "English Post",
        content: """
        Sourdough bread has experienced a remarkable revival in recent years, with home bakers
        around the world rediscovering this ancient craft. The natural fermentation process
        creates a distinctive tangy flavor and numerous health benefits.

        The key to successful sourdough lies in maintaining a healthy starter culture. This
        living mixture of flour and water harbors wild yeast and beneficial bacteria that
        work together to leaven the bread and develop complex flavors.

        Temperature and timing are crucial factors. The fermentation process can take anywhere
        from 12 to 24 hours, depending on ambient temperature and the activity of your starter.
        """,
        languageCode: .english
    )

    static let englishReaderArticle = TestContent(
        title: "English Reader Article",
        content: """
        Recent advances in quantum computing have brought us closer to solving complex problems
        that are impossible for classical computers. Google's quantum processor achieved
        quantum supremacy by performing a calculation in 200 seconds that would take the world's
        fastest supercomputer 10,000 years to complete. However, practical applications for
        everyday computing are still years away.
        """,
        languageCode: .english
    )

    // MARK: - French Content

    static let frenchPost = TestContent(
        title: "French Post",
        content: """
        La cuisine française est reconnue mondialement pour sa finesse et sa diversité.
        Du coq au vin bourguignon au délicieux cassoulet du Sud-Ouest, chaque région possède
        ses spécialités qui racontent une histoire culinaire unique.

        Les techniques de base de la cuisine française, comme le mirepoix, le roux, et les
        cinq sauces mères, constituent le fondement de nombreuses préparations classiques.
        Ces méthodes transmises de génération en génération permettent de créer des plats
        d'une grande complexité et raffinement.

        L'utilisation d'ingrédients frais et de saison est primordiale. Les marchés locaux
        offrent une abondance de produits qui inspirent les chefs et les cuisiniers amateurs.
        """,
        languageCode: .french
    )

    // MARK: - Japanese Content

    static let japanesePost = TestContent(
        title: "Japanese Post",
        content: """
        日本料理の基本である出汁は、昆布と鰹節から作られる伝統的な調味料です。
        この旨味の素は、味噌汁、煮物、そして様々な料理の基礎となっています。

        正しい出汁の取り方は、まず昆布を水に浸して弱火でゆっくりと加熱します。
        沸騰直前に昆布を取り出し、その後鰹節を加えて数分間煮出します。

        良質な出汁を使うことで、料理全体の味わいが格段に向上します。
        インスタント出汁も便利ですが、本格的な料理には手作りの出汁が欠かせません。
        """,
        languageCode: .japanese
    )

    // MARK: - German Content

    static let germanTechPost = TestContent(
        title: "German Tech Post",
        content: """
        Die deutsche Automobilindustrie steht vor einem beispiellosen Wandel. Der Übergang von
        Verbrennungsmotoren zu Elektroantrieben erfordert nicht nur technologische Innovation,
        sondern auch eine grundlegende Neuausrichtung der gesamten Wertschöpfungskette.

        Traditionelle Zulieferer müssen sich anpassen oder riskieren, obsolet zu werden. Gleichzeitig
        entstehen neue Geschäftsmodelle rund um Batterietechnologie, Ladeinfrastruktur und
        Software-definierte Fahrzeuge. Die Frage ist nicht mehr, ob dieser Wandel kommt, sondern
        wie schnell deutsche Unternehmen sich anpassen können, um ihre führende Position in der
        globalen Automobilbranche zu behalten.
        """,
        languageCode: .german
    )

    // MARK: - Mandarin Content

    static let mandarinPost = TestContent(
        title: "Mandarin Post",
        content: """
        中国茶文化有着数千年的悠久历史，是中华文明的重要组成部分。从绿茶到红茶，
        从乌龙茶到普洱茶，每一种茶都有其独特的制作工艺和品鉴方法。

        茶道不仅仅是一种饮茶的方式，更是一种生活态度和精神追求。通过泡茶、品茶的过程，
        人们可以修身养性，体会宁静致远的境界。

        好的茶叶需要适宜的水温和冲泡时间。绿茶适合用80度左右的水温，而红茶则需要
        95度以上的沸水。掌握这些细节，才能充分释放茶叶的香气和味道。
        """,
        languageCode: .simplifiedChinese
    )

    // MARK: - Hindi Content

    static let hindiPost = TestContent(
        title: "Hindi Post",
        content: """
        योग भारतीय संस्कृति की एक प्राचीन परंपरा है जो शारीरिक, मानसिक और आध्यात्मिक स्वास्थ्य को बढ़ावा देती है।
        आसन, प्राणायाम और ध्यान के माध्यम से, योग हमें संतुलित और स्वस्थ जीवन जीने में मदद करता है।

        नियमित योग अभ्यास से तनाव कम होता है, मांसपेशियां मजबूत होती हैं, और मन शांत रहता है।
        सूर्य नमस्कार, शवासन, और पद्मासन जैसे आसन शुरुआती लोगों के लिए बहुत उपयोगी हैं।

        योग केवल व्यायाम नहीं है, बल्कि यह जीवन जीने की एक कला है। प्रतिदिन कुछ मिनट योग करने से
        जीवन की गुणवत्ता में उल्लेखनीय सुधार हो सकता है।
        """,
        languageCode: .hindi
    )

    // MARK: - Russian Content

    static let russianPost = TestContent(
        title: "Russian Post",
        content: """
        Русская литература золотого века подарила миру величайшие произведения, которые
        продолжают вдохновлять читателей по всему свету. Толстой, Достоевский, Чехов и
        Пушкин создали произведения, исследующие глубины человеческой души.

        Эти авторы не просто рассказывали истории, они поднимали фундаментальные вопросы
        о смысле жизни, морали, и человеческой природе. Их произведения остаются актуальными
        и сегодня, предлагая читателям глубокие размышления о вечных темах.

        Чтение классической русской литературы — это путешествие в мир сложных характеров,
        философских идей и богатого культурного наследия. Каждое произведение открывает
        новые горизонты понимания человеческого опыта.
        """,
        languageCode: .russian
    )

    // MARK: - Mixed Language Content

    static let mixedLanguagePost = TestContent(
        title: "Mixed Language Post",
        content: """
        The Mediterranean Diet: Una Guía Completa

        The Mediterranean diet has been recognized by UNESCO as an Intangible Cultural Heritage
        of Humanity. Esta dieta tradicional se basa en el consumo de aceite de oliva, frutas,
        verduras, legumbres, y pescado.

        Los beneficios para la salud son numerosos: reduced risk of heart disease, mejor
        control del peso, y longevidad aumentada. Studies have shown that people who follow
        this diet tend to live longer and healthier lives.
        """,
        languageCode: .english
    )

    // MARK: - Error Handling Test Cases

    static let emptyContent = TestContent(
        title: "Empty Content",
        content: "",
        languageCode: .english
    )

    static let veryLongContent = TestContent(
        title: "Very Long Content",
        content: String(repeating: """
        Quantum computing represents a paradigm shift in computational technology. Unlike classical
        computers that process information using bits (0s and 1s), quantum computers leverage the
        principles of quantum mechanics to operate with qubits. These qubits can exist in multiple
        states simultaneously through superposition, enabling parallel processing of vast amounts
        of data. The phenomenon of quantum entanglement further enhances computational capabilities
        by allowing qubits to be correlated in ways that classical bits cannot achieve.

        The implications of quantum computing extend across numerous fields. In cryptography, quantum
        computers pose both a threat to current encryption methods and a promise for ultra-secure
        quantum key distribution. Drug discovery and molecular modeling benefit from quantum simulation
        of complex chemical interactions. Financial modeling, optimization problems, and artificial
        intelligence are all domains poised for transformation through quantum algorithms.

        However, significant challenges remain before quantum computing becomes mainstream. Quantum
        systems are extremely sensitive to environmental interference, requiring near-absolute-zero
        temperatures and electromagnetic isolation. Quantum decoherence occurs when qubits lose their
        quantum properties due to external disturbances, limiting the duration of quantum computations.
        Error correction in quantum systems is fundamentally more complex than in classical computing,
        requiring multiple physical qubits to encode a single logical qubit.

        Current quantum computers are in the NISQ era (Noisy Intermediate-Scale Quantum), characterized
        by systems with 50-100 qubits that are prone to errors. Major technology companies and research
        institutions are racing to achieve quantum advantage—the point where quantum computers can
        solve practical problems faster than classical supercomputers. Google's quantum processor
        achieved a milestone in 2019 by performing a specific calculation in 200 seconds that would
        take the world's fastest supercomputer 10,000 years.

        """, count: 30) + "\n\nThis content continues for over 10,000 words to test handling of very long inputs.",
        languageCode: .english
    )

    static let malformedHTML = TestContent(
        title: "Malformed HTML",
        content: """
        <h1>Broken HTML Content</h1>
        <p>This paragraph is not closed properly
        <div>This div has no closing tag
        <ul>
            <li>Item 1
            <li>Item 2</li>
            <li>Item 3<li>
        </ul>
        <p><strong>Bold text <em>with nested italics</p></em></strong>
        <!-- This comment is <!-- nested improperly -->
        <img src="image.jpg" alt="Missing closing bracket
        <a href="https://example.com">Link with no closing tag
        """,
        languageCode: .english
    )

    static let emojiAndSpecialCharacters = TestContent(
        title: "Emoji and Special Characters",
        content: """
        🌟 Welcome to the World of Unicode! 🌍

        Emojis have become an integral part of digital communication 💬. From simple smileys 😊
        to complex sequences 👨‍👩‍👧‍👦, they convey emotions and ideas across language barriers.

        Special characters matter too: © ® ™ § ¶ † ‡ • ◦ ‣ ⁃ ⁎ ⁕ ❖ ※
        Mathematical symbols: ∑ ∏ √ ∞ ≈ ≠ ≤ ≥ ± × ÷ ∂ ∫ ∇
        Currency symbols: $ € £ ¥ ₹ ₽ ₩ ₪ ฿ ¢

        Zero-width characters and combining marks: café vs café (different é construction)
        Right-to-left marks: ‏עברית‏ العربية
        Emoji variations: 👍 👍🏻 👍🏼 👍🏽 👍🏾 👍🏿

        Uncommon Unicode: Ω ℃ ℉ № ℠ ™ ℮ ⅓ ⅔ ¼ ¾ ⅛ ⅜ ⅝ ⅞
        Box drawing: ┌─┬─┐ │ │ │ ├─┼─┤ │ │ │ └─┴─┘

        This tests how the system handles diverse Unicode characters! 🎉✨🚀
        """,
        languageCode: .english
    )

    // MARK: - Tag Data

    static let spanishSiteTags = [
        "recetas",
        "cocina-española",
        "gastronomía",
        "comida-mediterránea",
        "platos-tradicionales"
    ]

    static let englishSiteTags = [
        "baking",
        "bread-making",
        "recipes",
        "sourdough",
        "homemade"
    ]

    static let frenchSiteTags = [
        "cuisine",
        "gastronomie-française",
        "recettes",
        "plats-traditionnels",
        "art-culinaire"
    ]

    static let japaneseSiteTags = [
        "日本料理",
        "レシピ",
        "料理",
        "伝統",
        "和食"
    ]

    static let germanSiteTags = [
        "technologie",
        "innovation",
        "deutschland",
        "automobil",
        "elektromobilität"
    ]

    static let mandarinSiteTags = [
        "文化",
        "茶道",
        "传统",
        "生活方式",
        "健康"
    ]

    static let russianSiteTags = [
        "литература",
        "культура",
        "классика",
        "искусство",
        "философия"
    ]
}
