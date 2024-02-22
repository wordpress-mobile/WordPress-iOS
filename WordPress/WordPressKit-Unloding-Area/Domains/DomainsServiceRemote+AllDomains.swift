import Foundation

extension DomainsServiceRemote {

    // MARK: - API

    /// Makes a call request to `GET /v1.1/all-domains` and returns a list of domain objects.
    ///
    /// The endpoint accepts 3 **optionals** query params:
    /// - `resolve_status` of type `boolean`. If `true`, the response will include a `status` attribute for each `domain` object.
    /// - `no_wpcom`of type `boolean`. If `true`, the respnse won't include `wpcom` domains.
    /// - `locale` of type `string`. Used for string localization.
    public func fetchAllDomains(params: AllDomainsEndpointParams? = nil, completion: @escaping (AllDomainsEndpointResult) -> Void) {
        let path = self.path(forEndpoint: "all-domains", withVersion: ._1_1)
        let parameters: [String: AnyObject]?

        do {
            parameters = try queryParameters(from: params)
        } catch let error {
            completion(.failure(error))
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        Task { @MainActor in
            await self.wordPressComRestApi
                .perform(
                    .get,
                    URLString: path,
                    parameters: parameters,
                    jsonDecoder: decoder,
                    type: AllDomainsEndpointResponse.self
                )
                .map { $0.body.domains }
                .mapError { error -> Error in error.asNSError() }
                .execute(completion)
        }
    }

    private func queryParameters(from params: AllDomainsEndpointParams?) throws -> [String: AnyObject]? {
        guard let params else {
            return nil
        }
        let encoder = JSONEncoder()
        let data = try encoder.encode(params)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject]
        return dict
    }

    // MARK: - Public Types

    public typealias AllDomainsEndpointResult = Result<[AllDomainsListItem], Error>

    public struct AllDomainsEndpointParams {

        public var resolveStatus: Bool = false
        public var noWPCOM: Bool = false
        public var locale: String?

        public init() {}
    }

    public struct AllDomainsListItem {

        public enum StatusType: String {
            case success
            case premium
            case neutral
            case warning
            case alert
            case error
        }

        public struct Status {

            public let value: String
            public let type: StatusType

            public init(value: String, type: StatusType) {
                self.value = value
                self.type = type
            }
        }

        public let domain: String
        public let blogId: Int
        public let blogName: String
        public let type: DomainType
        public let isDomainOnlySite: Bool
        public let isWpcomStagingDomain: Bool
        public let hasRegistration: Bool
        public let registrationDate: Date?
        public let expiryDate: Date?
        public let wpcomDomain: Bool
        public let currentUserIsOwner: Bool?
        public let siteSlug: String
        public let status: Status?
    }

    // MARK: - Private Types

    private struct AllDomainsEndpointResponse: Decodable {
        let domains: [AllDomainsListItem]
    }
}

// MARK: - Encoding / Decoding

extension DomainsServiceRemote.AllDomainsEndpointParams: Encodable {

    enum CodingKeys: String, CodingKey {
        case resolveStatus = "resolve_status"
        case locale
        case noWPCOM = "no_wpcom"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(resolveStatus)", forKey: .resolveStatus)
        try container.encode("\(noWPCOM)", forKey: .noWPCOM)
        try container.encodeIfPresent(locale, forKey: .locale)
    }
}

extension DomainsServiceRemote.AllDomainsListItem.StatusType: Decodable {
}

extension DomainsServiceRemote.AllDomainsListItem.Status: Decodable {
    enum CodingKeys: String, CodingKey {
        case value = "status"
        case type = "status_type"
    }
}

extension DomainsServiceRemote.AllDomainsListItem: Decodable {

    enum CodingKeys: String, CodingKey {
        case domain
        case blogId = "blog_id"
        case blogName = "blog_name"
        case type
        case isDomainOnlySite = "is_domain_only_site"
        case isWpcomStagingDomain = "is_wpcom_staging_domain"
        case hasRegistration = "has_registration"
        case registrationDate = "registration_date"
        case expiryDate = "expiry"
        case wpcomDomain = "wpcom_domain"
        case currentUserIsOwner = "current_user_is_owner"
        case siteSlug = "site_slug"
        case status = "domain_status"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.blogId = try container.decode(Int.self, forKey: .blogId)
        self.blogName = try container.decode(String.self, forKey: .blogName)
        self.isDomainOnlySite = try container.decode(Bool.self, forKey: .isDomainOnlySite)
        self.isWpcomStagingDomain = try container.decode(Bool.self, forKey: .isWpcomStagingDomain)
        self.hasRegistration = try container.decode(Bool.self, forKey: .hasRegistration)
        self.wpcomDomain = try container.decode(Bool.self, forKey: .wpcomDomain)
        self.currentUserIsOwner = try container.decode(Bool?.self, forKey: .currentUserIsOwner)
        self.siteSlug = try container.decode(String.self, forKey: .siteSlug)
        self.registrationDate = try {
            if let timestamp = try? container.decodeIfPresent(String.self, forKey: .registrationDate), !timestamp.isEmpty {
                return try container.decode(Date.self, forKey: .registrationDate)
            }
            return nil
        }()
        self.expiryDate = try {
            if let timestamp = try? container.decodeIfPresent(String.self, forKey: .expiryDate), !timestamp.isEmpty {
                return try container.decode(Date.self, forKey: .expiryDate)
            }
            return nil
        }()
        let type: String = try container.decode(String.self, forKey: .type)
        self.type = .init(type: type, wpComDomain: wpcomDomain, hasRegistration: hasRegistration)
        self.status = try container.decodeIfPresent(Status.self, forKey: .status)
    }
}
