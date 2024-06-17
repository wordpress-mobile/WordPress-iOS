import Foundation

/// Encapsulates the async request for a magic link and email validation for use cases that send a magic link.
struct MagicLinkRequester {
    /// Makes the call to request a magic authentication link be emailed to the user if possible.
    func requestMagicLink(email: String, jetpackLogin: Bool) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            guard email.isValidEmail() else {
                return continuation.resume(returning: .failure(MagicLinkRequestError.invalidEmail))
            }

            let service = WordPressComAccountService()
            service.requestAuthenticationLink(for: email,
                                              jetpackLogin: jetpackLogin,
                                              success: {
                continuation.resume(returning: .success(()))
            }, failure: { error in
                continuation.resume(returning: .failure(error))
            })
        }
    }
}

extension MagicLinkRequester {
    enum MagicLinkRequestError: Error {
        case invalidEmail
    }
}
