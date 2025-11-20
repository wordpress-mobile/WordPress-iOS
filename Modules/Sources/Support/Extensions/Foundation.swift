import Foundation

extension Date {
    var isToday: Bool {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.isDateInToday(self)
    }

    var hasPast: Bool {
        Date.now > self
    }
}

extension String {
    func applyingNumericMorphology(for number: Int) -> String {
        var attr = AttributedString(self)
        var morphology = Morphology()
        morphology.number = switch number {
        case 0: .zero
        case 1: .singular
        case 2: .pluralTwo
        case 3...7: .pluralFew
        case 7...: .pluralMany
        default: .plural
        }
        attr.inflect = InflectionRule(morphology: morphology)

        return attr.inflected().characters.reduce(into: "") { $0.append($1) }
    }
}

extension AttributedString {
    func toHtml() -> String {
        NSAttributedString(self).toHtml()
    }
}

extension NSAttributedString {
    func toHtml() -> String {
        let documentAttributes = [
            NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html
        ]

        guard
            let htmlData = try? self.data(from: NSMakeRange(0, self.length), documentAttributes: documentAttributes),
            let htmlString = String(data: htmlData, encoding: .utf8)
        else {
            return self.string
        }

        return htmlString
    }
}

func convertMarkdownHeadingsToBold(in markdown: String) -> String {
    let lines = markdown.components(separatedBy: .newlines)
    var convertedLines: [String] = []

    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        // Check if line starts with one or more # characters followed by a space
        if trimmedLine.hasPrefix("#") {
            // Find the first non-# character
            let hashCount = trimmedLine.prefix(while: { $0 == "#" }).count

            // Make sure there's at least one # and that it's followed by a space or end of string
            if hashCount > 0 && hashCount < trimmedLine.count {
                let remainingText = String(trimmedLine.dropFirst(hashCount))

                // Check if there's a space after the hashes (proper markdown heading format)
                if remainingText.hasPrefix(" ") {
                    let headingText = remainingText.trimmingCharacters(in: .whitespaces)
                    if !headingText.isEmpty {
                        // Convert to bold text
                        convertedLines.append("**\(headingText)**")
                        continue
                    }
                }
            }
        }

        // If not a heading, keep the original line
        convertedLines.append(line)
    }

    return convertedLines.joined(separator: "\n")
}

func convertMarkdownTextToAttributedString(_ text: String) -> AttributedString {
    do {
        // The iOS Markdown parser doesn't support headings, so we need to convert those
        let modifiedText = convertMarkdownHeadingsToBold(in: text)
        return try AttributedString(
            markdown: modifiedText,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )
    } catch {
        // Fallback to plain-text rendering
        return AttributedString(text)
    }
}

extension Task where Failure == Error {
    static func delayedAndRunOnMainActor<C>(
        for duration: C.Instant.Duration,
        priority: TaskPriority? = nil,
        operation: @MainActor @escaping @Sendable () throws -> Success,
        clock: C = .continuous
    ) -> Task where C: Clock {
        Task(priority: priority) {
            try await clock.sleep(for: duration)
            return try await MainActor.run(body: operation)
        }
    }

    static func runForAtLeast<C>(
        _ duration: C.Instant.Duration,
        operation: @escaping @Sendable () async throws -> Success,
        clock: C = .continuous
    ) async throws -> Success where C: Clock {
        async let waitResult: () = try await clock.sleep(for: duration)
        async let performTask = try await operation()

        return try await (waitResult, performTask).1
    }
}
