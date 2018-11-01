
/// Models a type of site.
struct SiteSegment {
    let identifier: Identifier
    let title: String
    let subtitle: String
    let icon: URL
}

extension SiteSegment: Equatable {
    static func ==(lhs: SiteSegment, rhs: SiteSegment) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension SiteSegment: Decodable {
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
