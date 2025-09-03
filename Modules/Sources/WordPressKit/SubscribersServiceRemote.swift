import Foundation
import WordPressKitObjC

public class SubscribersServiceRemote: ServiceRemoteWordPressComREST {

    // MARK: GET Subscribers (Paginated List)

    public struct GetSubscribersParameters: Hashable {
        public var sortField: SortField?
        public var sortOrder: SortOrder?
        public var subscriptionTypeFilter: FilterSubscriptionType?
        public var paymentTypeFilter: FilterPaymentType?

        @frozen public enum SortField: String, CaseIterable {
            case dateSubscribed = "date_subscribed"
            case email = "email"
            case name = "name"
            case plan = "plan"
            case subscriptionStatus = "subscription_status"
        }

        @frozen public enum SortOrder: String, CaseIterable {
            case ascending = "asc"
            case descending = "dsc"
        }

        @frozen public enum FilterSubscriptionType: String, CaseIterable {
            case email = "email_subscriber"
            case reader = "reader_subscriber"
            case unconfirmed = "unconfirmed_subscriber"
            case blocked = "blocked_subscriber"
        }

        @frozen public enum FilterPaymentType: String, CaseIterable {
            case free
            case paid
        }

        public var filters: [String] {
            [subscriptionTypeFilter?.rawValue, paymentTypeFilter?.rawValue].compactMap { $0 }
        }

        public init(sortField: SortField? = nil, sortOrder: SortOrder? = nil, subscriptionTypeFilter: FilterSubscriptionType? = nil, paymentTypeFilter: FilterPaymentType? = nil) {
            self.sortField = sortField
            self.sortOrder = sortOrder
            self.subscriptionTypeFilter = subscriptionTypeFilter
            self.paymentTypeFilter = paymentTypeFilter
        }
    }

    public struct GetSubscribersResponse: Decodable {
        public var total: Int
        public var pages: Int
        public var page: Int
        public var subscribers: [Subscriber]

        public struct Subscriber: Decodable, SubsciberBasicInfoResponse {
            public let subscriberID: Int
            public let dotComUserID: Int
            public let displayName: String?
            public let avatar: String?
            public let emailAddress: String?
            public let dateSubscribed: Date
            public let isEmailSubscriptionEnabled: Bool
            public let subscriptionStatus: String?

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: StringCodingKey.self)
                subscriberID = try container.decode(Int.self, forKey: "subscription_id")
                dotComUserID = try container.decode(Int.self, forKey: "user_id")
                displayName = try? container.decodeIfPresent(String.self, forKey: "display_name")
                avatar = try? container.decodeIfPresent(String.self, forKey: "avatar")
                emailAddress = try? container.decodeIfPresent(String.self, forKey: "email_address")
                dateSubscribed = try container.decode(Date.self, forKey: "date_subscribed")
                isEmailSubscriptionEnabled = try container.decode(Bool.self, forKey: "is_email_subscriber")
                subscriptionStatus = try? container.decodeIfPresent(String.self, forKey: "subscription_status")
            }
        }
    }

    /// Gets the list of the site subscribers, including WordPress.com users and
    /// email subscribers.
    public func getSubscribers(
        siteID: Int,
        page: Int? = nil,
        perPage: Int? = 25,
        parameters: GetSubscribersParameters = .init(),
        search: String? = nil
    ) async throws -> GetSubscribersResponse {
        let url = self.path(forEndpoint: "sites/\(siteID)/subscribers", withVersion: ._2_0)
        var query: [String: Any] = [:]
        if let page {
            query["page"] = page
        }
        if let perPage {
            query["per_page"] = perPage
        }
        if let sortField = parameters.sortField {
            query["sort"] = sortField.rawValue
        }
        if let sortOrder = parameters.sortOrder {
            query["sort_order"] = sortOrder.rawValue
        }
        if !parameters.filters.isEmpty {
            query["filters"] = parameters.filters
        }
        if let search, !search.isEmpty {
            query["search"] = search
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats

        return try await wordPressComRestApi.perform(
            .get,
            URLString: url,
            parameters: query,
            jsonDecoder: decoder,
            type: GetSubscribersResponse.self
        ).get().body
    }

    // MARK: GET Subscriber (Individual Details)

    public protocol SubsciberBasicInfoResponse {
        var dotComUserID: Int { get }
        var subscriberID: Int { get }
        var displayName: String? { get }
        var emailAddress: String? { get }
        var avatar: String? { get }
        var dateSubscribed: Date { get }
    }

    public final class GetSubscriberDetailsResponse: Decodable, SubsciberBasicInfoResponse {
        public let subscriberID: Int
        public let dotComUserID: Int
        public let displayName: String?
        public let avatar: String?
        public let emailAddress: String?
        public let siteURL: String?
        public let dateSubscribed: Date
        public let isEmailSubscriptionEnabled: Bool
        public let subscriptionStatus: String?
        public let country: Country?
        public let plans: [Plan]?

        public struct Country: Decodable {
            public var code: String?
            public var name: String?
        }

        public struct Plan: Decodable {
            public let isGift: Bool
            public let giftId: Int?
            public let paidSubscriptionId: String?
            public let status: String
            public let title: String
            public let currency: String?
            public let renewInterval: String?
            public let inactiveRenewInterval: String?
            public let renewalPrice: Decimal
            public let startDate: Date
            public let endDate: Date

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: StringCodingKey.self)
                isGift = try container.decode(Bool.self, forKey: "is_gift")
                giftId = try container.decodeIfPresent(Int.self, forKey: "gift_id")
                paidSubscriptionId = try container.decodeIfPresent(String.self, forKey: "paid_subscription_id")
                status = try container.decode(String.self, forKey: "status")
                title = try container.decode(String.self, forKey: "title")
                currency = try container.decodeIfPresent(String.self, forKey: "currency")
                renewInterval = try? container.decodeIfPresent(String.self, forKey: "renew_interval")
                inactiveRenewInterval = try? container.decodeIfPresent(String.self, forKey: "inactive_renew_interval")
                renewalPrice = try container.decode(Decimal.self, forKey: "renewal_price")
                startDate = try container.decode(Date.self, forKey: "start_date")
                endDate = try container.decode(Date.self, forKey: "end_date")
            }
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: StringCodingKey.self)
            subscriberID = try container.decode(Int.self, forKey: "subscription_id")
            dotComUserID = try container.decode(Int.self, forKey: "user_id")
            displayName = try? container.decodeIfPresent(String.self, forKey: "display_name")
            avatar = try? container.decodeIfPresent(String.self, forKey: "avatar")
            emailAddress = try? container.decodeIfPresent(String.self, forKey: "email_address")
            siteURL = try? container.decodeIfPresent(String.self, forKey: "url")
            dateSubscribed = try container.decode(Date.self, forKey: "date_subscribed")
            isEmailSubscriptionEnabled = try container.decode(Bool.self, forKey: "is_email_subscriber")
            subscriptionStatus = try? container.decodeIfPresent(String.self, forKey: "subscription_status")
            country = try? container.decodeIfPresent(Country.self, forKey: "country")
            plans = try container.decodeIfPresent([Plan].self, forKey: "plans")
        }
    }

    /// Gets stats for the given subscriber.
    ///
    /// Example: https://public-api.wordpress.com/wpcom/v2/sites/239619264/subscribers/individual?subscription_id=907116368
    public func getSubsciberDetails(
        siteID: Int,
        subscriberID: Int,
        type: String = "email"
    ) async throws -> GetSubscriberDetailsResponse {
        let url = self.path(forEndpoint: "sites/\(siteID)/subscribers/individual", withVersion: ._2_0)
        let query: [String: Any] = [
            "subscription_id": subscriberID,
            "type": type
        ]

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.supportMultipleDateFormats

        return try await wordPressComRestApi.perform(
            .get,
            URLString: url,
            parameters: query,
            jsonDecoder: decoder,
            type: GetSubscriberDetailsResponse.self
        ).get().body
    }

    public struct GetSubscriberStatsResponse: Decodable {
        public var emailsSent: Int
        public var uniqueOpens: Int
        public var uniqueClicks: Int
    }

    /// Gets stats for the given subscriber.
    ///
    /// Example: https://public-api.wordpress.com/wpcom/v2/sites/239619264/individual-subscriber-stats?subscription_id=907116368
    public func getSubsciberStats(
        siteID: Int,
        subscriberID: Int
    ) async throws -> GetSubscriberStatsResponse {
        let url = self.path(forEndpoint: "sites/\(siteID)/individual-subscriber-stats", withVersion: ._2_0)
        let query: [String: Any] = [
            "subscription_id": subscriberID
        ]
        return try await wordPressComRestApi.perform(
            .get,
            URLString: url,
            parameters: query,
            jsonDecoder: JSONDecoder.apiDecoder,
            type: GetSubscriberStatsResponse.self
        ).get().body
    }

    // MARK: POST Import Subscribers

    /// Example: URL: https://public-api.wordpress.com/wpcom/v2/sites/216878809/subscribers/import?_envelope=1
    @discardableResult
    public func importSubscribers(
        siteID: Int,
        emails: [String]
    ) async throws -> ImportSubscribersResponse {
        let url = self.path(forEndpoint: "sites/\(siteID)/subscribers/import", withVersion: ._2_0)
        let parameters: [String: Any] = [
            "emails": emails,
            "parse_only": false
        ]
        return try await wordPressComRestApi.perform(
            .post,
            URLString: url,
            parameters: parameters,
            type: ImportSubscribersResponse.self
        ).get().body
    }

    public struct ImportSubscribersResponse: Decodable {
        public let uploadID: Int

        enum CodingKeys: String, CodingKey {
            case uploadID = "upload_id"
        }
    }
}

extension SubscribersServiceRemote.SubsciberBasicInfoResponse {
    public var avatarURL: URL? {
        avatar.flatMap(URL.init)
    }

    public var isDotComUser: Bool {
        dotComUserID > 0
    }
}
