#!/usr/bin/env swift

// Usage: xcresult-to-junit.swift <bundle.xcresult> <report.junit>
//
// Keep the output identical to fastlane's `trainer`: Buildkite Test Engine tracks each test's history by its names.

import Foundation

struct Node: Decodable {
    let name: String?
    let nodeType: String?
    let nodeIdentifier: String?
    let duration: String?
    let result: String?
    let tags: [String]?
    let children: [Node]?

    func children(_ types: String...) -> [Node] {
        (children ?? []).filter { types.contains($0.nodeType ?? "") }
    }

    func names(_ type: String) -> [String] {
        children(type).compactMap(\.name)
    }

    // Parses a leading number only, like `trainer`, so "1m 3s" reads as 1.
    var seconds: Double {
        let text = (duration ?? "").replacingOccurrences(of: ",", with: ".")
        guard let range = text.range(of: #"^[0-9]+(\.[0-9]+)?"#, options: .regularExpression) else { return 0 }
        return Double(text[range]) ?? 0
    }
}

struct Report: Decodable {
    struct Configuration: Decodable {
        let configurationName: String?
    }

    struct Device: Decodable {
        let modelName: String?
        let osVersion: String?
    }

    let testNodes: [Node]?
    let testPlanConfigurations: [Configuration]?
    let devices: [Device]?
}

final class Element {
    let name: String
    let attributes: [(String, String)]
    var children: [Element] = []

    init(_ name: String, _ attributes: [(String, String?)] = []) {
        self.name = name
        self.attributes = attributes.compactMap { key, value in value.map { (key, $0) } }
    }

    func render(indent: String = "") -> String {
        let attributeText = attributes.map { " \($0)='\(escape($1))'" }.joined()
        guard !children.isEmpty else { return "\(indent)<\(name)\(attributeText)/>" }
        let body = children.map { $0.render(indent: indent + "  ") }.joined(separator: "\n")
        return "\(indent)<\(name)\(attributeText)>\n\(body)\n\(indent)</\(name)>"
    }
}

func escape(_ text: String) -> String {
    var output = ""
    for scalar in text.unicodeScalars {
        switch scalar {
        case "&": output += "&amp;"
        case "<": output += "&lt;"
        case ">": output += "&gt;"
        case "\"": output += "&quot;"
        case "'": output += "&apos;"
        case "\u{00}"..."\u{08}", "\u{0B}", "\u{0C}", "\u{0E}"..."\u{1F}", "\u{7F}":
            output += String(format: "\\u%04x", scalar.value)
        default: output.unicodeScalars.append(scalar)
        }
    }
    return output
}

// Matches Ruby's `Float#to_s`, which `trainer` uses: "1.0e-05" where Swift prints "1e-05".
func format(_ value: Double) -> String {
    let text = "\(value)"
    guard let exponent = text.firstIndex(of: "e"), !text[..<exponent].contains(".") else { return text }
    return text[..<exponent] + ".0" + text[exponent...]
}

// Matches Ruby's `Array#sum`, which `trainer` uses and which compensates for rounding (Kahan-Babuska).
func compensatedSum(_ values: [Double]) -> Double {
    var sum = 0.0
    var compensation = 0.0
    for value in values {
        let total = sum + value
        compensation += abs(sum) >= abs(value) ? (sum - total) + value : (value - total) + sum
        sum = total
    }
    return sum + compensation
}

// `trainer` sums integers when nothing was timed, which prints "0" rather than "0.0".
func timeText(_ time: Double, timed: Bool) -> String {
    timed ? format(time) : "0"
}

func properties(_ pairs: [(String, String?)]) -> Element {
    let element = Element("properties")
    element.children = pairs.map { Element("property", [("name", $0), ("value", $1)]) }
    return element
}

func testName(_ name: String, argument: String?) -> String {
    guard let argument else { return name }
    guard let range = name.range(of: #"\(.*\)"#, options: .regularExpression) else { return "\(name) (\(argument))" }
    return name.replacingCharacters(in: range, with: "(\(argument))")
}

func resultElements(for node: Node) -> [Element] {
    let messages = node.names("Failure Message")
    switch node.result {
    case "Failed":
        return (messages.isEmpty ? [nil] : messages.map(Optional.some)).map { Element("failure", [("message", $0)]) }
    case "Skipped":
        return [Element("skipped", [("message", messages.first)])]
    default:
        return []
    }
}

func numbered(_ prefix: String, _ values: [String]) -> [(String, String?)] {
    values.enumerated().map { ("\(prefix)\($0.offset + 1)", $0.element) }
}

func classname(_ test: Node) -> String? {
    test.nodeIdentifier.map { $0.components(separatedBy: "/").dropLast().joined(separator: ".") }
}

struct ExpandedCase {
    let elements: [Element]
    let result: String?
    let time: Double
}

func testcase(_ test: Node, argument: Node?, run: Node?, attributes: Node, runs: [Node]) -> Element {
    let element = Element("testcase", [
        ("name", testName(test.name ?? "", argument: argument?.name)),
        ("classname", classname(test)),
        ("time", format((run ?? test).seconds)),
    ])
    element.children = resultElements(for: run ?? argument ?? test)

    let origins = runs.isEmpty ? [attributes] : runs
    var pairs: [(String, String?)] = []
    if let argument {
        pairs += [("testname", test.name), ("argument", argument.name)]
    }
    if let run {
        pairs.append(("repetition", run.name))
    }
    pairs += numbered("source_reference", origins.flatMap { $0.names("Source Code Reference") })
    pairs += numbered("attachment", origins.flatMap { $0.names("Attachment") })
    pairs += numbered("tag", (test.tags ?? []).sorted())
    if !pairs.isEmpty {
        element.children.append(properties(pairs))
    }
    return element
}

// Returns one entry per test argument, or a single one for a test without arguments.
func expand(_ test: Node) -> [ExpandedCase] {
    let arguments = test.children("Arguments")
    return (arguments.isEmpty ? [nil] : arguments.map(Optional.some)).map { argument in
        let attributes = argument ?? test
        let runs = attributes.children("Repetition", "Test Case Run")
        let elements = (runs.isEmpty ? [nil] : runs.map(Optional.some)).map { run in
            testcase(test, argument: argument, run: run, attributes: attributes, runs: runs)
        }
        return ExpandedCase(elements: elements, result: attributes.result, time: test.seconds)
    }
}

struct Suite {
    let element: Element
    let tests: Int
    let failures: Int
    let skipped: Int
    let time: Double
    let timed: Bool
}

func buildSuite(_ node: Node) -> Suite {
    let cases = node.children("Test Case").flatMap(expand)
    let suites = node.children("Test Suite", "Unit test bundle", "UI test bundle").map(buildSuite)

    let tests = cases.count + suites.reduce(0) { $0 + $1.tests }
    let failures = cases.filter { $0.result == "Failed" }.count + suites.reduce(0) { $0 + $1.failures }
    let skipped = cases.filter { $0.result == "Skipped" }.count + suites.reduce(0) { $0 + $1.skipped }
    let time = compensatedSum(cases.map(\.time)) + compensatedSum(suites.map(\.time))
    let timed = !cases.isEmpty || suites.contains(where: \.timed)

    let element = Element("testsuite", [
        ("name", node.name),
        ("time", timeText(time, timed: timed)),
        ("tests", String(tests)),
        ("failures", String(failures)),
        ("skipped", String(skipped)),
    ])
    element.children = cases.flatMap(\.elements) + suites.map(\.element)
    return Suite(element: element, tests: tests, failures: failures, skipped: skipped, time: time, timed: timed)
}

func junit(_ report: Report) -> Element {
    let plan = report.testNodes?.first { $0.nodeType == "Test Plan" }
    let suites = (plan?.children ?? []).map(buildSuite)

    var environment: [(String, String?)] = []
    if plan != nil {
        environment += (report.testPlanConfigurations ?? []).map { ("Configuration", $0.configurationName) }
        environment += (report.devices ?? []).map {
            ("device", "\($0.modelName ?? "Unknown Device") (\($0.osVersion ?? "Unknown OS Version"))")
        }
    }

    let root = Element("testsuites", [
        ("tests", String(suites.reduce(0) { $0 + $1.tests })),
        ("failures", String(suites.reduce(0) { $0 + $1.failures })),
        ("skipped", String(suites.reduce(0) { $0 + $1.skipped })),
        ("time", timeText(compensatedSum(suites.map(\.time)), timed: suites.contains(where: \.timed))),
    ])
    for suite in suites {
        if !environment.isEmpty {
            suite.element.children.append(properties(environment))
        }
        root.children.append(suite.element)
    }
    return root
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 3 else {
    fail("Usage: xcresult-to-junit.swift <bundle.xcresult> <report.junit>")
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", CommandLine.arguments[1]]
let output = Pipe()
process.standardOutput = output
try process.run()
let json = output.fileHandleForReading.readDataToEndOfFile()
process.waitUntilExit()
guard process.terminationStatus == 0 else { fail("xcresulttool failed") }

let report = try JSONDecoder().decode(Report.self, from: json)
let xml = "<?xml version='1.0' encoding='UTF-8'?>\n" + junit(report).render()
try xml.write(toFile: CommandLine.arguments[2], atomically: true, encoding: .utf8)
