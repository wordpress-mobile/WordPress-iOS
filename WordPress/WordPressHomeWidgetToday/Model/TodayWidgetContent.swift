import WidgetKit


struct TodayWidgetContent: TimelineEntry {
    var date = Date()
    var siteTitle: String
    var views: Int
    var visitors: Int
    var likes: Int
    var comments: Int
}
