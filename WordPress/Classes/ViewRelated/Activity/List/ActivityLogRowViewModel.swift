import Foundation
import SwiftUI
import UIKit
import WordPressKit
import WordPressUI
import FormattableContentKit

struct ActivityLogRowViewModel: Identifiable {
    let id: String
    let actorAvatarURL: URL?
    var actor: String?
    var actorRole: String?
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
        self.actorAvatarURL = activity.actor.flatMap { URL(string: $0.avatarURL) }
        if let actor = activity.actor {
            self.actor = actor.displayName
            if !actor.role.isEmpty {
                self.actorRole = actor.role.localizedCapitalized
            }
        }
        self.date = activity.published
        self.time = activity.published.formatted(date: .omitted, time: .shortened)
        self.title = activity.text
        self.subtitle = activity.summary.localizedCapitalized

        self.icon = activity.icon
        self.tintColor = Color(activity.statusColor)
    }
}
