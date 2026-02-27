import Testing
import Foundation
import WordPressAPI
@testable import WordPress

@MainActor
struct TermResolutionServiceTests {

    // MARK: - resolveNames

    @Test("resolveNames fills in empty names from server")
    func resolveNamesFillsEmptyNames() async throws {
        // Given: terms with known IDs but empty names
        let terms = [
            PostSettings.Term(id: 1, name: ""),
            PostSettings.Term(id: 2, name: ""),
            PostSettings.Term(id: 3, name: "Already Named"),
        ]
        let mock = MockTaxonomyService()
        mock.getTermsResult = [
            makeAnyTerm(id: 1, name: "Tag One"),
            makeAnyTerm(id: 2, name: "Tag Two"),
        ]
        let service = TermResolutionService(taxonomyService: mock)

        // When
        let resolved = try await service.resolveNames(for: terms)

        // Then
        #expect(resolved[0].name == "Tag One")
        #expect(resolved[1].name == "Tag Two")
        #expect(resolved[2].name == "Already Named")
        #expect(mock.getTermsCalledWithIDs == [1, 2])
    }

    @Test("resolveNames returns unchanged when all names present")
    func resolveNamesNoOp() async throws {
        let terms = [PostSettings.Term(id: 1, name: "Has Name")]
        let mock = MockTaxonomyService()
        let service = TermResolutionService(taxonomyService: mock)

        let resolved = try await service.resolveNames(for: terms)

        #expect(resolved == terms)
        #expect(mock.getTermsCalledWithIDs == nil)
    }

    // MARK: - resolveIDs

    @Test("resolveIDs finds existing term by case-insensitive name match")
    func resolveIDsFindsExisting() async throws {
        let terms = [PostSettings.Term(id: 0, name: "swift")]
        let mock = MockTaxonomyService()
        mock.searchResult = [makeAnyTerm(id: 42, name: "Swift")]
        let service = TermResolutionService(taxonomyService: mock)

        let resolved = try await service.resolveIDs(for: terms)

        #expect(resolved[0].id == 42)
        #expect(resolved[0].name == "Swift")
        #expect(mock.searchCalledWith == "swift")
        #expect(mock.createCalledWith == nil)
    }

    @Test("resolveIDs creates term when no match found")
    func resolveIDsCreatesNew() async throws {
        let terms = [PostSettings.Term(id: 0, name: "new-tag")]
        let mock = MockTaxonomyService()
        mock.searchResult = [] // no match
        mock.createResult = makeAnyTerm(id: 99, name: "new-tag")
        let service = TermResolutionService(taxonomyService: mock)

        let resolved = try await service.resolveIDs(for: terms)

        #expect(resolved[0].id == 99)
        #expect(resolved[0].name == "new-tag")
        #expect(mock.createCalledWith == "new-tag")
    }

    @Test("resolveIDs skips terms that already have IDs")
    func resolveIDsSkipsKnownIDs() async throws {
        let terms = [
            PostSettings.Term(id: 5, name: "existing"),
            PostSettings.Term(id: 0, name: "new-tag"),
        ]
        let mock = MockTaxonomyService()
        mock.searchResult = []
        mock.createResult = makeAnyTerm(id: 10, name: "new-tag")
        let service = TermResolutionService(taxonomyService: mock)

        let resolved = try await service.resolveIDs(for: terms)

        #expect(resolved[0].id == 5)
        #expect(resolved[0].name == "existing")
        #expect(resolved[1].id == 10)
    }
}

// MARK: - Mock

private class MockTaxonomyService: TaxonomyServiceProtocol {
    var getTermsResult: [AnyTermWithViewContext] = []
    var getTermsCalledWithIDs: [Int64]?
    var searchResult: [AnyTermWithViewContext] = []
    var searchCalledWith: String?
    var createResult: AnyTermWithViewContext?
    var createCalledWith: String?

    func getTerms(ids: [Int64]) async throws -> [AnyTermWithViewContext] {
        getTermsCalledWithIDs = ids
        return getTermsResult
    }

    func searchTags(with query: String) async throws -> [AnyTermWithViewContext] {
        searchCalledWith = query
        return searchResult
    }

    func createTag(name: String, description: String) async throws -> AnyTermWithViewContext {
        createCalledWith = name
        return createResult!
    }

    func getTags(page: Int, recentlyUsed: Bool) async throws -> [AnyTermWithViewContext] { [] }
    func updateTag(_ term: AnyTermWithViewContext, name: String, description: String) async throws -> AnyTermWithViewContext { term }
    func deleteTag(_ term: AnyTermWithViewContext) async throws {}
}

private func makeAnyTerm(id: Int64, name: String) -> AnyTermWithViewContext {
    AnyTermWithViewContext(
        id: id, count: 0, description: "", link: "",
        name: name, slug: name.lowercased(), taxonomy: .postTag, parent: nil
    )
}
