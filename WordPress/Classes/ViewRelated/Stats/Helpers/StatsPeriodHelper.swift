import Foundation

class StatsPeriodHelper {
    private lazy var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .autoupdatingCurrent
        return cal
    }()

    func dateAvailableBeforeDate(_ dateIn: Date, period: StatsPeriodUnit, backLimit: Int, mostRecentDate: Date? = nil) -> Bool {
        // Use dates without time
        let currentDate =  mostRecentDate?.normalizedDate() ?? StatsDataHelper.currentDateForSite().normalizedForSite()

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

    func dateAvailableAfterDate(_ dateIn: Date, period: StatsPeriodUnit, mostRecentDate: Date? = nil) -> Bool {
        // Use dates without time
        let currentDate =  mostRecentDate?.normalizedDate() ?? StatsDataHelper.currentDateForSite().normalizedForSite()
        let date = dateIn.normalizedDate()

        switch period {
        case .day:
            return date < currentDate.normalizedDate()
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

    func endDate(from intervalStartDate: Date, period: StatsPeriodUnit, offsetBy count: Int = 1) -> Date {
        switch period {
        case .day:
            return intervalStartDate.normalizedDate()
        case .week:
            guard let week = weekIncludingDate(intervalStartDate) else {
                DDLogError("[Stats] Couldn't determine the right week. Returning original value.")
                return intervalStartDate.normalizedDate()
            }
            return week.weekEnd.normalizedDate()
        case .month:
            guard let endDate = intervalStartDate.lastDayOfTheMonth(in: calendar) else {
                DDLogError("[Stats] Couldn't determine number of days in a given month in Stats. Returning original value.")
                return intervalStartDate.normalizedDate()
            }
            return endDate.normalizedDate()
        case .year:
            guard let endDate = intervalStartDate.lastDayOfTheYear(in: calendar) else {
                DDLogError("[Stats] Couldn't determine number of months in a given year, or days in a given monthin Stats. Returning original value.")
                return intervalStartDate.normalizedDate()
            }
            return endDate.normalizedDate()
        }
    }

    func calculateEndDate(from currentDate: Date, offsetBy count: Int = 1, unit: StatsPeriodUnit) -> Date? {
        let calendar = Calendar.autoupdatingCurrent

        guard let adjustedDate = calendar.date(byAdding: unit.calendarComponent, value: count, to: currentDate) else {
            DDLogError("[Stats] Couldn't do basic math on Calendars in Stats. Returning original value.")
            return currentDate
        }

        switch unit {
        case .day:
            return adjustedDate.normalizedDate()

        case .week:

            // The hours component here is because the `dateInterval` returned by Calendar is a closed range
            // — so the "end" of a specific week is also simultenously a 'start' of the next one.
            // This causes problem when calling this math on dates that _already are_ an end/start of a week.
            // This doesn't work for our calculations, so we force it to rollover using this hack.
            // (I *think* that's what's happening here. Doing Calendar math on this method has broken my brain.
            // I spend like 10h on this ~50 LoC method. Beware.)
            let components = DateComponents(day: 7 * count, hour: -12)

            guard let weekAdjusted = calendar.date(byAdding: components, to: currentDate.normalizedDate()) else {
                DDLogError("[Stats] Couldn't add a multiple of 7 days and -12 hours to a date in Stats. Returning original value.")
                return currentDate
            }
            return calendar.dateInterval(of: .weekOfYear, for: weekAdjusted)?.end.normalizedDate()

        case .month:
            guard let endDate = adjustedDate.lastDayOfTheMonth(in: calendar) else {
                DDLogError("[Stats] Couldn't determine number of days in a given month in Stats. Returning original value.")
                return currentDate
            }
            return endDate.normalizedDate()

        case .year:
            guard let endDate = adjustedDate.lastDayOfTheYear(in: calendar) else {
                DDLogError("[Stats] Couldn't determine number of months in a given year, or days in a given monthin Stats. Returning original value.")
                return currentDate
            }
            return endDate.normalizedDate()
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

private extension Date {
    func adjusted(for period: StatsPeriodUnit, in calendar: Calendar, value: Int) -> Date {
        guard let adjustedDate = calendar.date(byAdding: period.calendarComponent, value: value, to: self) else {
            DDLogError("[Stats] Couldn't do basic math on Calendars in Stats. Returning original value.")
            return self
        }
        return adjustedDate
    }

    func lastDayOfTheWeek(in calendar: Calendar, with offset: Int) -> Date? {
        // The hours component here is because the `dateInterval` returnd by Calendar is a closed range
        // — so the "end" of a specific week is also simultenously a 'start' of the next one.
        // This causes problem when calling this math on dates that _already are_ an end/start of a week.
        // This doesn't work for our calculations, so we force it to rollover using this hack.
        // (I *think* that's what's happening here. Doing Calendar math on this method has broken my brain.
        // I spend like 10h on this ~50 LoC method. Beware.)
        let components = DateComponents(day: 7 * offset, hour: -12)

        guard let weekAdjusted = calendar.date(byAdding: components, to: normalizedDate()),
        let endOfAdjustedWeek = calendar.dateInterval(of: .weekOfYear, for: weekAdjusted)?.end else {
            DDLogError("[Stats] Couldn't add a multiple of 7 days and -12 hours to a date in Stats. Returning original value.")
            return nil
        }
        return endOfAdjustedWeek
    }

    func lastDayOfTheMonth(in calendar: Calendar) -> Date? {
        guard let maxComponent = calendar.range(of: .day, in: .month, for: self)?.max() else {
            DDLogError("[Stats] Couldn't determine number of days in a given month in Stats. Returning original value.")
            return nil
        }
        return calendar.date(bySetting: .day, value: maxComponent, of: self)?.normalizedDate()
    }

    func lastDayOfTheYear(in calendar: Calendar) -> Date? {
        guard
            let maxMonth = calendar.range(of: .month, in: .year, for: self)?.max(),
            let adjustedMonthDate = calendar.date(bySetting: .month, value: maxMonth, of: self),
            let maxDay = calendar.range(of: .day, in: .month, for: adjustedMonthDate)?.max() else {
                DDLogError("[Stats] Couldn't determine number of months in a given year, or days in a given monthin Stats. Returning original value.")
                return nil
        }
        let adjustedDayDate = calendar.date(bySetting: .day, value: maxDay, of: adjustedMonthDate)
        return adjustedDayDate?.normalizedDate()
    }
}
