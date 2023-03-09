import SwiftUI

struct AppColorPickerView: View {

    @StateObject var vm = AppColorPickerViewModel()

    var body: some View {
        ColorPicker(selection: $vm.color, supportsOpacity: false) {
            HStack {
                Text(colorPickerTitle)

                Spacer()
                Button(action: {
                    vm.restoreDefaultColor()
                }, label: {
                    Text(resetButtonTitle)
                })
            }
        }
        .font(.callout)
    }

    private var colorPickerTitle: String {
        NSLocalizedString("App Color", comment: "Navigates to color picker screen to change the app primary color")
    }

    private var resetButtonTitle: String {
        NSLocalizedString("Reset", comment: "Restores default app primary color")
    }
}

struct AppColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AppColorPickerView()
    }
}
