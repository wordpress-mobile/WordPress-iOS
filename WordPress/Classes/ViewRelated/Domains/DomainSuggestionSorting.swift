import WordPressKit

enum DomainSuggestionSorting {
    /// Mimics the sorting on the web: two top paid domains, then the rest in their original order.
    static func sorted(_ suggestions: [DomainSuggestion]) -> [DomainSuggestion] {
        var topDomains: [DomainSuggestion] = []
        var otherDomains: [DomainSuggestion] = []

        for suggestion in suggestions {
            if topDomains.count < 2 && !suggestion.isFree {
                topDomains.append(suggestion)
            } else {
                otherDomains.append(suggestion)
            }
        }

        return topDomains + otherDomains
    }

    /// Splits suggestions into the free address shown on its own card and the sorted rows below it.
    ///
    /// The free entry is selected by its `isFree` flag, not by its position in the response.
    /// Only the first free entry goes to the card; any other free entries stay in the rows.
    static func partitioned(_ suggestions: [DomainSuggestion]) -> (free: DomainSuggestion?, rows: [DomainSuggestion]) {
        guard let freeIndex = suggestions.firstIndex(where: \.isFree) else {
            return (nil, sorted(suggestions))
        }

        var rows = suggestions
        let free = rows.remove(at: freeIndex)
        return (free, sorted(rows))
    }
}
