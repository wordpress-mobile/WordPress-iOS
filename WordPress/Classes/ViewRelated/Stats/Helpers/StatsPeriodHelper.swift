import Foundation

class StatsPeriodHelper {
    private lazy var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    func dateAvailableBeforeDate(_ dateIn: Date, period: StatsPeriodUnit, backLimit: Int) -> Bool {
        // Use dates without time
        let currentDate = Date().normalizedDate()

        guard var oldestDate = calendar.date(byAdding: period.calendarComponent, value: backLimit, to: currentDate) else {
            return false
        }

        let date = dateIn.normalizedDate()
        oldestDate = oldestDate.normalizedDate()

        switch period {
        case .day:
            return date > oldestDate
        case .week:
            let week = weekIncludingDate(date)
            guard let weekStart = week?.weekStart,
                let oldestWeekStart = weekIncludingDate(oldestDate)?.weekStart else {
                    return false
            }
            return weekStart > oldestWeekStart
        case .month:
            guard let month = monthFromDate(date),
                let oldestMonth = monthFromDate(oldestDate) else {
                    return false
            }
            return month > oldestMonth
        case .year:
            let year = yearFromDate(date)
            return year > yearFromDate(oldestDate)
        }
    }

    func dateAvailableAfterDate(_ dateIn: Date, period: StatsPeriodUnit) -> Bool {
        // Use dates without time
        let currentDate = Date().normalizedDate()
        let date = dateIn.normalizedDate()

        switch period {
        case .day:
            return date < currentDate
        case .week:
            let week = weekIncludingDate(date)
            guard let weekEnd = week?.weekEnd,
                let currentWeekEnd = weekIncludingDate(currentDate)?.weekEnd else {
                    return false
            }
            return weekEnd < currentWeekEnd
        case .month:
            guard let month = monthFromDate(date),
                let currentMonth = monthFromDate(currentDate) else {
                    return false
            }
            return month < currentMonth
        case .year:
            let year = yearFromDate(date)
            return year < yearFromDate(currentDate)
        }
    }

    func endDate(from startDate: Date, period: StatsPeriodUnit) -> Date {
        switch period {
        case .day:
            return startDate.normalizedDate()
        case .week:
            guard let week = weekIncludingDate(startDate) else {
                DDLogError("[Stats] Couldn't determine the right week. Returning original value.")
                return startDate.normalizedDate()
            }
            return week.weekEnd.normalizedDate()
        case .month:
            guard let maxComponent = calendar.range(of: .day, in: .month, for: startDate)?.max(),
                let endDate = calendar.date(bySetting: .day, value: maxComponent, of: startDate) else {
                DDLogError("[Stats] Couldn't determine number of days in a given month in Stats. Returning original value.")
                return startDate.normalizedDate()
            }
            return endDate.normalizedDate()
        case .year:
            // From a start date 2017-12-31 23:00:00 +0000 the end date must be 2018-12-30 23:00:00 +0000.
            // Because the final formatted range will be 2018-01-01 and 2018-12-31.

            let daysToAdd = -1
            let yearsToAdd = 1

            var dateComponent = DateComponents()
            dateComponent.day = daysToAdd
            dateComponent.year = yearsToAdd

            guard let endDate = calendar.date(byAdding: dateComponent, to: startDate) else {
                DDLogError("[Stats] Couldn't determine the right year. Returning original value.")
                return startDate.normalizedDate()
            }
            return endDate.normalizedDate()
        }
    }

    func calculateEndDate(startDate: Date, offsetBy count: Int = 1, unit: StatsPeriodUnit) -> Date? {
        let calendar = Calendar.autoupdatingCurrent

        guard let adjustedDate = calendar.date(byAdding: unit.calendarComponent, value: count, to: startDate) else {
            DDLogError("[Stats] Couldn't do basic math on Calendars in Stats. Returning original value.")
            return startDate
        }

        switch unit {
        case .day:
            return adjustedDate.normalizedDate()

        case .week:

            // The hours component here is because the `dateInterval` returnd by Calendar is a closed range
            // — so the "end" of a specific week is also simultenously a 'start' of the next one.
            // This causes problem when calling this math on dates that _already are_ an end/start of a week.
            // This doesn't work for our calculations, so we force it to rollover using this hack.
            // (I *think* that's what's happening here. Doing Calendar math on this method has broken my brain.
            // I spend like 10h on this ~50 LoC method. Beware.)
            let components = DateComponents(day: 7 * count, hour: -12)

            guard let weekAdjusted = calendar.date(byAdding: components, to: startDate.normalizedDate()) else {
                DDLogError("[Stats] Couldn't add a multiple of 7 days and -12 hours to a date in Stats. Returning original value.")
                return startDate
            }

            let endOfAdjustedWeek = calendar.dateInterval(of: .weekOfYear, for: weekAdjusted)?.end

            return endOfAdjustedWeek?.normalizedDate()

        case .month:
            guard let maxComponent = calendar.range(of: .day, in: .month, for: adjustedDate)?.max() else {
                DDLogError("[Stats] Couldn't determine number of days in a given month in Stats. Returning original value.")
                return startDate
            }

            return calendar.date(bySetting: .day, value: maxComponent, of: adjustedDate)?.normalizedDate()

        case .year:
            guard
                let maxMonth = calendar.range(of: .month, in: .year, for: adjustedDate)?.max(),
                let adjustedMonthDate = calendar.date(bySetting: .month, value: maxMonth, of: adjustedDate),
                let maxDay = calendar.range(of: .day, in: .month, for: adjustedMonthDate)?.max() else {
                    DDLogError("[Stats] Couldn't determine number of months in a given year, or days in a given monthin Stats. Returning original value.")
                    return startDate
            }
            let adjustedDayDate = calendar.date(bySetting: .day, value: maxDay, of: adjustedMonthDate)

            return adjustedDayDate?.normalizedDate()
        }
    }

    // MARK: - Date Helpers

    func weekIncludingDate(_ date: Date) -> (weekStart: Date, weekEnd: Date)? {
        // Note: Week is Monday - Sunday

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return nil
        }

        return (weekStart, weekEnd)
    }

    func monthFromDate(_ date: Date) -> Date? {
        let dateComponents = calendar.dateComponents([.month, .year], from: date)
        return calendar.date(from: dateComponents)
    }

    func yearFromDate(_ date: Date) -> Int {
        return calendar.component(.year, from: date)
    }
}
