import Foundation
import WordPressAPI

struct TermResolutionService {
    let taxonomyService: TaxonomyServiceProtocol

    /// Resolves display names for terms that have known IDs but empty names
    /// by batch-fetching from the server.
    func resolveNames(for terms: [PostSettings.Term]) async throws -> [PostSettings.Term] {
        let unresolved = terms.filter { $0.id > 0 && $0.name.isEmpty }
        guard !unresolved.isEmpty else { return terms }

        let ids = unresolved.map { Int64($0.id) }
        let fetched = try await taxonomyService.getTerms(ids: ids)

        var nameByID: [Int: String] = [:]
        for term in fetched {
            nameByID[Int(term.id)] = term.name
        }

        return terms.map { term in
            if let name = nameByID[term.id], term.name.isEmpty {
                return PostSettings.Term(id: term.id, name: name)
            }
            return term
        }
    }

    /// Resolves IDs for terms with `id == 0` by searching the server for a
    /// case-insensitive name match, or creating the term if not found.
    func resolveIDs(for terms: [PostSettings.Term]) async throws -> [PostSettings.Term] {
        var result = terms

        for (index, term) in terms.enumerated() where term.id == 0 {
            let matches = try await taxonomyService.searchTags(with: term.name)
            if let match = matches.first(where: {
                $0.name.caseInsensitiveCompare(term.name) == .orderedSame
            }) {
                result[index] = PostSettings.Term(id: Int(match.id), name: match.name)
            } else {
                let created = try await taxonomyService.createTag(name: term.name, description: "")
                result[index] = PostSettings.Term(id: Int(created.id), name: created.name)
            }
        }

        return result
    }
}
