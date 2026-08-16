import SwiftUI
import SwiftData

struct StoredFoodEntryView: View {

    let storedFoods: [StoredFood]

    let onAddFood:
        (StoredFood, Double) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var searchText = ""

    @State private var selectedFood:
        StoredFood?

    @State private var weightInput = ""

    private var filteredFoods: [StoredFood] {

        let trimmedSearch =
            searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedSearch.isEmpty
        else {
            return storedFoods
        }

        return storedFoods.filter { food in

            food.name.localizedCaseInsensitiveContains(
                trimmedSearch
            )
        }
    }

    private var calculatedCalories: Int? {

        guard
            let selectedFood,
            let weightInGrams =
                Double(weightInput),
            weightInGrams > 0
        else {
            return nil
        }

        return Int(
            (
                selectedFood.caloriesPerGram *
                weightInGrams
            ).rounded()
        )
    }

    private var canAddFood: Bool {

        selectedFood != nil &&
            calculatedCalories != nil
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 16) {

                List(filteredFoods) { food in

                    Button {

                        selectedFood = food

                    } label: {

                        HStack {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(food.name)
                                    .foregroundStyle(.white)

                                Text(
                                    "\(food.caloriesPerGram, specifier: "%.2f") cal/g"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    FitnessTheme.secondaryText
                                )
                            }

                            Spacer()

                            if selectedFood?
                                .persistentModelID
                                ==
                                food.persistentModelID {

                                Image(
                                    systemName: "checkmark"
                                )
                                .foregroundStyle(
                                    FitnessTheme.accent
                                )
                            }
                        }
                    }
                    .listRowBackground(
                        FitnessTheme.cardBackground
                    )
                }
                .scrollContentBackground(.hidden)
                .searchable(
                    text: $searchText,
                    prompt: "Type food name"
                )

                VStack(spacing: 12) {

                    TextField(
                        "Weight in grams",
                        text: $weightInput
                    )
                    .keyboardType(.decimalPad)
                    .textFieldStyle(
                        FitnessTextFieldStyle()
                    )

                    if let calculatedCalories {

                        Text(
                            "Calculated Calories: \(calculatedCalories) cal"
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            FitnessTheme.secondaryText
                        )
                    }

                    Button("Add Selected Food") {

                        guard
                            let selectedFood,
                            let weightInGrams =
                                Double(weightInput),
                            weightInGrams > 0
                        else {
                            return
                        }

                        dismissKeyboard()

                        onAddFood(
                            selectedFood,
                            weightInGrams
                        )

                        dismiss()
                    }
                    .disabled(!canAddFood)
                    .fitnessPrimaryButton(
                        isEnabled: canAddFood
                    )
                }
                .padding(
                    [.horizontal, .bottom]
                )
            }
            .fitnessBackground()
            .navigationTitle("Select Food")
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
