import SwiftUI

struct AppColorListView: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme

    @StateObject var vm = AppColorListViewModel()

    var body: some View {
        List(vm.allAccents) { accent in
            Button(action: {
                vm.selectedAccent = accent
            }, label: {
                makeRow(with: accent)
            })
        }
    }

    private func makeRow(with accent: AppColor.Accent) -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(accent.color)
                .frame(width: 32, height: 32)
                .padding(.horizontal)
                .padding(.vertical, 4)

            Text(accent.description)
                .foregroundColor(.primary)

            Spacer()
            if accent == vm.selectedAccent {
                Image(systemName: "checkmark")
                    .foregroundColor(accent.color)
            }
        }
    }

}

final class AppColorListViewModel: ObservableObject {

    var allAccents: [AppColor.Accent] {
        AppColor.Accent.allCasesSorted
    }

    @Published var selectedAccent = AppColor.accent {
        didSet {
            if selectedAccent != oldValue {
                updateAccent(selectedAccent)
            }
        }
    }

    private func updateAccent(_ accent: AppColor.Accent) {
        AppColor.updateAccent(with: accent)

        let appDelegate = UIApplication.shared.delegate as? WordPressAppDelegate
        appDelegate?.customizeAppearance()
    }

}

struct AppColorListView_Previews: PreviewProvider {
    static var previews: some View {
        AppColorListView()
    }
}
