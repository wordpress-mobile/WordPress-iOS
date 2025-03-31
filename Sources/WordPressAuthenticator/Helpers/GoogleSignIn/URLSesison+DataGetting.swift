import Foundation

// In other projects, we avoid extending `URLSession` to conform to "-getting" protocols shaped
// like `DataGetting` and prefer composition instead, creating an object conforming to the protocol
// and holding an `URLSession` reference.
//
// The concern with extending a Foundation type with special-purpose domain object getting ability
// is that it would pollute the namespace, offering the protocol methods as an option everywhere
// `URLSession` is used, even in part of the app that are unrelated with the resource.
//
// But since the type `DataGetting` revolves around is `Data` and `URLSession` already exposes
// methods returning `Data`, this feels more like a syntax-sugar extension rather than one adding
// whole new domain-specific APIs to the type.
extension URLSession: DataGetting {

    func data(for request: URLRequest) async throws -> Data {
        let (data, _) = try await data(for: request)
        return data
    }
}
