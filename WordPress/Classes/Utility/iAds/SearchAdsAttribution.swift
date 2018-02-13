/// Implementation of Search Ads attribution detail
/// More info: https://searchads.apple.com/help/measure-results/#attribution-api

import Foundation
import iAd
import AutomatticTracks

@objc final class SearchAdsAttribution: NSObject {

    /// Keep the instance alive
    ///
    private static var lifeToken: SearchAdsAttribution?

    private static let userDefaultsSentKey = "search_ads_attribution_details_sent"
    private static let userDefaultsLimitedAdTrackingKey = "search_ads_limited_tracking"

    private var isTrackingLimited: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SearchAdsAttribution.userDefaultsLimitedAdTrackingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SearchAdsAttribution.userDefaultsLimitedAdTrackingKey)
        }
    }

    private var isAttributionDetailsSent: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SearchAdsAttribution.userDefaultsSentKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SearchAdsAttribution.userDefaultsSentKey)
        }
    }

    #if (arch(i386) || arch(x86_64)) && os(iOS)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif


    override init() {
        super.init()
        SearchAdsAttribution.lifeToken = self
    }

    @objc func requestDetails() {
        guard
            isSimulator == false, // don't request in simulator
            isTrackingLimited == false,
            isAttributionDetailsSent == false
        else {
            finish()
            return
        }

        requestAttributionDetails()
    }

    private func requestAttributionDetails() {
        ADClient.shared().requestAttributionDetails { [weak self] (attributionDetails, error) in
            if let error = error as NSError? {
                self?.didReceiveError(error)
            } else {
                self?.didReceiveAttributionDetails(attributionDetails)
            }
        }
    }

    private func didReceiveError(_ error: Error) {
        let nsError = error as NSError

        switch ADClientError.Code(rawValue: nsError.code) {
        case .limitAdTracking?: // Not possible to get data
            isTrackingLimited = true
            finish()
        default: // Possible connectivity issues
            self.tryAgain(after: 5)
        }
    }

    private func tryAgain(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.requestDetails()
        }
    }

    private func didReceiveAttributionDetails(_ details: [String: NSObject]?) {
        defer {
            finish()
        }
        guard
            let version = details,
            let details = version["Version3.1"] as? [String: Any]
        else { return }

        // Search Ads Attribution API returns testing data when it's not called from a distribution build.
        // So we won't send that testing data to Tracks

        if BuildConfiguration.current == .appStore {
            WPAnalytics.track(WPAnalyticsStat.searchAdsAttribution, withProperties: details)
            isAttributionDetailsSent = true
        } else {
            DDLogInfo("SearchAdsAttribution: Data will be send to Tracks from AppStore build")
        }
    }

    /// Free this instance after all work is done.
    ///
    private func finish() {
        SearchAdsAttribution.lifeToken = nil
    }
}
