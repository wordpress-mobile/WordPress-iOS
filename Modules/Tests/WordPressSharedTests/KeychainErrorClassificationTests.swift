import Foundation
import Security
import Testing

@testable import WordPressShared

struct KeychainErrorClassificationTests {
    @Test func realSFHFFailureIsReal() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecInteractionNotAllowed))
        #expect(isRealKeychainFailure(error))
    }

    @Test func sfhfNotFoundIsBenign() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecItemNotFound))
        #expect(!isRealKeychainFailure(error))
    }

    @Test func synthesizedReadNotFoundIsBenign() {
        enum ReadError: Error { case notFound }
        #expect(!isRealKeychainFailure(ReadError.notFound))
    }

    @Test func entitlementMismatchIsRealFailure() {
        let error = NSError(domain: sfhfKeychainErrorDomain, code: Int(errSecMissingEntitlement))
        #expect(isRealKeychainFailure(error))
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
