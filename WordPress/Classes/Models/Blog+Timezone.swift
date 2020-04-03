import Foundation

extension Blog {
    @objc var timeZone: NSTimeZone {
        let timeZoneName: String? = getOption(name: "timezone")
        let gmtOffSet: NSNumber? = getOption(name: "gmt_offset")
        let optionValue: NSString? = getOption(name: "time_zone")
        let oneHourInSeconds: Float = 60 * 60

        var timeZone: NSTimeZone!

        if let timeZoneName = timeZoneName, !timeZoneName.isEmpty {
            timeZone = NSTimeZone(name: timeZoneName)
        } else if let gmtOffSet = gmtOffSet?.floatValue {
            timeZone = NSTimeZone(forSecondsFromGMT: Int(gmtOffSet * oneHourInSeconds))
        } else if let optionValue = optionValue {
            let timeZoneOffsetSeconds = Int(optionValue.floatValue * oneHourInSeconds)
            timeZone = NSTimeZone(forSecondsFromGMT: timeZoneOffsetSeconds)
        }

        if timeZone == nil {
            timeZone = NSTimeZone(forSecondsFromGMT: 0)
        }

        return timeZone
    }
}
