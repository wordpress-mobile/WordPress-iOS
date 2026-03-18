import Foundation
import SwiftUI
import UIKit
import WordPressKit
import WordPressUI
import FormattableContentKit

struct ActivityLogRowViewModel: Identifiable {
    let id: String
    let actorSubtitle: String?
    let actorMetadata: String?
    let title: String
    let subtitle: String
    let date: Date
    let time: String
    let icon: UIImage?
    let tintColor: Color
    let activity: Activity

    init(activity: Activity) {
        self.activity = activity
        self.id = activity.activityID

        if let actor = activity.actor {
            actorSubtitle = actor.role.isEmpty ? nil : actor.role.localizedCapitalized
            actorMetadata = ActivityStringFormatting.botName(for: actor)
        } else {
            actorSubtitle = nil
            actorMetadata = nil
        }

        self.date = activity.published
        self.time = activity.published.formatted(date: .omitted, time: .shortened)
        self.title = activity.summary.localizedCapitalized
        self.subtitle = activity.text

        self.icon = activity.icon
        self.tintColor = Color(activity.statusColor)
    }
}
