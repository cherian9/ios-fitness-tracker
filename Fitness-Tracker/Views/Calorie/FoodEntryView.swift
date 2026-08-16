import SwiftUI

struct FoodEntryView: View {

    let storedFoods: [StoredFood]

    @Binding var manualFoodNameInput: String
    @Binding var manualFoodCaloriesInput: String

    let currentMealFoods: [FoodItem]

    let onAddManualFood: () -> Void

    let onAddStoredFood:
        (StoredFood, Double) -> Void

    let onDone: () -> Void

    @State private var showingFoodSelector = false

    private var canAddManualFood: Bool {

        let trimmedName =
            manualFoodNameInput
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            let calories =
                Int(manualFoodCaloriesInput)
        else {
            return false
        }

        return !trimmedName.isEmpty &&
            calories > 0
    }

    private var canFinishMeal: Bool {
        !currentMealFoods.isEmpty ||
            canAddManualFood
    }

    var body: some View {

        VStack(spacing: 20) {

            Text("Log Meal")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            VStack(spacing: 12) {

                TextField(
                    "Food name",
                    text: $manualFoodNameInput
                )
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                TextField(
                    "Calories",
                    text: $manualFoodCaloriesInput
                )
                .keyboardType(.numberPad)
                .textFieldStyle(
                    FitnessTextFieldStyle()
                )

                Button {
                    showingFoodSelector = true
                } label: {

                    HStack {

                        Text("Select Food")

                        Spacer()

                        Image(
                            systemName: "chevron.right"
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        FitnessTheme.cardBackground
                    )
                    .foregroundStyle(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )
                }
            }

            if !currentMealFoods.isEmpty {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text("Current Meal")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(currentMealFoods) { food in

                        HStack {

                            VStack(
                                alignment: .leading,
                                spacing: 2
                            ) {

                                Text(food.name)
                                    .foregroundStyle(.white)

                                if let weightInGrams =
                                    food.weightInGrams {

                                    Text(
                                        "\(weightInGrams, specifier: "%.0f") g"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(
                                        FitnessTheme.secondaryText
                                    )
                                }
                            }

                            Spacer()

                            Text(
                                "\(food.calories) cal"
                            )
                            .foregroundStyle(
                                FitnessTheme.accent
                            )
                        }
                        .font(.subheadline)
                    }
                }
                .fitnessCard()
            }

            VStack(spacing: 12) {

                Button("Add Food") {

                    dismissKeyboard()

                    onAddManualFood()
                }
                .disabled(!canAddManualFood)
                .fitnessPrimaryButton(
                    isEnabled: canAddManualFood
                )

                Button("Done") {

                    dismissKeyboard()

                    onDone()
                }
                .disabled(!canFinishMeal)
                .fitnessPrimaryButton(
                    isEnabled: canFinishMeal,
                    color: FitnessTheme.accentBlue
                )
            }
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
        .sheet(
            isPresented:
                $showingFoodSelector
        ) {

            StoredFoodEntryView(
                storedFoods: storedFoods,
                onAddFood: onAddStoredFood
            )
        }
    }
}
