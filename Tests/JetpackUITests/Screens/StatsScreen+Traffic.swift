import XCTest

/// The Traffic tab: the Today card, the chart card, the top list cards and the date controls.
extension StatsScreen {
    /// What a top list card lists. A card's menu switches it between these.
    enum DataType: String, CaseIterable {
        case authors
        case videos
        case archive
        case referrers
        case searchTerms
        case utm
        case locations
        case devices
        case externalLinks
        case fileDownloads
        case postsAndPages

        var title: String {
            switch self {
            case .authors: "Authors"
            case .videos: "Videos"
            case .archive: "Archive"
            case .referrers: "Referrers"
            case .searchTerms: "Search Terms"
            case .utm: "UTM"
            case .locations: "Locations"
            case .devices: "Devices"
            case .externalLinks: "Clicks"
            case .fileDownloads: "File Downloads"
            case .postsAndPages: "Posts & Pages"
            }
        }
    }

    enum Metric: String, CaseIterable {
        case visitors, likes, comments, posts, views
    }

    enum LocationLevel: String, CaseIterable {
        case regions = "Regions"
        case cities = "Cities"
        case countries = "Countries"
    }

    // MARK: - Elements

    var todayCard: XCUIElement { app.buttons["today_card"] }
    var chartCard: XCUIElement { app.otherElements["chart_card"] }
    var addCardButton: XCUIElement { app.buttons["stats_add_card_button"] }
    var dateRangeButton: XCUIElement { app.buttons["stats_date_range_button"] }
    var dateBackwardButton: XCUIElement { app.buttons["stats_date_range_backward_button"] }
    var dateForwardButton: XCUIElement { app.buttons["stats_date_range_forward_button"] }

    /// The first top list card's title, which reads "<data type> card".
    var firstTopListCardTitle: XCUIElement {
        app.buttons.matching(identifier: "top_list_card_title").firstMatch
    }

    private var locationLevelButton: XCUIElement { app.buttons["top_list_card_location_level_button"] }

    /// The first card listing `dataType`.
    private func card(_ dataType: DataType) -> XCUIElement {
        app.otherElements.matching(identifier: "top_list_card_\(dataType.rawValue)").firstMatch
    }

    // MARK: - Today Card

    /// Narrows the date range to today.
    @discardableResult
    func tapTodayCard() throws -> Self {
        try scrollAndTap(todayCard)
        return self
    }

    func openTodayCardMenu() throws -> MenuComponent {
        try scrollAndTap(app.buttons["today_card_more_button"])
        return try MenuComponent(expecting: "Delete Card", app: app)
    }

    // MARK: - Chart Card

    @discardableResult
    func select(_ metric: Metric) throws -> Self {
        try select(tab: app.buttons["chart_card_metric_\(metric.rawValue)"])
        return self
    }

    func openChartCardMenu() throws -> MenuComponent {
        try scrollAndTap(app.buttons["chart_card_more_button"])
        return try MenuComponent(expecting: "Show Data", app: app)
    }

    func goToChartData() throws -> ChartDataScreen {
        try openChartCardMenu().select("Show Data")
        return try ChartDataScreen(app: app)
    }

    func goToChartCardCustomization() throws -> StatsCardCustomizationScreen {
        try openChartCardMenu().select("Edit Card")
        return try StatsCardCustomizationScreen(title: "Select Metrics", app: app)
    }

    // MARK: - Top List Cards

    func openMenu(ofCardListing dataType: DataType) throws -> MenuComponent {
        try scrollAndTap(card(dataType).buttons["top_list_card_more_button"])
        return try MenuComponent(expecting: "Edit Card", app: app)
    }

    func goToCustomization(ofCardListing dataType: DataType) throws -> StatsCardCustomizationScreen {
        try openMenu(ofCardListing: dataType).select("Edit Card")
        return try StatsCardCustomizationScreen(title: "Select Data Type", app: app)
    }

    func openDataTypeMenu(ofCardListing dataType: DataType) throws -> MenuComponent {
        try scrollAndTap(card(dataType).buttons["top_list_card_title"])
        return try MenuComponent(expecting: DataType.fileDownloads.title, app: app)
    }

    /// Switches the card listing `current` to list `dataType` instead.
    @discardableResult
    func switchCard(listing current: DataType, to dataType: DataType) throws -> Self {
        try openDataTypeMenu(ofCardListing: current).select(dataType.title)
        return self
    }

    func goToAllItems(ofCardListing dataType: DataType) throws -> StatsDetailsScreen {
        try scrollAndTap(card(dataType).buttons["top_list_card_show_all_button"])
        return try StatsDetailsScreen(title: dataType.title, app: app)
    }

    /// Opens the stats for the first item in a card. Only some data types have item stats, and a
    /// card only lists items that have stats in the date range.
    func goToFirstItem(ofCardListing dataType: DataType, titled title: String) throws -> StatsDetailsScreen {
        let item = card(dataType).buttons.matching(identifier: "top_list_item").firstMatch
        try scroll(
            to: card(dataType).buttons["top_list_card_title"],
            in: content,
            maxSwipes: Self.maxSwipes,
            waitsForExistence: false
        )
        guard item.pollForExistence(timeout: Self.defaultWaitTimeout) else {
            throw XCTSkip("This site has no \(dataType.title) stats in the date range")
        }
        try scrollAndTap(item)
        return try StatsDetailsScreen(title: title, app: app)
    }

    func openLocationLevelMenu() throws -> MenuComponent {
        try scrollAndTap(locationLevelButton)
        return try MenuComponent(expecting: LocationLevel.cities.rawValue, app: app)
    }

    @discardableResult
    func select(_ level: LocationLevel) throws -> Self {
        try openLocationLevelMenu().select(level.rawValue)
        try wait(until: "the locations card listing \(level.rawValue)") {
            locationLevelButton.label.hasPrefix(level.rawValue)
        }
        return self
    }

    // MARK: - Adding Cards and the Time Zone

    func openAddCardMenu() throws -> MenuComponent {
        try scrollAndTap(addCardButton)
        return try MenuComponent(expecting: "Top List, See your top performing content", app: app)
    }

    /// Opens the popover explaining which time zone the stats are in.
    @discardableResult
    func openTimeZoneInfo() throws -> Self {
        try scrollAndTap(app.buttons["stats_timezone_button"])
        try waitFor(app.staticTexts["Site Time Zone"])
        return self
    }

    // MARK: - Date Range

    func openDateRangeMenu() throws -> MenuComponent {
        try tap(dateRangeButton)
        return try MenuComponent(expecting: "Custom Range…", app: app)
    }

    func goToCustomDateRange() throws -> CustomDateRangeScreen {
        try openDateRangeMenu().select("Custom Range…")
        return try CustomDateRangeScreen(app: app)
    }
}
