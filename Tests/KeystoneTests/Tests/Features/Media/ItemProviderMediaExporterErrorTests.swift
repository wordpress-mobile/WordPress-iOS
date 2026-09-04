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
}
