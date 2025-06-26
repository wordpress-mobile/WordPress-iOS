import SwiftUI
import WordPressKit

struct DashboardActivityLogListView: View {
    let activities: [Activity]
    let onActivityTap: (Activity) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities, id: \.activityID) { activity in
                Button(action: {
                    onActivityTap(activity)
                }) {
                    ActivityLogRowView(viewModel: ActivityLogRowViewModel(activity: activity))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())

                if activity != activities.last {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
    }
}
