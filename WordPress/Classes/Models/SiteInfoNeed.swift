fileprivate enum SiteInfoNeedType: String, Decodable {
    case text
    case phoneNum = "phone-num"
    case header
    case footer
}

fileprivate struct GenericNeed: Decodable {
    let type: SiteInfoNeedType
    let text: String
    let hint: String?
    let siteOption: Identifier?

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case hint
        case site_option
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(SiteInfoNeedType.self, forKey: .type)
        text = try values.decode(String.self, forKey: .text)
        if values.contains(.hint) {
            hint = try values.decode(String.self, forKey: .hint)
        } else {
            hint = nil
        }
        if values.contains(.site_option) {
            siteOption = try Identifier(value: values.decode(String.self, forKey: .site_option))
        } else {
            siteOption = nil
        }
    }
}


// MARK: - SITE INFO
// MARK: -
struct SiteInfoNeed {
    let title: String
    let subtitle: String
    let sections: [SiteInfoSection]
}

extension SiteInfoNeed: Decodable {
    private enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case needs
    }


    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        subtitle = try values.decode(String.self, forKey: .subtitle)
        sections = try values.decode([GenericNeed].self, forKey: .needs).map { need in
            switch need.type {
            case .text:
                return TextInfoNeed(text: need.text, hint: need.hint, siteOption: need.siteOption)
            case .phoneNum:
                return PhoneInfoNeed(text: need.text, hint: need.hint, siteOption: need.siteOption)
            case .header:
                return HeaderInfoNeed(text: need.text)
            case .footer:
                return FooterInfoNeed(text: need.text)
            }
        }
    }
}

// MARK: - PROTOCOL
// MARK: -
protocol SiteInfoSection {
    var text: String { get }
    var hint: String? { get }
    var siteOption: Identifier? { get }
}

extension SiteInfoSection where Self: Equatable {
    static func ==(lhs: SiteInfoSection, rhs: SiteInfoSection) -> Bool {
        return lhs.siteOption == rhs.siteOption
    }
}

// MARK: - IMPLEMENTATIONS
// MARK: - Text Info
struct TextInfoNeed: SiteInfoSection, Equatable {
    private let type = "text"
    let text: String
    let hint: String?
    let siteOption: Identifier?
}

extension TextInfoNeed: Decodable {
    enum CodingKeys: String, CodingKey {
        case text
        case hint
        case site_option
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
        hint = try values.decode(String.self, forKey: .hint)
        siteOption = try Identifier(value: values.decode(String.self, forKey: .site_option))
    }
}

// MARK: - Phone Info
struct PhoneInfoNeed: SiteInfoSection, Equatable {
    private let type = "phone-num"
    let text: String
    let hint: String?
    let siteOption: Identifier?
}

extension PhoneInfoNeed: Decodable {
    enum CodingKeys: String, CodingKey {
        case text
        case hint
        case site_option
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
        hint = try values.decode(String.self, forKey: .hint)
        siteOption = try Identifier(value: values.decode(String.self, forKey: .site_option))
    }
}

// MARK: - Header
struct HeaderInfoNeed: SiteInfoSection, Equatable {
    private let type = "header"
    let text: String
    let hint: String? = nil
    let siteOption: Identifier? = nil
}

extension HeaderInfoNeed: Decodable {
    enum CodingKeys: String, CodingKey {
        case text
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
    }
}

// MARK: - Footer
struct FooterInfoNeed: SiteInfoSection, Equatable {
    private let type = "footer"
    let text: String
    let hint: String? = nil
    let siteOption: Identifier? = nil
}

extension FooterInfoNeed: Decodable {
    enum CodingKeys: String, CodingKey {
        case text
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
    }
}
