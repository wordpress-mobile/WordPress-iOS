import Foundation

struct StringRankedSearch {
    /// By default, `[.caseInsensitive, .diacriticInsensitive]`.
    var options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    private let terms: [String]

    init(searchTerm: String) {
        self.terms = searchTerm
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
    }

    /// Returns a score in a `0.0...1.0` range where `1.0` is maximum confidence.
    func score(for string: String?) -> Double {
        let words = (string ?? "")
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else {
            return 0
        }
        var score = 0.0
        for term in terms {
            score += words.map { self.score(for: $0, term: term) }.max()!
        }
        return 0.5 * (score / Double(max(words.count, terms.count)) + score / Double(terms.count))
    }

    private func score(for input: String, term: String) -> Double {
        guard !input.isEmpty else {
            return 0
        }
        let score = fuzzyScore(for: input[...], term: term)
        return (0.8 * (score / Double(term.count))) + (0.2 * (score / Double(input.count)))
    }

    private func fuzzyScore(for input: Substring, term: String) -> Double {
        var score = 0.0
        var misses = 0
        var input = input
        for character in term {
            func findNextMatch() -> Range<String.Index>? {
                if let range = input.range(of: term, options: options) {
                    return range // Found these characters in a row
                }
                return input.range(of: String(character), options: options)
            }
            if let index = findNextMatch()?.lowerBound {
                if index == input.startIndex {
                    score += 0.9 // Bonus: matches the position exactly
                } else if character.isLetter && !input[input.index(before: index)].isLetter {
                    score += 0.8 // Bonus: after non-letter, e.g. `'`
                } else {
                    score += 0.6
                }
                if input[index] == character {
                    score += 0.1 // Bonus: exact match, including case and diacritics
                }
                input = input.suffix(from: input.index(after: index))
            } else {
                misses += 1
                if misses > 1 {
                    return 0 // Allow up to one miss
                }
            }
        }
        return score
    }
}
