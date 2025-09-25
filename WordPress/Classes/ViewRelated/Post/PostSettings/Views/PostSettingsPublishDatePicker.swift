import SwiftUI
import WordPressUI

struct PostSettingsPublishDatePicker: View {
    @ObservedObject var viewModel: PostSettingsViewModel

    var body: some View {
        PublishDatePickerView(configuration: PublishDatePickerConfiguration(
            date: viewModel.settings.publishDate,
            isRequired: !viewModel.isDraftOrPending,
            timeZone: viewModel.timeZone,
            updated: { date in
                viewModel.settings.publishDate = date
            }
        ))
    }
}
