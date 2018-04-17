import Foundation
import WordPressShared

public class TimeZoneServiceRemote: ServiceRemoteWordPressComREST {
    public enum ResponseError: Error {
        case decodingFailed
    }

    public func getTimezones(success: @escaping (([TimeZoneGroup]) -> Void), failure: @escaping ((Error) -> Void)) {
        let endpoint = "timezones"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let parameters: [String: AnyObject] = ["_locale": locale as AnyObject]
        wordPressComRestApi.GET(path, parameters: parameters, success: { (response, _) in
            do {
                let groups = try self.timezoneGroupsFromResponse(response)
                success(groups)
            } catch {
                failure(error)
            }
        }) { (error, _) in
            failure(error)
        }
    }
}

private extension TimeZoneServiceRemote {
    func timezoneGroupsFromResponse(_ response: AnyObject) throws -> [TimeZoneGroup] {
        guard let response = response as? [String: Any],
            let timeZonesByContinent = response["timezones_by_continent"] as? [String: [[String: String]]],
            let manualUTCOffsets = response["manual_utc_offsets"] as? [[String: String]] else {
                throw ResponseError.decodingFailed
        }
        let continentGroups: [TimeZoneGroup] = try timeZonesByContinent.map({
            let (groupName, rawZones) = $0
            let zones = try rawZones.map({ try parseNamedTimezone(response: $0) })
            return TimeZoneGroup(name: groupName, timezones: zones)
        }).sorted(by: { return $0.name < $1.name })

        let utcOffsets: [WPTimeZone] = try manualUTCOffsets.map({ try parseOffsetTimezone(response: $0) })
        let utcOffsetsGroup = TimeZoneGroup(
            name: NSLocalizedString("Manual Offsets", comment: "Section name for manual offsets in time zone selector"),
            timezones: utcOffsets)
        return continentGroups + [utcOffsetsGroup]
    }

    func parseNamedTimezone(response: [String: String]) throws -> WPTimeZone {
        guard let label = response["label"],
            let value = response["value"] else {
                throw ResponseError.decodingFailed
        }
        return NamedTimeZone(label: label, value: value)
    }

    func parseOffsetTimezone(response: [String: String]) throws -> WPTimeZone {
        guard let value = response["value"],
            let zone = OffsetTimeZone.fromValue(value) else {
                throw ResponseError.decodingFailed
        }
        return zone
    }
}
