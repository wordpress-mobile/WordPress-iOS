// MARK: - SITE INFO
// MARK: -
struct SiteInfoNeed {
    let title: String
    let subtitle: String
    let sections: [SiteInfoSection]
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
        case siteOption = "site-option"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
        hint = try values.decode(String.self, forKey: .hint)
        siteOption = try Identifier(value: values.decode(String.self, forKey: .siteOption))
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
        case siteOption = "site-option"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
        hint = try values.decode(String.self, forKey: .hint)
        siteOption = try Identifier(value: values.decode(String.self, forKey: .siteOption))
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
