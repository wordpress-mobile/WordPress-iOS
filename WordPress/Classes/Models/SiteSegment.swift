
/// Models a type of site.
struct SiteSegment {
    let identifier: Int64   // we use a numeric ID for segments; see p9wMUP-bH-612-p2 for discussion
    let title: String
    let subtitle: String
    let icon: URL
    let iconColor: UIColor?
}

extension SiteSegment {
    static let blogSegmentIdentifier = Int64(1)
}

extension SiteSegment: Equatable {
    static func ==(lhs: SiteSegment, rhs: SiteSegment) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension SiteSegment: Decodable {
    enum CodingKeys: String, CodingKey {
        case segmentId = "segment_id"
        case segmentTypeTitle = "segment_type_title"
        case segmentTypeSubtitle = "segment_type_subtitle"
        case iconURL = "icon_URL"
        case iconColor = "icon_color"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try values.decode(Int64.self, forKey: .segmentId)
        title = try values.decode(String.self, forKey: .segmentTypeTitle)
        subtitle = try values.decode(String.self, forKey: .segmentTypeSubtitle)
        icon = try values.decode(String.self, forKey: .iconURL).asURL()
        iconColor = try values.decode(String.self, forKey: .iconColor).asColor()
    }
}

private extension String {
    func asColor() -> UIColor? {
        return UIColor(hexString: self)
    }
}
