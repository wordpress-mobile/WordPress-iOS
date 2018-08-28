
protocol AppRatingUtilityType {
    func incrementSignificantEvent(section: String)
}

extension AppRatingUtility: AppRatingUtilityType { }
