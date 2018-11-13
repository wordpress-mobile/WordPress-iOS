// MARK: - PROTOCOL
// MARK: -
protocol SiteInfoNeed {
    var text: String { get }
    var hint: String? { get }
    var siteOption: Identifier? { get }
}

extension SiteInfoNeed where Self: Equatable {
    static func ==(lhs: SiteInfoNeed, rhs: SiteInfoNeed) -> Bool {
        return lhs.siteOption == rhs.siteOption
    }
}

// MARK: - IMPLEMENTATIONS
// MARK: - Text Info
struct TextInfoNeed: SiteInfoNeed, Equatable {
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
struct PhoneInfoNeed: SiteInfoNeed, Equatable {
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
struct HeaderInfoNeed: SiteInfoNeed, Equatable {
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
struct FooterInfoNeed: SiteInfoNeed, Equatable {
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
