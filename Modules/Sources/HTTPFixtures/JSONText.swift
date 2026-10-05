import Foundation

/// Finds the text of a value in a JSON document, exactly as the document has it.
///
/// A response body is served this way instead of being parsed and written back out, because
/// `JSONSerialization` doesn't keep the order of an object's keys. The order matters to a body's
/// template expressions, which are evaluated as they come: one may define a variable that a later
/// one reads.
enum JSONText {
    /// - Parameters:
    ///   - path: The keys leading to the value, from the document's root object.
    ///   - document: A valid JSON document.
    static func value(at path: [String], in document: Data) -> Data? {
        let scanner = Scanner(bytes: [UInt8](document))
        var range = 0..<scanner.bytes.count
        for key in path {
            guard let member = scanner.member(key, ofObjectIn: range) else {
                return nil
            }
            range = member
        }
        return Data(scanner.bytes[range])
    }

    private struct Scanner {
        let bytes: [UInt8]

        /// The range of the value of `key` in the object that starts in `range`.
        func member(_ key: String, ofObjectIn range: Range<Int>) -> Range<Int>? {
            var index = skipWhitespace(from: range.lowerBound)
            guard byte(at: index) == UInt8(ascii: "{") else {
                return nil
            }
            index += 1

            while true {
                index = skipWhitespace(from: index)
                guard byte(at: index) == UInt8(ascii: "\"") else {
                    return nil
                }
                let keyEnd = endOfString(from: index)
                let keyText = Data(bytes[index..<keyEnd])
                let name = try? JSONSerialization.jsonObject(with: keyText, options: .fragmentsAllowed)

                index = skipWhitespace(from: keyEnd)
                guard byte(at: index) == UInt8(ascii: ":") else {
                    return nil
                }
                index = skipWhitespace(from: index + 1)

                let valueEnd = endOfValue(from: index)
                if name as? String == key {
                    return index..<valueEnd
                }

                index = skipWhitespace(from: valueEnd)
                guard byte(at: index) == UInt8(ascii: ",") else {
                    return nil
                }
                index += 1
            }
        }

        private func byte(at index: Int) -> UInt8? {
            bytes.indices.contains(index) ? bytes[index] : nil
        }

        private func skipWhitespace(from start: Int) -> Int {
            var index = start
            while let byte = byte(at: index), Self.whitespace.contains(byte) {
                index += 1
            }
            return index
        }

        /// The index after the closing quote of the string that starts at `start`.
        private func endOfString(from start: Int) -> Int {
            var index = start + 1
            while let byte = byte(at: index) {
                if byte == UInt8(ascii: "\\") {
                    index += 2
                } else if byte == UInt8(ascii: "\"") {
                    return index + 1
                } else {
                    index += 1
                }
            }
            return index
        }

        /// The index after the value that starts at `start`.
        private func endOfValue(from start: Int) -> Int {
            var index = start

            switch byte(at: start) {
            case UInt8(ascii: "\""):
                return endOfString(from: start)
            case UInt8(ascii: "{"), UInt8(ascii: "["):
                var depth = 0
                while let byte = byte(at: index) {
                    switch byte {
                    case UInt8(ascii: "\""):
                        index = endOfString(from: index)
                        continue
                    case UInt8(ascii: "{"), UInt8(ascii: "["):
                        depth += 1
                    case UInt8(ascii: "}"), UInt8(ascii: "]"):
                        depth -= 1
                    default:
                        break
                    }
                    index += 1
                    if depth == 0 {
                        break
                    }
                }
            default:
                // A number, `true`, `false` or `null` runs up to whatever follows it.
                while let byte = byte(at: index), !Self.delimiters.contains(byte) {
                    index += 1
                }
            }

            return index
        }

        private static let whitespace: Set<UInt8> = [0x20, 0x09, 0x0A, 0x0D]
        private static let delimiters = whitespace.union([UInt8(ascii: ","), UInt8(ascii: "}"), UInt8(ascii: "]")])
    }
}
