import Foundation

/// Reads WordPress.com's web starter design catalog and runs the theme setup that follows applying a design.
public final class StarterDesignServiceRemote: ServiceRemoteWordPressComREST {

    /// Returns every design in the web starter design catalog, in catalog order.
    ///
    /// A design that fails to decode is dropped rather than failing the whole catalog.
    public func fetchStarterDesigns() async throws -> [StarterDesign] {
        let path = path(forEndpoint: "starter-designs", withVersion: ._2_0)
        let response = await wordPressComRestApi.perform(.get, URLString: path, type: StarterDesignsResponse.self)
        return try response.get().body.designs
    }

    /// Asks WordPress.com to insert placeholder content for the site's active theme.
    ///
    /// WordPress.com only does this when the theme's home template has a blog pattern. It answers HTTP 200 with
    /// either an object or the bare value `false`.
    ///
    /// - Returns: `true` when the response is an object whose `result` is `success`; `false` for a boolean body
    ///   or any other result.
    /// - Throws: A transport error, or a decoding error for a body that is neither an object nor a boolean.
    public func runThemeSetup(siteID: Int) async throws -> Bool {
        let path = path(forEndpoint: "sites/\(siteID)/theme-setup", withVersion: ._2_0)
        let response = await wordPressComRestApi.perform(.post, URLString: path, type: ThemeSetupResponse.self)
        return try response.get().body.isCompleted
    }
}

private struct StarterDesignsResponse: Decodable {
    let designs: [StarterDesign]

    private enum CodingKeys: String, CodingKey {
        case `static`
    }

    private enum StaticKeys: String, CodingKey {
        case designs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let staticContainer = try container.nestedContainer(keyedBy: StaticKeys.self, forKey: .static)
        designs = try staticContainer.decode([LossyStarterDesign].self, forKey: .designs).compactMap(\.design)
    }
}

private struct LossyStarterDesign: Decodable {
    let design: StarterDesign?

    init(from decoder: Decoder) throws {
        design = try? StarterDesign(from: decoder)
    }
}

private struct ThemeSetupResponse: Decodable {
    let isCompleted: Bool

    private enum CodingKeys: String, CodingKey {
        case result
    }

    init(from decoder: Decoder) throws {
        // Only an object reports a completed setup; WordPress.com answers `false` when it skipped the setup.
        if (try? decoder.singleValueContainer().decode(Bool.self)) != nil {
            isCompleted = false
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isCompleted = try container.decodeIfPresent(String.self, forKey: .result) == "success"
    }
}
