import Foundation

struct StringRankedSearch {
    /// By default, `[.caseInsensitive, .diacriticInsensitive]`.
    var options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    private let term: String
    private let terms: [String]

    init(searchTerm: String) {
        self.term = searchTerm.trimmingCharacters(in: .whitespaces)
        self.terms = term.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }

    /// Returns a score in a `0.0...1.0` range where `1.0` is maximum confidence.
    /// Anything above `0.5` suggests a good probability of a match.
    func score(for string: String?) -> Double {
        guard let string else {
            return 0
        }
        let words = string
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else {
            return 0
        }
        var score = 0.0
        var matchIndices: Set<Int> = []
        for term in terms {
            // Get the maximum score for each word. There is no penalty for a
            // position of the word in the input string.
            let match = words.enumerated()
                .map { (index, word) in (index: index, score: self.score(for: word, term: term)) }
                .max { $0.score < $1.score }!
            score += match.score
            matchIndices.insert(match.index)
        }
        let bonusForDistanceBetweenMatches = self.bonusForDistanceBetweenMatches(matchIndices.sorted(), words: words)
        let bonusForLengthMatch = score * (Double(min(string.count, term.count)) / Double(max(string.count, term.count)))
        let bonusForCountMatch = score * (Double(min(terms.count, words.count)) / Double(max(terms.count, words.count)))
        return (0.9 * (score / Double(terms.count))) +
        (0.05 * bonusForDistanceBetweenMatches) +
        (0.025 * bonusForLengthMatch) *
        (0.025 * bonusForCountMatch)
    }


    private func bonusForDistanceBetweenMatches(_ indices: [Int], words: [String]) -> Double {
        let distance = zip(indices.dropLast(), indices.dropFirst())
            .map { $1 - $0 }
            .reduce(0, +)
        return 1.0 - (Double(distance) / Double(words.count))
    }

    // Returns score in a `0.0...1.0` range.
    private func score(for input: String, term: String) -> Double {
        guard !input.isEmpty else {
            return 0
        }
        let score = fuzzyScore(for: input, term: term) / Double(term.count)
        let bonusForLengthMatch = score * (Double(min(input.count, term.count)) / Double(max(input.count, term.count)))
        let bonusForTermLength = term.count > 3 ? 0.1 : (term.count > 2 ? 0.05 : 0.0)
        return (0.8 * score) + (0.1 * bonusForLengthMatch) + bonusForTermLength
    }

    // Returns score in a `0.0...1.0` range.
    private func fuzzyScore(for input: String, term: String) -> Double {
        var score = 0.0
        var inputIndex = input.startIndex
        var termIndex = term.startIndex

        func findNextMatch() -> Range<String.Index>? {
            // Look for a perfect match first
            if let range = input[inputIndex...].range(of: term[termIndex...], options: options) {
                return range // Found these characters in a row
            }
            return input[inputIndex...].range(of: String(term[termIndex]), options: options)
        }

        while termIndex < term.endIndex, inputIndex < input.endIndex, let range = findNextMatch() {
            var matchIndex = range.lowerBound
            while matchIndex < range.upperBound {
                if matchIndex == inputIndex {
                    score += 0.9 // Bonus: matches the position exactly
                } else if term[termIndex].isLetter != input[input.index(before: matchIndex)].isLetter {
                    score += 0.8 // Bonus: letter followed by non-letter or the other way around
                }
                if input[matchIndex] == term[termIndex] {
                    score += 0.1 // Bonus: exact match, including case and diacritics
                }
                termIndex = term.index(after: termIndex)
                matchIndex = input.index(after: matchIndex)
                inputIndex = matchIndex
            }
            inputIndex = range.upperBound
        }

        guard term.distance(from: termIndex, to: term.endIndex) < 2 else {
            return 0 // Too many misses
        }
        return score
    }
}
