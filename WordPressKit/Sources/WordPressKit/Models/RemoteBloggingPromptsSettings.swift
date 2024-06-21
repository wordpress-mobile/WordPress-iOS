public struct RemoteBloggingPromptsSettings: Codable {
    public var promptCardEnabled: Bool
    public var promptRemindersEnabled: Bool
    public var reminderDays: ReminderDays
    public var reminderTime: String
    public var isPotentialBloggingSite: Bool

    public struct ReminderDays: Codable {
        public var monday: Bool
        public var tuesday: Bool
        public var wednesday: Bool
        public var thursday: Bool
        public var friday: Bool
        public var saturday: Bool
        public var sunday: Bool

        public init(monday: Bool, tuesday: Bool, wednesday: Bool, thursday: Bool, friday: Bool, saturday: Bool, sunday: Bool) {
            self.monday = monday
            self.tuesday = tuesday
            self.wednesday = wednesday
            self.thursday = thursday
            self.friday = friday
            self.saturday = saturday
            self.sunday = sunday
        }
    }

    private enum CodingKeys: String, CodingKey {
        case promptCardEnabled = "prompts_card_opted_in"
        case promptRemindersEnabled = "prompts_reminders_opted_in"
        case reminderDays = "reminders_days"
        case reminderTime = "reminders_time"
        case isPotentialBloggingSite = "is_potential_blogging_site"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(promptRemindersEnabled, forKey: .promptRemindersEnabled)
        try container.encode(reminderDays, forKey: .reminderDays)
        try container.encode(reminderTime, forKey: .reminderTime)
    }

    public init(promptCardEnabled: Bool = false, promptRemindersEnabled: Bool, reminderDays: RemoteBloggingPromptsSettings.ReminderDays, reminderTime: String, isPotentialBloggingSite: Bool = false) {
        self.promptCardEnabled = promptCardEnabled
        self.promptRemindersEnabled = promptRemindersEnabled
        self.reminderDays = reminderDays
        self.reminderTime = reminderTime
        self.isPotentialBloggingSite = isPotentialBloggingSite
    }

}
