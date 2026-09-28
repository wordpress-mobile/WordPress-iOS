import Foundation
import Testing
@testable import Support

struct UnifiedSupportAttachmentValidatorTests {

    private let validator = UnifiedSupportAttachmentValidator(maximumUploadSize: 100)

    @Test func acceptsTheFilesThatFit() {
        let files = [makeFile(fileSize: 40), makeFile(fileSize: 60)]

        let result = validator.validate(files)

        #expect(result.accepted == files)
        #expect(result.skipped.isEmpty)
        #expect(result.acceptedSize == 100)
        #expect(result.skippedSize == 0)
    }

    @Test func skipsTheFilesThatDoNotFit() {
        let fitting = makeFile(fileSize: 90)
        let tooLarge = makeFile(fileSize: 30)

        let result = validator.validate([fitting, tooLarge])

        #expect(result.accepted == [fitting])
        #expect(result.skipped == [tooLarge])
        #expect(result.acceptedSize == 90)
        #expect(result.skippedSize == 30)
    }

    /// Files are taken in the order they were picked, so a later file can't jump the queue by being smaller.
    @Test func keepsThePickingOrder() {
        let large = makeFile(fileSize: 100)
        let small = makeFile(fileSize: 1)

        let result = validator.validate([large, small])

        #expect(result.accepted == [large])
        #expect(result.skipped == [small])
    }

    @Test func makesRoomWhenAnAcceptedFileIsRemoved() {
        let large = makeFile(fileSize: 90)
        let small = makeFile(fileSize: 20)

        let result = validator.validate([large, small].filter { $0.id != large.id })

        #expect(result.accepted == [small])
        #expect(result.skipped.isEmpty)
    }

    /// The system doesn't always report a size, and a file is worth sending even when its size is unknown.
    @Test func acceptsFilesOfUnknownSize() {
        let unknown = makeFile(fileSize: 0)

        let result = validator.validate([makeFile(fileSize: 100), unknown])

        #expect(result.accepted.count == 2)
        #expect(result.skipped.isEmpty)
    }

    private func makeFile(fileSize: UInt64) -> UnifiedSupportPickedFile {
        UnifiedSupportPickedFile(url: URL(fileURLWithPath: "/tmp/\(UUID().uuidString).png"), fileSize: fileSize)
    }
}
