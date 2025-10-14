import Testing
@testable import WordPressData

@Suite("PostMetadata Tests")
struct PostMetadataTests {

    // MARK: accessLevel

    @Test("Access level from mock data")
    func accessLevelFromMockData() throws {
        let metadata = try PostMetadata(data: PostMetadataContainerTests.mockMetadataJSON)

        #expect(metadata.accessLevel == .subscribers)
    }

    @Test("Set access level")
    func setEncodeAccessLevel() {
        // GIVEN
        var container = PostMetadataContainer()
        var metadata = PostMetadata(from: container)

        // WHEN
        metadata.accessLevel = .everybody
        metadata.encode(in: &container)

        // THEN
        #expect(container.getValue(String.self, forKey: .jetpackNewsletterAccess) == "everybody")
    }

    @Test("Remove access level")
    func removeAccessLevel() throws {
        // GIVEN
        var metadata = try PostMetadata(data: PostMetadataContainerTests.mockMetadataJSON)
        #expect(metadata.accessLevel != nil)

        // WHEN
        metadata.accessLevel = nil
        var container = PostMetadataContainer()
        metadata.encode(in: &container)

        // THEN
        #expect(container.getValue(String.self, forKey: .jetpackNewsletterAccess) == nil)
    }

    // MARK: isJetpackNewsletterEmailDisabled

    @Test
    func jetpackNewsletterEmailDisabled() {
        var container = PostMetadataContainer()

        #expect(PostMetadata(from: container).isJetpackNewsletterEmailDisabled == false)

        container.setValue("", for: .jetpackNewsletterEmailDisabled)
        #expect(PostMetadata(from: container).isJetpackNewsletterEmailDisabled == false)

        container.setValue("true", for: .jetpackNewsletterEmailDisabled)
        #expect(PostMetadata(from: container).isJetpackNewsletterEmailDisabled == true)

        container.setValue("1", for: .jetpackNewsletterEmailDisabled)
        #expect(PostMetadata(from: container).isJetpackNewsletterEmailDisabled == true)

        container.setValue(1, for: .jetpackNewsletterEmailDisabled)
        #expect(PostMetadata(from: container).isJetpackNewsletterEmailDisabled == true)

        container.setValue(true, for: .jetpackNewsletterEmailDisabled)
        #expect(PostMetadata(from: container).isJetpackNewsletterEmailDisabled == true)
    }

    @Test
    func settingExistingValueIsNoop() {
        // GIVEN
        var container = PostMetadataContainer()
        container.setValue("", for: .jetpackNewsletterEmailDisabled)

        // WHEN
        var metadata = PostMetadata(from: container)
        metadata.isJetpackNewsletterEmailDisabled = false
        metadata.encode(in: &container)

        // THEN
        #expect(container.getString(for: .jetpackNewsletterEmailDisabled) == "")
    }
}

private extension PostMetadata {
    init(data: Data) throws {
        let container = try PostMetadataContainer(data: data)
        self = PostMetadata(from: container)
    }
}

extension PostMetadataContainerTests {
    static var mockMetadataJSON: Data {
        let mockData: [[String: Any]] = [
            [
                "id": "2372",
                "key": "advanced_seo_description",
                "value": ""
            ],
            [
                "id": "2380",
                "key": "footnotes",
                "value": ""
            ],
            [
                "id": "2373",
                "key": "jetpack_seo_html_title",
                "value": ""
            ],
            [
                "id": "2374",
                "key": "jetpack_seo_noindex",
                "value": ""
            ],
            [
                "id": "2347",
                "key": "wp_jp_foreign_id",
                "value": "95199E7F-EEF2-46B0-BC89-898AE817CEAD"
            ],
            [
                "id": "2377",
                "key": "_jetpack_dont_email_post_to_subs",
                "value": ""
            ],
            [
                "id": "2376",
                "key": "_jetpack_newsletter_access",
                "value": "subscribers"
            ],
            [
                "id": "2386",
                "key": "_jetpack_newsletter_tier_id",
                "value": "0"
            ],
            [
                "id": "2383",
                "key": "_wpas_done_all",
                "value": ""
            ],
            [
                "id": "2382",
                "key": "_wpas_feature_enabled",
                "value": "1"
            ],
            [
                "id": "2381",
                "key": "_wpas_mess",
                "value": ""
            ],
            [
                "id": "2384",
                "key": "_wpas_options",
                "value": """
                {
                    "image_generator_settings": {
                        "default_image_id": 0,
                        "enabled": 0,
                        "font": "",
                        "template": "highway"
                    },
                    "version": 2
                }
                """
            ]
        ]

        return try! JSONSerialization.data(withJSONObject: mockData, options: [])
    }
}
