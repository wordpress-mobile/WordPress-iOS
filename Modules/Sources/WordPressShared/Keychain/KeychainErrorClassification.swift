import Foundation
import Logging
import Security

/// The error domain `SFHFKeychainUtils` uses for its own failures. Shared so
/// the classifier and its tests cannot drift to different spellings.
let sfhfKeychainErrorDomain = "SFHFKeychainUtilsErrorDomain"

/// The underlying Keychain `OSStatus` for an error produced by
/// `SFHFKeychainUtils`, or `nil` when the error is not from that domain.
///
/// `SFHFKeychainUtils` reports real failures as an `NSError` in its own domain,
/// carrying the raw Keychain `OSStatus` as the code. A not-found read instead
/// bridges to a generic error in another domain. Centralizing the domain check
/// and the `Int` -> `OSStatus` conversion here lets callers compare directly
/// against the `errSec*` constants.
func keychainErrorCode(error: Error) -> OSStatus? {
    let nsError = error as NSError
    guard nsError.domain == sfhfKeychainErrorDomain else { return nil }
    return OSStatus(truncatingIfNeeded: nsError.code)
}

/// Whether an error from `SFHFKeychainUtils` is a real failure rather than the
/// expected not-found. A not-found surfaces either as a non-SFHF error (reads)
/// or as an SFHF error whose code is `errSecItemNotFound` (deletes).
public func isRealKeychainFailure(_ error: Error) -> Bool {
    guard let code = keychainErrorCode(error: error) else { return false }
    return code != errSecItemNotFound
}

private let keychainLogger = Logger(label: (Bundle.main.bundleIdentifier!) + ".keychain")

/// Logs a real keychain failure. An entitlement mismatch is fatal: it means
/// the access group is unreachable for the entire build (a provisioning or
/// build-settings defect, not a runtime condition), so there is nothing to
/// recover to and we crash to surface it immediately. Does nothing for the
/// expected not-found.
///
/// For every other failure this only emits telemetry and does not change
/// control flow: callers still throw, fall back, or swallow as before. The
/// source location identifies which call site (read, write, or delete) failed.
func reportKeychainFailureIfNeeded(
    _ error: Error,
    serviceName: String,
    accessGroup: String,
    file: StaticString = #fileID,
    line: UInt = #line
) {
    guard let status = keychainErrorCode(error: error), status != errSecItemNotFound else {
        return
    }

    if status == errSecMissingEntitlement {
        fatalError(
            "Keychain entitlement mismatch (service: \(serviceName), group: \(accessGroup))",
            file: file,
            line: line
        )
    }

    keychainLogger.error(
        "Keychain failure (service: \(serviceName), group: \(accessGroup), status: \(status)) at \(file):\(line)"
    )
}
