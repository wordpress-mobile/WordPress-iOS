import Testing
@testable import WordPressKit
@testable import WordPressKitObjC

struct PostTermComparisonTests {

    @Test
    func emptyDictionaries() {
        let lhs: [String: [String]] = [:]
        let rhs: [String: [String]] = [:]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == true)
    }

    @Test
    func identicalDictionaries() {
        let lhs: [String: [String]] = [
            "category": ["1", "2", "3"],
            "post_tag": ["tag1", "tag2"]
        ]
        let rhs: [String: [String]] = [
            "category": ["1", "2", "3"],
            "post_tag": ["tag1", "tag2"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == true)
    }

    @Test
    func sameValuesInDifferentOrder() {
        let lhs: [String: [String]] = [
            "category": ["1", "2", "3"],
            "post_tag": ["tag1", "tag2"]
        ]
        let rhs: [String: [String]] = [
            "category": ["3", "1", "2"],
            "post_tag": ["tag2", "tag1"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == true)
    }

    @Test
    func differentKeys() {
        let lhs: [String: [String]] = [
            "category": ["1", "2", "3"]
        ]
        let rhs: [String: [String]] = [
            "post_tag": ["tag1", "tag2"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == false)
    }

    @Test
    func differentValues() {
        let lhs: [String: [String]] = [
            "category": ["1", "2", "3"]
        ]
        let rhs: [String: [String]] = [
            "category": ["1", "2", "4"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == false)
    }

    @Test
    func differentCounts() {
        let lhs: [String: [String]] = [
            "category": ["1", "2", "3"],
            "post_tag": ["tag1", "tag2"]
        ]
        let rhs: [String: [String]] = [
            "category": ["1", "2", "3"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == false)
    }

    @Test
    func duplicateValuesInArrays() {
        let lhs: [String: [String]] = [
            "category": ["1", "2", "2", "3"]
        ]
        let rhs: [String: [String]] = [
            "category": ["1", "2", "3"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == true)
    }

    @Test
    func multipleTaxonomies() {
        let lhs: [String: [String]] = [
            "category": ["1", "2"],
            "post_tag": ["tag1", "tag2"],
            "custom_tax": ["term1"]
        ]
        let rhs: [String: [String]] = [
            "category": ["2", "1"],
            "post_tag": ["tag2", "tag1"],
            "custom_tax": ["term1"]
        ]

        #expect(RemotePost.compare(otherTerms: lhs, withAnother: rhs) == true)
    }

}
