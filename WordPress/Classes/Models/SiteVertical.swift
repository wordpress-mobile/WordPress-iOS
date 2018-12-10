
/// Models a Site Vertical
struct SiteVertical {
    let identifier: Identifier
    let title: String
    let isNew: Bool
}

extension SiteVertical: Equatable {
    static func ==(lhs: SiteVertical, rhs: SiteVertical) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension SiteVertical: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title = "site_vertical_title"
        case isNew = "is_new_user_vertical"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try Identifier(value: values.decode(String.self, forKey: .id))
        title = try values.decode(String.self, forKey: .title)
        let isNewString = try values.decode(String.self, forKey: .isNew)
        isNew = isNewString.lowercased() == "true" ? true : false
    }
}
