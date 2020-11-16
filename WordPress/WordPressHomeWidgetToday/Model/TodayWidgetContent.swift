import WidgetKit


struct TodayWidgetContent: TimelineEntry {
    let date: Date
    let siteTitle: String
    let stats: TodayWidgetStats
}
