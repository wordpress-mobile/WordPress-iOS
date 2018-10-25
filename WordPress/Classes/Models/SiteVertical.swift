
/// Models a Site Vertical
struct SiteVertical {
    let id: Identifier
    let title: String
}

extension SiteVertical: Equatable {
    static func ==(lhs: SiteVertical, rhs: SiteVertical) -> Bool {
        return lhs.id == rhs.id
    }
}

extension SiteVertical: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title = "site-vertical-title"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try Identifier(value: values.decode(String.self, forKey: .id))
        title = try values.decode(String.self, forKey: .title)
    }
}
