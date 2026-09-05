import Foundation
import Testing

@testable import WordPress

struct ItemProviderMediaExporterErrorTests {

    /// The exact error shape observed on device (under iOS Lockdown Mode) when the
    /// Photos provider is killed while materializing a large image:
    /// `NSItemProviderErrorDomain -1000` wrapping `NSCocoaErrorDomain 4099`.
    @Test func detectsProviderProcessDeathFromNestedXPCError() {
        let xpcError = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.xpcConnectionInvalid.rawValue)
        let itemProviderError = NSError(
            domain: "NSItemProviderErrorDomain",
            code: -1000,
            userInfo: [NSUnderlyingErrorKey: xpcError]
        )

        let match = ItemProviderMediaExporter.providerConnectionError(in: itemProviderError)

        #expect(match?.domain == NSCocoaErrorDomain)
        #expect(match?.code == CocoaError.Code.xpcConnectionInvalid.rawValue)
    }

    @Test func detectsXPCConnectionInterruptedAtTopLevel() {
        let error = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.xpcConnectionInterrupted.rawValue)
        #expect(ItemProviderMediaExporter.providerConnectionError(in: error) != nil)
    }

    @Test func findsXPCErrorNestedSeveralLevelsDeep() {
        let xpcError = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.xpcConnectionReplyInvalid.rawValue)
        let middle = NSError(domain: "Middle", code: 1, userInfo: [NSUnderlyingErrorKey: xpcError])
        let outer = NSError(domain: "Outer", code: 2, userInfo: [NSUnderlyingErrorKey: middle])
        #expect(ItemProviderMediaExporter.providerConnectionError(in: outer) != nil)
    }

    /// A provider-death XPC error can be buried several layers down a wrapped chain.
    /// The classifier must still find it: the chain-walk previously enqueued every
    /// wrapped error twice (`underlyingErrors` *and* `NSUnderlyingErrorKey`), exhausting
    /// its traversal budget long before reaching errors this deep.
    @Test func findsXPCErrorFiveLevelsDeep() {
        let xpcError = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.xpcConnectionInvalid.rawValue)
        // Bury the XPC error five `NSUnderlyingErrorKey` levels down.
        var nested: Error = xpcError
        for level in 1...5 {
            nested = NSError(domain: "Wrapper\(level)", code: level, userInfo: [NSUnderlyingErrorKey: nested])
        }
        let match = ItemProviderMediaExporter.providerConnectionError(in: nested)
        #expect(match?.code == CocoaError.Code.xpcConnectionInvalid.rawValue)
    }

    /// A generic Cocoa error that is *not* an XPC connection failure must not match —
    /// otherwise every load failure would be misreported as a provider process death.
    @Test func ignoresUnrelatedCocoaError() {
        let error = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.fileNoSuchFile.rawValue)
        #expect(ItemProviderMediaExporter.providerConnectionError(in: error) == nil)
    }

    /// The same numeric code in a different domain is not an XPC error.
    @Test func ignoresXPCCodeInADifferentDomain() {
        let error = NSError(domain: "SomeOtherDomain", code: CocoaError.Code.xpcConnectionInvalid.rawValue)
        #expect(ItemProviderMediaExporter.providerConnectionError(in: error) == nil)
    }

    // MARK: - Cancellation

    /// A user-cancelled load must not be surfaced as an error (it would show a
    /// spurious "failed" message for an upload the user deliberately cancelled).
    @Test func detectsUserCancellation() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        #expect(ItemProviderMediaExporter.isCancellation(error))
    }

    @Test func detectsURLCancellation() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        #expect(ItemProviderMediaExporter.isCancellation(error))
    }

    @Test func detectsSwiftConcurrencyCancellation() {
        #expect(ItemProviderMediaExporter.isCancellation(CancellationError()))
    }

    @Test func detectsCancellationNestedInChain() {
        let cancel = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        let outer = NSError(domain: "Outer", code: 1, userInfo: [NSUnderlyingErrorKey: cancel])
        #expect(ItemProviderMediaExporter.isCancellation(outer))
    }

    /// A provider-death (XPC) error is a genuine failure, not a cancellation.
    @Test func doesNotTreatXPCFailureAsCancellation() {
        let error = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.xpcConnectionInvalid.rawValue)
        #expect(!ItemProviderMediaExporter.isCancellation(error))
    }

    @Test func doesNotTreatUnrelatedErrorAsCancellation() {
        let error = NSError(domain: NSCocoaErrorDomain, code: CocoaError.Code.fileNoSuchFile.rawValue)
        #expect(!ItemProviderMediaExporter.isCancellation(error))
    }
}
