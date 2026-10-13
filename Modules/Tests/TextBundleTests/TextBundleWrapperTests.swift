import Foundation
import Testing

import TextBundle

/// Regression tests for the nullability hardening in `TextBundleWrapper`:
/// a read failure must surface as a thrown error (the initializer is now `nullable`,
/// so it bridges to a throwing Swift initializer) rather than a nil-holding instance,
/// and a text file that isn't valid UTF-8 must fail the read instead of leaving
/// the `nonnull` `text` property nil.
struct TextBundleWrapperTests {

    // MARK: Helpers

    /// Writes a `.textbundle` directory to a unique temporary location and returns its URL.
    /// Pass `nil` for `info` or `textFileName`/`textData` to omit that member.
    private func makeBundle(info: Data?, textFileName: String?, textData: Data?) throws -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("TextBundleTests-\(UUID().uuidString)", isDirectory: true)
        let bundle = root.appendingPathComponent("document.textbundle", isDirectory: true)
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
        if let info {
            try info.write(to: bundle.appendingPathComponent("info.json"))
        }
        if let textFileName, let textData {
            try textData.write(to: bundle.appendingPathComponent(textFileName))
        }
        return bundle
    }

    private var validInfoJSON: Data {
        Data(#"{"version":2,"type":"net.daringfireball.markdown"}"#.utf8)
    }

    // MARK: Happy path

    @Test func validBundleLoadsText() throws {
        let url = try makeBundle(info: validInfoJSON, textFileName: "text.markdown", textData: Data("# Hello".utf8))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let wrapper = try TextBundleWrapper(contentsOf: url, options: .immediate)
        #expect(wrapper.text == "# Hello")
        #expect(wrapper.type == kUTTypeMarkdown)
    }

    // MARK: Finding 1 — read failures must throw (nullable initializer)

    @Test func missingTextFileThrows() throws {
        let url = try makeBundle(info: validInfoJSON, textFileName: nil, textData: nil)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(throws: (any Error).self) {
            _ = try TextBundleWrapper(contentsOf: url, options: .immediate)
        }
    }

    @Test func missingInfoJSONThrows() throws {
        let url = try makeBundle(info: nil, textFileName: "text.markdown", textData: Data("hi".utf8))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(throws: (any Error).self) {
            _ = try TextBundleWrapper(contentsOf: url, options: .immediate)
        }
    }

    @Test func unreadableURLThrows() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("does-not-exist-\(UUID().uuidString).textbundle", isDirectory: true)

        #expect(throws: (any Error).self) {
            _ = try TextBundleWrapper(contentsOf: url, options: .immediate)
        }
    }

    // MARK: Finding 2 — non-UTF-8 text must fail the read, not leave `text` nil

    @Test func nonUTF8TextThrows() throws {
        // 0xFF is never a valid UTF-8 byte, so NSString decoding returns nil.
        let url = try makeBundle(info: validInfoJSON, textFileName: "text.markdown", textData: Data([0xFF, 0xFE, 0xFF]))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(throws: (any Error).self) {
            _ = try TextBundleWrapper(contentsOf: url, options: .immediate)
        }
    }

    // MARK: Assets

    @Test func assetsAreLoadedAndLookedUpByFilename() throws {
        let url = try makeBundle(info: validInfoJSON, textFileName: "text.markdown", textData: Data("# Hi".utf8))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let assets = url.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: assets.appendingPathComponent("foo.png"))

        let wrapper = try TextBundleWrapper(contentsOf: url, options: .immediate)
        #expect(wrapper.assetsFileWrapper.fileWrappers?["foo.png"] != nil)
        #expect(wrapper.fileWrapper(forAssetFilename: "foo.png") != nil)
        #expect(wrapper.fileWrapper(forAssetFilename: "missing.png") == nil)
    }

    // MARK: Metadata

    @Test func nonMarkdownTypeIsReported() throws {
        let info = Data(#"{"version":2,"type":"public.plain-text"}"#.utf8)
        let url = try makeBundle(info: info, textFileName: "text.txt", textData: Data("hi".utf8))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let wrapper = try TextBundleWrapper(contentsOf: url, options: .immediate)
        #expect(wrapper.type == "public.plain-text")
        #expect(wrapper.type != kUTTypeMarkdown)
    }

    @Test func invalidInfoJSONThrows() throws {
        let url = try makeBundle(
            info: Data("{ not valid json".utf8),
            textFileName: "text.markdown",
            textData: Data("hi".utf8)
        )
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(throws: (any Error).self) {
            _ = try TextBundleWrapper(contentsOf: url, options: .immediate)
        }
    }

    @Test func nonDictionaryInfoJSONThrows() throws {
        // Valid JSON but a top-level array (not an object): must fail the read
        // instead of crashing on -[NSArray objectForKeyedSubscript:].
        let url = try makeBundle(info: Data("[1,2,3]".utf8), textFileName: "text.markdown", textData: Data("hi".utf8))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(throws: (any Error).self) {
            _ = try TextBundleWrapper(contentsOf: url, options: .immediate)
        }
    }
}
