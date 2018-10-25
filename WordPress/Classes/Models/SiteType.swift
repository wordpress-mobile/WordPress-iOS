
/// A site type. There is already a SiteType enum in the codebase. To be renamed after we get rid of the old code
struct SiteType {
    let identifier: Identifier
    let title: String
    let subtitle: String
    let icon: URL
}

extension SiteType: Equatable {
    static func ==(lhs: SiteType, rhs: SiteType) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension SiteType: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title = "site-type-title"
        case subtitle = "site-type-subtitle"
        case icon
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try Identifier(value: values.decode(String.self, forKey: .id))
        title = try values.decode(String.self, forKey: .title)
        subtitle = try values.decode(String.self, forKey: .subtitle)
        icon = try values.decode(String.self, forKey: .icon).asURL()
    }
}
