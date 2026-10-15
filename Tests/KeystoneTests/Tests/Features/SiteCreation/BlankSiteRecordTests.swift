import Testing

@testable import WordPress

struct BlankSiteRecordTests {
    private let repository = InMemoryUserDefaults()

    @Test func emptyRecordContainsNothing() {
        #expect(!BlankSiteRecord(repository: repository).contains(siteID: 1))
    }

    @Test func insertedSiteIsContainedAcrossInstances() {
        BlankSiteRecord(repository: repository).insert(siteID: 1)

        let record = BlankSiteRecord(repository: repository)
        #expect(record.contains(siteID: 1))
        #expect(!record.contains(siteID: 2))
    }

    @Test func removeOnlyRemovesThatSite() {
        let record = BlankSiteRecord(repository: repository)
        record.insert(siteID: 1)
        record.insert(siteID: 2)

        record.remove(siteID: 1)

        #expect(!record.contains(siteID: 1))
        #expect(record.contains(siteID: 2))
    }
}
