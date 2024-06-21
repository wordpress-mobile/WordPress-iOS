import Foundation

/// Retrieves feature announcements from the related endpoint
public class AnnouncementServiceRemote: ServiceRemoteWordPressComREST {

    public func getAnnouncements(appId: String,
                                 appVersion: String,
                                 locale: String,
                                 completion: @escaping (Result<[Announcement], Error>) -> Void) {

        guard let endPoint = makeEndpoint(appId: appId, appVersion: appVersion, locale: locale) else {
            completion(.failure(AnnouncementError.endpointError))
            return
        }

        let path = self.path(forEndpoint: endPoint, withVersion: ._2_0)
        Task { @MainActor [wordPressComRestApi] in
            await wordPressComRestApi.perform(.get, URLString: path, type: AnnouncementsContainer.self)
                .map { $0.body.announcements }
                .eraseToError()
                .execute(completion)
        }
    }
}

// MARK: - Helpers
private extension AnnouncementServiceRemote {

    func makeQueryItems(appId: String, appVersion: String, locale: String) -> [URLQueryItem] {
        return [URLQueryItem(name: Constants.appIdKey, value: appId),
                URLQueryItem(name: Constants.appVersionKey, value: appVersion),
                URLQueryItem(name: Constants.localeKey, value: locale)]
    }

    func makeEndpoint(appId: String, appVersion: String, locale: String) -> String? {
        var path = URLComponents(string: Constants.baseUrl)
        path?.queryItems = makeQueryItems(appId: appId, appVersion: appVersion, locale: locale)
        return path?.string
    }
}

// MARK: - Constants
private extension AnnouncementServiceRemote {

    enum Constants {
        static let baseUrl = "mobile/feature-announcements/"
        static let appIdKey = "app_id"
        static let appVersionKey = "app_version"
        static let localeKey = "_locale"
    }

    enum AnnouncementError: Error {
        case endpointError

        var localizedDescription: String {
            switch self {
            case .endpointError:
                return NSLocalizedString("Invalid endpoint",
                                         comment: "Error message generated when announcement service is unable to return a valid endpoint.")
            }
        }
    }
}

// MARK: - Decoded data
public struct AnnouncementsContainer: Decodable {
    public let announcements: [Announcement]

    private enum CodingKeys: String, CodingKey {
        case announcements = "announcements"
    }

    public init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
        announcements = try rootContainer.decode([Announcement].self, forKey: .announcements)
    }
}

public struct Announcement: Codable {
    public let appVersionName: String
    public let minimumAppVersion: String
    public let maximumAppVersion: String
    public let appVersionTargets: [String]
    public let detailsUrl: String
    public let announcementVersion: String
    public let isLocalized: Bool
    public let responseLocale: String
    public let features: [Feature]
}

public struct Feature: Codable {
    public let title: String
    public let subtitle: String
    public let icons: [FeatureIcon]?
    public let iconUrl: String
    public let iconBase64: String?
}

public struct FeatureIcon: Codable {
    public let iconUrl: String
    public let iconBase64: String
    public let iconType: String
}
