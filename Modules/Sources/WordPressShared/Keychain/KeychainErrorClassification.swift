import Foundation
import Security

/// The error domain `SFHFKeychainUtils` uses for its own failures. Shared so
/// the classifier and its tests cannot drift to different spellings.
let sfhfKeychainErrorDomain = "SFHFKeychainUtilsErrorDomain"

/// Classifies errors thrown by `SFHFKeychainUtils`.
///
/// `SFHFKeychainUtils` populates an `NSError` in its own domain (with the raw
/// `OSStatus` as the code) only for real failures. A not-found surfaces either
/// as a nil result that Swift bridges to a generic non-SFHF error (reads), or
/// as an SFHF error whose code is `errSecItemNotFound` (deletes). So a real
/// failure is exactly an SFHF-domain error whose code is not `errSecItemNotFound`.
public func isRealKeychainFailure(_ error: Error) -> Bool {
    let nsError = error as NSError
    return nsError.domain == sfhfKeychainErrorDomain
        && nsError.code != Int(errSecItemNotFound)
}
