
/// Models a type of site.
struct Segment {
    let identifier: Identifier
    let title: String
    let subtitle: String
    let icon: URL
}

extension Segment: Equatable {
    static func ==(lhs: Segment, rhs: Segment) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension Segment: Decodable {
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
