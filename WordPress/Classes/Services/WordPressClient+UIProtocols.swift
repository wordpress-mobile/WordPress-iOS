import WordPressAPI
import WordPressCore

extension WordPressClient: PluginInstallerProtocol {
    func installAndActivatePlugin(slug: String) async throws {
        let params = PluginCreateParams(
            slug: PluginWpOrgDirectorySlug(slug: slug),
            status: .active
        )

        _ = try await self.api.plugins.create(params: params)
    }
}
