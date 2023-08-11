import Foundation
import SourceKittenFramework

public struct Expression {
    public let byteRange: ClosedRange<Int64>
    public let type: String

    init(sourceKitExpressionTypeResponse response: [String: SourceKitRepresentable]) throws {
        let offset: Int64 = try response.get("key.expression_offset")
        let length: Int64 = try response.get("key.expression_length")
        byteRange = offset...(offset + length - 1)
        type = try response.get("key.expression_type")
    }

    func highlightPrint(at sourceCode: URL) throws {
        try print(String(contentsOf: sourceCode).highlight(byteRange: byteRange))
    }
}

extension String {
    func highlight(byteRange: ClosedRange<Int64>) -> String {
        var data = data(using: .utf8)!

        let dataRange = Int(byteRange.lowerBound)...Int(byteRange.upperBound)
        let highlighted = "\u{001B}[1;32m".data(using: .utf8)! + data[dataRange] + "\u{001B}[0m".data(using: .utf8)!
        data.replaceSubrange(dataRange, with: highlighted)

        let highlightStartLine = data.numberOfLines(in: 0..<dataRange.lowerBound) + 1
        let hihglightEndLine = highlightStartLine + highlighted.numberOfLines()

        var output = ""
        var lineNo = 0
        String(data: data, encoding: .utf8)!.enumerateLines { line, stop in
            lineNo += 1

            guard lineNo >= highlightStartLine, lineNo <= hihglightEndLine else {
                return
            }

            output += "\(lineNo): \(line)"
            stop = lineNo == hihglightEndLine
        }
        return output
    }
}

private extension Data {
    func numberOfLines() -> Int {
        numberOfLines(in: 0..<count)
    }

    func numberOfLines<R: RangeExpression>(in range: R) -> Int where R.Bound == Int {
        let newline = UInt8(ascii: "\n")
        return self[range].reduce(0) { lines, char in
            char == newline ? lines + 1 : lines
        }
    }
}
