//
//  PostItineraryDateViewModel.swift
//  BeauVoyage
//
//  Created by Lukasz Koszentka on 7/29/20.
//  Copyright © 2020 BeauVoyage. All rights reserved.
//

import Foundation

@objc protocol PostItineraryDateViewModelDelegate: AnyObject {
    func startDateChanged(date: String)
    func endDateChanged(date: String)
}

@objc protocol PostItineraryDateViewModel: AnyObject {
    var delegate: PostItineraryDateViewModelDelegate? { get set }
    var post: Post { get }
    var title: String { get }
    var allDayTitle: String { get }
    var saveButtonTitle: String { get }
    var startDatePlaceholder: String { get }
    var endDatePlaceholder: String { get }

    func changeStartDate(date: Date)
    func changeEndDate(date: Date)
}

final class PostItineraryDateViewModelImpl: NSObject, PostItineraryDateViewModel {

    weak var delegate: PostItineraryDateViewModelDelegate?

    var title: String { return NSLocalizedString("Date Time", comment: "") }
    var allDayTitle: String { return NSLocalizedString("All day", comment: "") }
    var saveButtonTitle: String { return NSLocalizedString("Save", comment: "") }
    var startDatePlaceholder: String { return NSLocalizedString("Start date", comment: "") }
    var endDatePlaceholder: String { return NSLocalizedString("End date", comment: "") }

    private var isAllDay: Bool = false

    private var startDate = Date() {
        didSet {
            let dateString = localDateFormatter.string(from: startDate)
            delegate?.startDateChanged(date: dateString)
            post.eventStartDate = dateString
            let utcDateString = utcDateFormatter.string(from: startDate)
            post.eventStartDateUTC = utcDateString

        }
    }
    private var endDate = Date() {
        didSet {
            let dateString = localDateFormatter.string(from: endDate)
            delegate?.endDateChanged(date: dateString)
            post.eventEndDate = dateString
            let utcDateString = utcDateFormatter.string(from: endDate)
            post.eventEndDateUTC = utcDateString
        }
    }

    private lazy var localDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private lazy var utcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    let post: Post

    @objc public init(post: Post) {
        self.post = post
        super.init()
        post.eventShowMap = "1"
        post.eventShowMapLink = "1"
        post.eventAllDay = ""
        post.eventTimezone = TimeZone.current.abbreviation()
    }

    func changeStartDate(date: Date) {
        startDate = date
    }

    func changeEndDate(date: Date) {
        endDate = date
    }
    
}
