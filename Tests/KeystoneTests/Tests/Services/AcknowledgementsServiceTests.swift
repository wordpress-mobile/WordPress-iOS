import Testing

@testable import WordPress

struct AcknowledgementsServiceTests {
    @Test(.enabledOnCI)
    func bundledPackageManifestCanBeParsed() async throws {
        let items = try await AcknowledgementsService().loadItems()

        #expect(!items.isEmpty)
    }
}
