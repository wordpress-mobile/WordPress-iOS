import Foundation
import Security
import Testing

@testable import WordPressShared

struct KeychainErrorClassificationTests {
    @Test func realSFHFFailureMapsToFailure() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecInteractionNotAllowed))
        #expect(keychainError(from: error) == .failure(errSecInteractionNotAllowed))
    }

    @Test func sfhfNotFoundMapsToNotFound() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecItemNotFound))
        #expect(keychainError(from: error) == .notFound)
    }

    @Test func synthesizedReadNotFoundMapsToNotFound() {
        enum ReadError: Error { case notFound }
        #expect(keychainError(from: ReadError.notFound) == .notFound)
    }

    @Test func entitlementMismatchMapsToFailure() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecMissingEntitlement))
        #expect(keychainError(from: error) == .failure(errSecMissingEntitlement))
    }

    /// `-1999` ("item present, no password data") is a deliberate `.failure`:
    /// rethrowing it preserves the previous behavior, where such an item does
    /// not fall back to another access group.
    @Test func malformedItemMapsToFailure() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: -1999)
        #expect(keychainError(from: error) == .failure(-1999))
    }

    /// Crash logging and `DataMigrationError` bridge the thrown error to
    /// `NSError`; the `OSStatus` must survive that bridge.
    @Test func failureBridgesToNSErrorCarryingOSStatus() {
        let nsError = KeychainError.failure(errSecInteractionNotAllowed) as NSError
        #expect(nsError.domain == sfhfKeychainErrorDomain)
        #expect(nsError.code == Int(errSecInteractionNotAllowed))
    }

    @Test func keychainErrorCodeReturnsStatusForSFHFError() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecMissingEntitlement))
        #expect(keychainErrorCode(error: error) == errSecMissingEntitlement)
    }

    @Test func keychainErrorCodeIsNilForForeignDomain() {
        let error = NSError(domain: NSCocoaErrorDomain, code: Int(errSecMissingEntitlement))
        #expect(keychainErrorCode(error: error) == nil)
    }
}
