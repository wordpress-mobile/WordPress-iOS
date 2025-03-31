@testable import WordPressAuthenticator

extension ProofKeyForCodeExchange.CodeVerifier {

    /// A code verifier for testing purposes that is guaranteed to be valid and deterministic.
    ///
    /// The reason we care about it being deterministic is because we don't want implicit randomness test.
    /// The only place were we want to use random values in the `CodeVerifier` tests which explicitly check the random generation.
    static func fixture() -> Self {
        .init(value: (0..<allowedLengthRange.lowerBound).map { _ in "a" }.joined())!
    }
}
