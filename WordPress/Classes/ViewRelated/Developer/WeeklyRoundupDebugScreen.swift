import BackgroundTasks
import SwiftUI

struct BlueButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ?  Color.white : Color(red: 0.5, green: 0.5, blue: 0.8))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct WeeklyRoundupDebugScreen: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode

    var body: some View {
        //NavigationView {
            VStack(alignment: .center) {
                HStack {
                    Spacer()

                    Button("Schedule immediately") {
                        self.scheduleImmediately()
                    }
                    .buttonStyle(BlueButton())
                    .frame(width: 350)

                    Spacer()
                }

                Spacer()
                    .frame(height: 16)

                HStack {
                    Spacer()

                    Button("Schedule in 10 sec / 5 min") {
                        self.scheduleDelayed(taskRunDelay: 10, staticNotificationDelay: 5 * 60)
                    }
                    .buttonStyle(BlueButton())
                    .frame(width: 350)

                    Spacer()
                }

                Spacer()
                    .frame(height: 16)

                HStack {
                    Spacer()

                    Button("Schedule in 10 sec / 30 min") {
                        self.scheduleDelayed(taskRunDelay: 10, staticNotificationDelay: 30 * 60)
                    }
                    .buttonStyle(BlueButton())
                    .frame(width: 350)

                    Spacer()
                }

                Spacer()
                    .frame(height: 16)

                HStack {
                    Spacer()

                    Button("Schedule in 10 sec / 60 min") {
                        self.scheduleDelayed(taskRunDelay: 10, staticNotificationDelay: 60 * 60)
                    }
                    .buttonStyle(BlueButton())
                    .frame(width: 350)

                    Spacer()
                }

                Spacer()
                    .frame(height: 16)

                Text("The first number is when the dynamic notification is scheduled at the earliest.  It can take a lot more time to be sent since iOS basically decides when to deliver it.  The second number is for the static notification.  It will be shown if either the App is killed or if the dynamic notification isn't shown by iOS before it.")
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        //}
        .navigationBarTitle("Weekly Roundup", displayMode: .inline)
    }

    func scheduleImmediately() {
        InteractiveNotificationsManager.shared.requestAuthorization { authorized in
            if authorized {
                typealias LaunchTaskWithIdentifier = @convention(c) (NSObject, Selector, NSString) -> Void

                let selector = Selector(("_simulateLaunchForTaskWithIdentifier:"))
                let methodImp = BGTaskScheduler.shared.method(for: selector)
                let method = unsafeBitCast(methodImp, to: LaunchTaskWithIdentifier.self)

                method(BGTaskScheduler.shared, selector, WeeklyRoundupBackgroundTask.identifier as NSString)
            }
        }
    }

    func scheduleDelayed(taskRunDelay: TimeInterval, staticNotificationDelay: TimeInterval) {
        InteractiveNotificationsManager.shared.requestAuthorization { authorized in
            if authorized {
                DispatchQueue.main.async {
                    let taskRunDate = Date(timeIntervalSinceNow: taskRunDelay)
                    let staticNotificationDate = Date(timeIntervalSinceNow: staticNotificationDelay)
                    let calendar = Calendar.current

                    let runDateComponents = calendar.dateComponents([.hour, .minute, .second], from: taskRunDate)
                    let staticNotificationDateComponents = calendar.dateComponents([.hour, .minute, .second], from: staticNotificationDate)

                    let backgroundTask = WeeklyRoundupBackgroundTask(
                        runDateComponents: runDateComponents,
                        staticNotificationDateComponents: staticNotificationDateComponents)

                    WordPressAppDelegate.shared?.backgroundTasksCoordinator.schedule(backgroundTask) { _ in
                    }
                }
            }
        }
    }
}

struct WeeklyRoundupDebugScreen_Preview: PreviewProvider {
    static var previews: some View {
        StoreSandboxSecretScreen(cookieJar: HTTPCookieStorage.shared)
    }
}
