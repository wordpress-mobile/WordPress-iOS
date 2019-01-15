
/// Models a type of site.
struct SiteSegment {
    let identifier: Int64   // we use a numeric ID for segments; see p9wMUP-bH-612-p2 for discussion
    let title: String
    let subtitle: String
    let icon: URL?
    let iconColor: UIColor?
    let mobile: Bool
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
        case segmentId = "id"
        case segmentTypeTitle = "segment_type_title"
        case segmentTypeSubtitle = "segment_type_subtitle"
        case iconURL = "icon_URL"
        case iconColor = "icon_color"
        case mobile = "mobile"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try values.decode(Int64.self, forKey: .segmentId)
        title = try values.decode(String.self, forKey: .segmentTypeTitle)
        subtitle = try values.decode(String.self, forKey: .segmentTypeSubtitle)
        if let iconString = try values.decodeIfPresent(String.self, forKey: .iconURL) {
            icon = URL(string: iconString)
        } else {
            icon = nil
        }

        if let iconColorString = try values.decodeIfPresent(String.self, forKey: .iconColor) {
            var cleanIconColorString = iconColorString
            if iconColorString.hasPrefix("#") {
                cleanIconColorString = String(iconColorString.dropFirst(1))
            }

            iconColor = cleanIconColorString.asColor()
        } else {
            iconColor = nil
        }

        mobile = try values.decode(Bool.self, forKey: .mobile)

    }
}

private extension String {
    func asColor() -> UIColor? {
        return UIColor(hexString: self)
    }
}
