@testable import WordPressKit

struct MockPluginStateProvider: DynamicMockProvider {

    static func getPluginState(setToActive active: Bool = false, autoupdate: Bool = false) -> PluginState {
        let jetpackDevPlugin = PluginState(id: "jetpack-dev/jetpack",
                                           slug: "jetpack-dev",
                                           active: active,
                                           name: "Jetpack by WordPress.com",
                                           author: "Automattic",
                                           version: "5.4",
                                           updateState: PluginState.UpdateState.updated,
                                           autoupdate: autoupdate,
                                           automanaged: false,
                                           url: URL(string: "https://jetpack.com/"),
                                           settingsURL: URL(string: "https://example.com/wp-admin/admin.php?page=jetpack#/settings")
        )

        return jetpackDevPlugin
    }

    static func getDynamicValuePluginState(setToActive active: Bool = false, autoupdate: Bool = false, automanaged: Bool = false, updateState: PluginState.UpdateState = PluginState.UpdateState.updated) -> PluginState {
        return PluginState(id: MockPluginStateProvider.getDynamicPluginID(),
                           slug: MockPluginStateProvider.randomIntAsString(limit: 25),
                           active: active,
                           name: MockPluginStateProvider.randomString(length: 25),
                           author: MockPluginStateProvider.randomString(length: 15),
                           version: MockPluginStateProvider.randomIntAsString(limit: 5),
                           updateState: updateState,
                           autoupdate: autoupdate,
                           automanaged: false,
                           url: URL(string: MockPluginStateProvider.randomURLAsString()),
                           settingsURL: nil
        )
    }

    static func getDynamicPluginStateJSONResponse() throws -> Data {
        let slug = randomString(length: 10)

        let pluginState = EncodableMockPluginState(id: "\(slug)/\(slug)",
                                      slug: slug,
                                      active: randomBool(),
                                      name: randomString(length: 20),
                                      author: randomString(length: 15),
                                      version: getRandomVersionNumber(),
                                      updateState: PluginState.UpdateState.updated,
                                      autoupdate: randomBool(),
                                      automanaged: randomBool(),
                                      url: URL(string: randomURLAsString(length: 15)),
                                      settingsURL: URL(string: randomURLAsString(length: 15)))

        let jsonEncoder = JSONEncoder()
        let data = try jsonEncoder.encode(pluginState)

        return data
    }

        static func getEncodedDynamicPluginState() throws -> Data {
            let slug = randomString(length: 10)

            let pluginState = PluginState(id: "\(slug)/\(slug)",
                                          slug: slug,
                                          active: randomBool(),
                                          name: randomString(length: 20),
                                          author: randomString(length: 15),
                                          version: getRandomVersionNumber(),
                                          updateState: PluginState.UpdateState.updated,
                                          autoupdate: randomBool(),
                                          automanaged: randomBool(),
                                          url: URL(string: randomURLAsString(length: 15)),
                                          settingsURL: URL(string: randomURLAsString(length: 15)))

            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(pluginState)

            return data
        }

    private static func getDynamicPluginID() -> String {
        let id = MockPluginStateProvider.randomString(length: 10)

        return id + "/" + id
    }

    static func getEncodedUpdateState(state: PluginState.UpdateState) throws -> Data {
        var data = Data()
        let encoder = JSONEncoder()

        data = try encoder.encode(state)

        return data
    }

    static func getRandomVersionNumber() -> String {
        let majorRelease = randomIntAsString(limit: 99)
        let subRelease = randomIntAsString(limit: 99)
        let pointRelease = randomIntAsString(limit: 99)

        return "\(majorRelease).\(subRelease).\(pointRelease)"
    }
}

struct EncodableMockPluginState: Encodable {
    let id: String
    let slug: String
    let active: Bool
    let name: String
    let author: String
    let version: String?
    let updateState: PluginState.UpdateState
    let autoupdate: Bool
    let automanaged: Bool?
    let url: URL?
    let settingsURL: URL?

    enum CodingKeys: String, CodingKey {
        case id = "name"
        case slug
        case active
        case name = "display_name"
        case author
        case version
        case updateState
        case autoupdate
        case automanaged
        case url = "plugin_url"
        case settingsURL = "Settings"
    }
}
