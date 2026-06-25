import SwiftUI
import Foundation
import SwiftData
import UserNotifications

@Model
final class StoredFood {
    @Attribute(.unique) var name: String
    var caloriesPerGram: Double

    init(name: String, caloriesPerGram: Double) {
        self.name = name
        self.caloriesPerGram = caloriesPerGram
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \StoredFood.name) private var storedFoods: [StoredFood]

    @AppStorage("currentWeight") private var currentWeight: Double = 0
    @AppStorage("height") private var height: Double = 0
    @AppStorage("maintenanceCalories") private var maintenanceCalories: Int = 0
    @AppStorage("hasSavedProfile") private var hasSavedProfile = false
    @AppStorage("lastWeightEntryDate") private var lastWeightEntryDate = ""

    @State private var showingProfilePrompt = false
    @State private var showingDailyWeightPrompt = false
    @State private var showingProfileDetails = false
    @State private var showingFoodEntry = false
    @State private var weightInput = ""
    @State private var heightInput = ""
    @State private var maintenanceCaloriesInput = ""
    @State private var dailyWeightInput = ""
    @State private var manualFoodNameInput = ""
    @State private var manualFoodCaloriesInput = ""
    @State private var currentMealFoods: [FoodItem] = []
    @State private var meals: [MealEntry] = []

    private var caloriesConsumed: Int {
        meals.reduce(0) { total, meal in
            total + meal.totalCalories
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Calorie Tracker")
                    .font(.largeTitle)
                    .bold()

                if hasSavedProfile {
                    VStack(spacing: 6) {
                        Text("Today's Goal: \(maintenanceCalories) cal")
                        Text("Calories Consumed: \(caloriesConsumed) cal")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                } else {
                    Text("Set up your profile to start tracking")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Button("Log Food") {
                    manualFoodNameInput = ""
                    manualFoodCaloriesInput = ""
                    currentMealFoods = []
                    showingFoodEntry = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                if meals.isEmpty {
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    List(Array(meals.enumerated()), id: \.element.id) { index, meal in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Meal \(index + 1)")
                                    .font(.headline)
                                Spacer()
                                Text("\(meal.totalCalories) cal")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            ForEach(meal.foods) { food in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(food.name)
                                            .font(.subheadline)
                                        if let weightInGrams = food.weightInGrams {
                                            Text("\(weightInGrams, specifier: "%.0f") g")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Text("\(food.calories) cal")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .frame(minHeight: 220)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfileDetails = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .disabled(!hasSavedProfile)
                }
            }
        }
        .onAppear {
            seedStoredFoodsIfNeeded()
            showingProfilePrompt = !hasSavedProfile
            checkForDailyWeightPrompt()
            requestDailyWeightNotificationPermission()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkForDailyWeightPrompt()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                checkForDailyWeightPrompt()
            }
        }
        .sheet(isPresented: $showingProfilePrompt) {
            ProfileEntryView(
                weightInput: $weightInput,
                heightInput: $heightInput,
                maintenanceCaloriesInput: $maintenanceCaloriesInput
            ) {
                guard let weight = Double(weightInput),
                      let heightValue = Double(heightInput),
                      let calories = Int(maintenanceCaloriesInput),
                      weight > 0,
                      heightValue > 0,
                      calories > 0 else { return }

                currentWeight = weight
                height = heightValue
                maintenanceCalories = calories
                lastWeightEntryDate = todayKey()
                hasSavedProfile = true
                showingProfilePrompt = false
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingDailyWeightPrompt) {
            WeightEntryView(weightInput: $dailyWeightInput) {
                guard let weight = Double(dailyWeightInput), weight > 0 else { return }

                currentWeight = weight
                lastWeightEntryDate = todayKey()
                dailyWeightInput = ""
                showingDailyWeightPrompt = false
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingProfileDetails) {
            ProfileDetailsView(
                currentWeight: currentWeight,
                height: height,
                maintenanceCalories: maintenanceCalories
            )
        }
        .sheet(isPresented: $showingFoodEntry) {
            FoodEntryView(
                storedFoods: storedFoods,
                manualFoodNameInput: $manualFoodNameInput,
                manualFoodCaloriesInput: $manualFoodCaloriesInput,
                currentMealFoods: currentMealFoods,
                onAddManualFood: {
                    _ = addManualFoodToCurrentMeal()
                },
                onAddStoredFood: { food, weightInGrams in
                    addStoredFoodToCurrentMeal(food, weightInGrams: weightInGrams)
                },
                onDone: {
                    saveCurrentMeal()
                }
            )
        }
    }

    private func addManualFoodToCurrentMeal() -> Bool {
        let trimmedName = manualFoodNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let calories = Int(manualFoodCaloriesInput),
              !trimmedName.isEmpty,
              calories > 0 else { return false }

        currentMealFoods.append(
            FoodItem(
                name: trimmedName,
                weightInGrams: nil,
                calories: calories
            )
        )
        manualFoodNameInput = ""
        manualFoodCaloriesInput = ""
        return true
    }

    private func addStoredFoodToCurrentMeal(_ food: StoredFood, weightInGrams: Double) {
        let calories = Int((food.caloriesPerGram * weightInGrams).rounded())
        currentMealFoods.append(
            FoodItem(
                name: food.name,
                weightInGrams: weightInGrams,
                calories: calories
            )
        )
    }

    private func saveCurrentMeal() {
        if !manualFoodNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !manualFoodCaloriesInput.isEmpty {
            guard addManualFoodToCurrentMeal() else { return }
        }

        guard !currentMealFoods.isEmpty else { return }
        meals.append(MealEntry(foods: currentMealFoods))
        currentMealFoods = []
        manualFoodNameInput = ""
        manualFoodCaloriesInput = ""
        showingFoodEntry = false
    }

    private func seedStoredFoodsIfNeeded() {
        guard storedFoods.isEmpty else { return }

        let foods = [
            StoredFood(name: "Apple", caloriesPerGram: 0.52),
            StoredFood(name: "Banana", caloriesPerGram: 0.89),
            StoredFood(name: "Chicken Breast", caloriesPerGram: 1.65),
            StoredFood(name: "Cooked Rice", caloriesPerGram: 1.30),
            StoredFood(name: "Egg", caloriesPerGram: 1.55),
            StoredFood(name: "Greek Yogurt", caloriesPerGram: 0.59),
            StoredFood(name: "Oats", caloriesPerGram: 3.89),
            StoredFood(name: "Salmon", caloriesPerGram: 2.08),
            StoredFood(name: "White Bread", caloriesPerGram: 2.65)
        ]

        for food in foods {
            modelContext.insert(food)
        }
    }

    private func checkForDailyWeightPrompt() {
        guard hasSavedProfile,
              !showingProfilePrompt,
              !showingDailyWeightPrompt,
              !showingProfileDetails,
              !showingFoodEntry,
              shouldAskForWeightToday() else { return }

        showingDailyWeightPrompt = true
    }

    private func shouldAskForWeightToday() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let sevenAM = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) else {
            return false
        }

        return now >= sevenAM && lastWeightEntryDate != todayKey()
    }

    private func todayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func requestDailyWeightNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            scheduleDailyWeightNotification()
        }
    }

    private func scheduleDailyWeightNotification() {
        let notificationID = "daily-weight-reminder"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Enter today's weight"
        content.body = "Open Fitness Tracker and record your current weight."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

private struct MealEntry: Identifiable {
    let id = UUID()
    let foods: [FoodItem]

    var totalCalories: Int {
        foods.reduce(0) { total, food in
            total + food.calories
        }
    }
}

private struct FoodItem: Identifiable {
    let id = UUID()
    let name: String
    let weightInGrams: Double?
    let calories: Int
}

private struct ProfileEntryView: View {
    @Binding var weightInput: String
    @Binding var heightInput: String
    @Binding var maintenanceCaloriesInput: String
    let onSave: () -> Void

    private var canSave: Bool {
        guard let weight = Double(weightInput),
              let height = Double(heightInput),
              let calories = Int(maintenanceCaloriesInput) else { return false }

        return weight > 0 && height > 0 && calories > 0
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Up Profile")
                .font(.title2)
                .bold()

            VStack(spacing: 12) {
                TextField("Weight in kg", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Height in cm", text: $heightInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Maintenance calories", text: $maintenanceCaloriesInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Save") {
                onSave()
            }
            .disabled(!canSave)
            .padding()
            .frame(maxWidth: .infinity)
            .background(canSave ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

private struct WeightEntryView: View {
    @Binding var weightInput: String
    let onSave: () -> Void

    private var canSave: Bool {
        guard let weight = Double(weightInput) else { return false }
        return weight > 0
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Today's Weight")
                .font(.title2)
                .bold()

            TextField("Weight in kg", text: $weightInput)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            Button("Save") {
                onSave()
            }
            .disabled(!canSave)
            .padding()
            .frame(maxWidth: .infinity)
            .background(canSave ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

private struct FoodEntryView: View {
    let storedFoods: [StoredFood]
    @Binding var manualFoodNameInput: String
    @Binding var manualFoodCaloriesInput: String
    let currentMealFoods: [FoodItem]
    let onAddManualFood: () -> Void
    let onAddStoredFood: (StoredFood, Double) -> Void
    let onDone: () -> Void

    @State private var showingFoodSelector = false

    private var canAddManualFood: Bool {
        let trimmedName = manualFoodNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let calories = Int(manualFoodCaloriesInput) else { return false }
        return !trimmedName.isEmpty && calories > 0
    }

    private var canFinishMeal: Bool {
        !currentMealFoods.isEmpty || canAddManualFood
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Log Meal")
                .font(.title2)
                .bold()

            VStack(spacing: 12) {
                TextField("Food name", text: $manualFoodNameInput)
                    .textFieldStyle(.roundedBorder)

                TextField("Calories", text: $manualFoodCaloriesInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button {
                    showingFoodSelector = true
                } label: {
                    HStack {
                        Text("Select Food")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }

            if !currentMealFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Meal")
                        .font(.headline)

                    ForEach(currentMealFoods) { food in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                if let weightInGrams = food.weightInGrams {
                                    Text("\(weightInGrams, specifier: "%.0f") g")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Text("\(food.calories) cal")
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    }
                }
            }

            VStack(spacing: 12) {
                Button("Add Food") {
                    onAddManualFood()
                }
                .disabled(!canAddManualFood)
                .padding()
                .frame(maxWidth: .infinity)
                .background(canAddManualFood ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Done") {
                    onDone()
                }
                .disabled(!canFinishMeal)
                .padding()
                .frame(maxWidth: .infinity)
                .background(canFinishMeal ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $showingFoodSelector) {
            StoredFoodEntryView(storedFoods: storedFoods, onAddFood: onAddStoredFood)
        }
    }
}

private struct StoredFoodEntryView: View {
    let storedFoods: [StoredFood]
    let onAddFood: (StoredFood, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFood: StoredFood?
    @State private var weightInput = ""

    private var filteredFoods: [StoredFood] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return storedFoods }

        return storedFoods.filter { food in
            food.name.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var calculatedCalories: Int? {
        guard let selectedFood,
              let weightInGrams = Double(weightInput),
              weightInGrams > 0 else { return nil }

        return Int((selectedFood.caloriesPerGram * weightInGrams).rounded())
    }

    private var canAddFood: Bool {
        selectedFood != nil && calculatedCalories != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                List(filteredFoods) { food in
                    Button {
                        selectedFood = food
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.name)
                                    .foregroundColor(.primary)
                                Text("\(food.caloriesPerGram, specifier: "%.2f") cal/g")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedFood?.persistentModelID == food.persistentModelID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Type food name")

                VStack(spacing: 12) {
                    TextField("Weight in grams", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    if let calculatedCalories {
                        Text("Calculated Calories: \(calculatedCalories) cal")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Button("Add Selected Food") {
                        guard let selectedFood,
                              let weightInGrams = Double(weightInput),
                              weightInGrams > 0 else { return }

                        onAddFood(selectedFood, weightInGrams)
                        dismiss()
                    }
                    .disabled(!canAddFood)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(canAddFood ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Select Food")
        }
    }
}

private struct ProfileDetailsView: View {
    let currentWeight: Double
    let height: Double
    let maintenanceCalories: Int

    var body: some View {
        NavigationStack {
            List {
                LabeledContent("Current Weight", value: "\(String(format: "%.1f", currentWeight)) kg")
                LabeledContent("Height", value: "\(String(format: "%.1f", height)) cm")
                LabeledContent("Maintenance Calories", value: "\(maintenanceCalories) cal")
            }
            .navigationTitle("Profile")
        }
    }
}
