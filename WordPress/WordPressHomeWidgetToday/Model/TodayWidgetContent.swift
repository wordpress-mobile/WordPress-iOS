import WidgetKit


struct TodayWidgetContent: TimelineEntry {
    var date = Date()
    // TODO - TODAYWIDGET: see if this needs to be LocalizedStringKey
    var siteTitle: String
    var views: Int
    var visitors: Int
    var likes: Int
    var comments: Int
}
