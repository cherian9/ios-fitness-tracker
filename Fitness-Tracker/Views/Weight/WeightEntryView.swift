import SwiftUI

struct WeightEntryView: View {
    @Binding var weightInput: String
    let onSave: () -> Void

    private var canSave: Bool {
        guard let weight = Double(weightInput) else {
            return false
        }

        return weight > 0
    }

    var body: some View {
        VStack(spacing: 20) {

            Text("Enter Today's Weight")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            TextField(
                "Weight in kg",
                text: $weightInput
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(FitnessTextFieldStyle())

            Button("Save") {
                dismissKeyboard()
                onSave()
            }
            .disabled(!canSave)
            .fitnessPrimaryButton(isEnabled: canSave)
        }
        .padding()
        .fitnessBackground()
        .presentationBackground(FitnessTheme.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    dismissKeyboard()
                }
                .foregroundStyle(FitnessTheme.accent)
            }
        }
    }
}
