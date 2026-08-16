import SwiftUI

struct ProfileDetailsView: View {

    let currentWeight: Double
    let goalWeight: Double
    let height: Double
    let maintenanceCalories: Int

    let onSave:
        (Double, Double, Double, Int) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var weightInput = ""
    @State private var goalWeightInput = ""
    @State private var heightInput = ""
    @State private var maintenanceCaloriesInput = ""

    @State private var isEditing = false

    private var canSave: Bool {

        guard
            let weight =
                Double(weightInput),
            let goal =
                Double(goalWeightInput),
            let h =
                Double(heightInput),
            let cal =
                Int(maintenanceCaloriesInput)
        else {
            return false
        }

        return weight > 0 &&
            goal > 0 &&
            h > 0 &&
            cal > 0
    }

    var body: some View {

        NavigationStack {

            List {

                if isEditing {

                    Section("Weight (kg)") {

                        TextField(
                            "Weight in kg",
                            text: $weightInput
                        )
                        .keyboardType(.decimalPad)
                    }

                    Section("Goal Weight (kg)") {

                        TextField(
                            "Goal weight in kg",
                            text: $goalWeightInput
                        )
                        .keyboardType(.decimalPad)
                    }

                    Section("Height (cm)") {

                        TextField(
                            "Height in cm",
                            text: $heightInput
                        )
                        .keyboardType(.decimalPad)
                    }

                    Section("Maintenance Calories") {

                        TextField(
                            "Calories",
                            text:
                                $maintenanceCaloriesInput
                        )
                        .keyboardType(.numberPad)
                    }

                } else {

                    LabeledContent(
                        "Current Weight",
                        value:
                            "\(String(format: "%.1f", currentWeight)) kg"
                    )

                    LabeledContent(
                        "Goal Weight",
                        value:
                            "\(String(format: "%.1f", goalWeight)) kg"
                    )

                    LabeledContent(
                        "Height",
                        value:
                            "\(String(format: "%.1f", height)) cm"
                    )

                    LabeledContent(
                        "Maintenance Calories",
                        value:
                            "\(maintenanceCalories) cal"
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .fitnessBackground()
            .navigationTitle("Profile")
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

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    if isEditing {

                        Button("Save") {

                            guard
                                let weight =
                                    Double(weightInput),
                                let goal =
                                    Double(goalWeightInput),
                                let h =
                                    Double(heightInput),
                                let cal =
                                    Int(
                                        maintenanceCaloriesInput
                                    )
                            else {
                                return
                            }

                            dismissKeyboard()

                            onSave(
                                weight,
                                goal,
                                h,
                                cal
                            )

                            isEditing = false

                            dismiss()
                        }
                        .disabled(!canSave)
                        .foregroundStyle(
                            FitnessTheme.accent
                        )

                    } else {

                        Button("Edit") {

                            weightInput =
                                String(
                                    format: "%.1f",
                                    currentWeight
                                )

                            goalWeightInput =
                                String(
                                    format: "%.1f",
                                    goalWeight
                                )

                            heightInput =
                                String(
                                    format: "%.1f",
                                    height
                                )

                            maintenanceCaloriesInput =
                                "\(maintenanceCalories)"

                            isEditing = true
                        }
                        .foregroundStyle(
                            FitnessTheme.accent
                        )
                    }
                }

                if isEditing {

                    ToolbarItem(
                        placement: .topBarLeading
                    ) {

                        Button("Cancel") {

                            dismissKeyboard()

                            isEditing = false
                        }
                        .foregroundStyle(
                            FitnessTheme.secondaryText
                        )
                    }
                }

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
