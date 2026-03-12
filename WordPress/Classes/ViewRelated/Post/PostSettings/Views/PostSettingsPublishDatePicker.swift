import SwiftUI
import WordPressUI

struct PostSettingsPublishDatePicker<ViewModel: PostSettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

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
