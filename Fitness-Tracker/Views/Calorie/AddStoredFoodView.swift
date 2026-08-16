import SwiftUI

enum CalorieInputMode: String,
    CaseIterable,
    Identifiable {

    case perGram = "Per Gram"
    case per100Grams = "Per 100g"

    var id: String {
        rawValue
    }
}

struct AddStoredFoodView: View {

    let onSave:
        (String, Double) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var foodNameInput = ""
    @State private var calorieInput = ""

    @State private var inputMode =
        CalorieInputMode.per100Grams

    private var caloriesPerGram: Double? {

        guard
            let calories =
                Double(calorieInput),
            calories > 0
        else {
            return nil
        }

        switch inputMode {

        case .perGram:
            return calories

        case .per100Grams:
            return calories / 100
        }
    }

    private var canSave: Bool {

        !foodNameInput
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
            &&
            caloriesPerGram != nil
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                TextField(
                    "Food name",
                    text: $foodNameInput
                )
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                Picker(
                    "Calorie type",
                    selection: $inputMode
                ) {

                    ForEach(
                        CalorieInputMode.allCases
                    ) { mode in

                        Text(mode.rawValue)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                TextField(
                    inputMode == .perGram
                        ? "Calories per gram"
                        : "Calories per 100g",
                    text: $calorieInput
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                if let caloriesPerGram {

                    Text(
                        "Stored as \(caloriesPerGram, specifier: "%.2f") cal/g"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        FitnessTheme.secondaryText
                    )
                }

                Button("Save Food") {

                    guard
                        let caloriesPerGram
                    else {
                        return
                    }

                    dismissKeyboard()

                    onSave(
                        foodNameInput,
                        caloriesPerGram
                    )

                    dismiss()
                }
                .disabled(!canSave)
                .fitnessPrimaryButton(
                    isEnabled: canSave
                )

                Spacer()
            }
            .padding()
            .fitnessBackground()
            .navigationTitle("Add Food")
            .toolbarBackground(
                FitnessTheme.background,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
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
}
