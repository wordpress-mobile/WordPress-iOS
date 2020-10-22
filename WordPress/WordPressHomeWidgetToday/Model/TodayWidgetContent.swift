import WidgetKit


struct TodayWidgetContent: TimelineEntry {
    let date = Date()
    let siteTitle: String
    let views: Int
    let visitors: Int
    let likes: Int
    let comments: Int
}
