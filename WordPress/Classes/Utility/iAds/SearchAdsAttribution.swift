
import Foundation
import iAd
import AutomatticTracks

@objc final class SearchAdsAttribution: NSObject {

    let dateFormat = "yyyy-MM-dd hh:mm:ssSSS" // Use your own
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }

    func requestDetails() {
        ADClient.shared().requestAttributionDetails { [weak self] (attributionDetails, error) in
            if let error = error {
                DDLogError(String(describing: error))
                self?.didReceiveError(error)
            } else {
                self?.didReceiveAttributionDetails(attributionDetails)
            }
        }
    }

    func didReceiveError(_ error: Error) {
        let nsError = error as NSError
        let adError = ADClientError(_nsError: nsError)
        switch adError.code {
        case .unknown:
            print("Unknown error")
        case .limitAdTracking:
            print("Limited ad tracking error")
        }
    }

//  {
//    “Version3.1” = {
//      “iad-attribution” = true;
//      “iad-org-name” = “Light Right”;
//      “iad-campaign-id” = 15292426;
//      “iad-campaign-name” = “Light Bright Launch”;
//      “iad-conversion-date” = “2016-06-14T17:18:07Z”;
//      “iad-click-date” = “2016-06-14T17:17:00Z”;
//      “iad-adgroup-id” = 15307675;
//      “iad-adgroup-name” = “LightRight Launch Group”;
//      “iad-keyword” = “light right”;
//    };
//  }

    func didReceiveAttributionDetails(_ details: [String: NSObject]?) {
        guard
            let version = details,
            let details = version["Version3.1"] as? [String: Any]
        else { return }

        postAttributionDetails(details)
    }

    func postAttributionDetails(_ details: [String: Any]) {
        print(details)
        WPAnalytics.track(WPAnalyticsStat.searchAdsAttribution, withProperties: details)
    }
}
