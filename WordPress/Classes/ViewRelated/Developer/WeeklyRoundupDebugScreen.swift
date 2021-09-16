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

    class Settings {
        private let weeklyRoundupEnabledForA8cP2sKey = "weekly_roundup.debug.enabled_for_a8c_p2s"

        let defaultPadding = CGFloat(16)
        let spacerHeight = CGFloat(16)

        var isEnabledForA8cP2s: Bool {
            get {
                (UserDefaults.standard.value(forKey: weeklyRoundupEnabledForA8cP2sKey) as? Bool) ?? false
            }

            set {
                UserDefaults.standard.setValue(newValue, forKey: weeklyRoundupEnabledForA8cP2sKey)
            }
        }
    }

    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @State private var scheduledDate: Date? = nil
    @State private var running: Bool = false
    @State private var errorScheduling: Bool = false
    private let settings = Settings()

    var body: some View {
        VStack(alignment: .center) {
            if errorScheduling {
                Group {
                    Text("Error scheduling Weekly Roundup!")
                        .foregroundColor(.red)
                }

                Spacer()
                    .frame(height: 16)
            }

            Group {
                Toggle("Include A8c P2s", isOn: Binding(get: {
                    settings.isEnabledForA8cP2s
                }, set: { isOn in
                    settings.isEnabledForA8cP2s = isOn
                }))
                .padding()


                Spacer()
                    .frame(height: 16)
            }

            Group {
                scheduleDetailsView()

                Spacer()
                    .frame(height: 16)
            }

            Group {
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
                    .frame(height: settings.spacerHeight)

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
                    .frame(height: settings.spacerHeight)

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
                    .frame(height: settings.spacerHeight)

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
                    .frame(height: settings.spacerHeight)
            }

            Text("The first number is when the dynamic notification is scheduled at the earliest.  It can take a lot more time to be sent since iOS basically decides when to deliver it.  The second number is for the static notification.  It will be shown if either the App is killed or if the dynamic notification isn't shown by iOS before it.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(settings.defaultPadding)

            Spacer()
        }
        .navigationBarTitle("Weekly Roundup", displayMode: .inline)
        .onAppear {
            self.updateBackgroundTaskDate()
        }
    }

    func updateBackgroundTaskDate() {
        DispatchQueue.main.async {
            WordPressAppDelegate.shared?.backgroundTasksCoordinator.getScheduledExecutionDate(taskIdentifier: WeeklyRoundupBackgroundTask.identifier, completion: { date in

                self.scheduledDate = date
            })
        }
    }

    func scheduleDetailsView() -> some View {
        guard !running else {
            return AnyView(Text("Running..."))
        }

        if let scheduledDate = self.scheduledDate {
            return AnyView(HStack {
                Text("Earliest begin date:")
                Spacer()
                Text("\(scheduledDate.shortStringWithTime())")
            })
        } else {
            return AnyView(HStack {
                Text("Not scheduled.")
            })
        }
    }

    func scheduleImmediately() {
        running = true

        InteractiveNotificationsManager.shared.requestAuthorization { authorized in
            guard authorized else {
                self.running = false
                return
            }

            typealias LaunchTaskWithIdentifier = @convention(c) (NSObject, Selector, NSString) -> Void

            let selector = Selector(("_simulateLaunchForTaskWithIdentifier:"))
            let methodImp = BGTaskScheduler.shared.method(for: selector)
            let method = unsafeBitCast(methodImp, to: LaunchTaskWithIdentifier.self)

            method(BGTaskScheduler.shared, selector, WeeklyRoundupBackgroundTask.identifier as NSString)

            self.errorScheduling = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.updateBackgroundTaskDate()
                self.running = false
            }
        }
    }

    func scheduleDelayed(taskRunDelay: TimeInterval, staticNotificationDelay: TimeInterval) {
        updateBackgroundTaskDate()

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

                    WordPressAppDelegate.shared?.backgroundTasksCoordinator.schedule(backgroundTask) { result in
                        switch result {
                        case .success:
                            errorScheduling = false
                        case .failure:
                            errorScheduling = true
                        }

                        self.updateBackgroundTaskDate()
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
