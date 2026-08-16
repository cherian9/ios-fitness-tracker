import SwiftUI

struct ProfileEntryView: View {

    @Binding var weightInput: String
    @Binding var goalWeightInput: String
    @Binding var heightInput: String
    @Binding var maintenanceCaloriesInput: String

    let onSave: () -> Void

    private var canSave: Bool {

        guard
            let weight = Double(weightInput),
            let goalWeight =
                Double(goalWeightInput),
            let height =
                Double(heightInput),
            let calories =
                Int(maintenanceCaloriesInput)
        else {
            return false
        }

        return weight > 0 &&
            goalWeight > 0 &&
            height > 0 &&
            calories > 0
    }

    var body: some View {

        VStack(spacing: 20) {

            Text("Set Up Profile")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            VStack(spacing: 12) {

                TextField(
                    "Weight in kg",
                    text: $weightInput
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                TextField(
                    "Goal weight in kg",
                    text: $goalWeightInput
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                TextField(
                    "Height in cm",
                    text: $heightInput
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                TextField(
                    "Maintenance calories",
                    text: $maintenanceCaloriesInput
                )
                .keyboardType(.numberPad)
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )
            }

            Button("Save") {

                dismissKeyboard()

                onSave()
            }
            .disabled(!canSave)
            .fitnessPrimaryButton(
                isEnabled: canSave
            )
        }
        .padding()
        .fitnessBackground()
        .presentationBackground(
            FitnessTheme.background
        )
        .toolbar {

            ToolbarItemGroup(
                placement: .keyboard
            ) {

                Spacer()

                Button("Done") {
                    dismissKeyboard()
                }
                .foregroundStyle(
                    FitnessTheme.accent
                )
            }
        }
    }
}
