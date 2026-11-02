import Foundation
import Testing
import UniformTypeIdentifiers

struct ShareExtractorTextFileTests {

    private static let utf8BOM = Data([0xEF, 0xBB, 0xBF])

    /// A byte order mark in front of the heading used to stop us from recognising it as the title.
    @Test func markdownWithByteOrderMarkUsesHeadingAsTitle() async throws {
        let contents = Self.utf8BOM + Data("# My Trip Report\n\nFirst paragraph.\n".utf8)

        let share = try await extract(fileNamed: "note.md", contents: contents)

        #expect(share.title.trimmingCharacters(in: .newlines) == "My Trip Report")
        #expect(share.importedText.contains("<p>First paragraph.</p>"))
        #expect(!share.importedText.contains("My Trip Report"))
        #expect(!share.importedText.containsByteOrderMark)
    }

    @Test func markdownWithoutByteOrderMarkUsesHeadingAsTitle() async throws {
        let contents = Data("# My Trip Report\n\nFirst paragraph.\n".utf8)

        let share = try await extract(fileNamed: "note.md", contents: contents)

        #expect(share.title.trimmingCharacters(in: .newlines) == "My Trip Report")
        #expect(share.importedText.contains("<p>First paragraph.</p>"))
    }

    @Test func plainTextWithByteOrderMarkDropsIt() async throws {
        let contents = Self.utf8BOM + Data("Plain text".utf8)

        let share = try await extract(fileNamed: "note.txt", contents: contents)

        #expect(share.importedText == "Plain text")
    }

    /// Reading a file should still detect encodings other than UTF-8.
    @Test func plainTextInUTF16IsDecoded() async throws {
        let contents = try #require("Héllo".data(using: .utf16))

        let share = try await extract(fileNamed: "note.txt", contents: contents)

        #expect(share.importedText == "Héllo")
    }

    /// Shares a file through the same path as the share sheet: a file URL in an `NSItemProvider`.
    private func extract(fileNamed name: String, contents: Data) async throws -> ExtractedShare {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent(name)
        try contents.write(to: fileURL)

        let item = NSExtensionItem()
        item.attachments = [NSItemProvider(item: fileURL as NSURL, typeIdentifier: UTType.url.identifier)]
        let context = StubExtensionContext(items: [item])

        return await withCheckedContinuation { continuation in
            ShareExtractor(extensionContext: context)
                .loadShare { outcome in
                    continuation.resume(returning: outcome.share)
                }
        }
    }
}

private final class StubExtensionContext: NSExtensionContext {
    private let items: [Any]

    init(items: [Any]) {
        self.items = items
        super.init()
    }

    override var inputItems: [Any] {
        items
    }
}

private extension String {
    var containsByteOrderMark: Bool {
        unicodeScalars.contains("\u{FEFF}")
    }
}
