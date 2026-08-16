import SwiftUI
import SwiftData
import UserNotifications

struct CalorieTrackerView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.scenePhase)
    private var scenePhase

    @Query(sort: \StoredFood.name)
    private var storedFoods: [StoredFood]

    @Query(sort: \DailyWeightEntry.date)
    private var dailyWeightEntries: [DailyWeightEntry]

    @AppStorage("currentWeight")
    private var currentWeight: Double = 0

    @AppStorage("goalWeight")
    private var goalWeight: Double = 0

    @AppStorage("height")
    private var height: Double = 0

    @AppStorage("maintenanceCalories")
    private var maintenanceCalories: Int = 0

    @AppStorage("hasSavedProfile")
    private var hasSavedProfile = false

    @AppStorage("lastWeightEntryDate")
    private var lastWeightEntryDate = ""

    @State private var showingProfilePrompt = false
    @State private var showingDailyWeightPrompt = false
    @State private var showingProfileDetails = false
    @State private var showingFoodEntry = false
    @State private var showingAddStoredFood = false

    @State private var weightInput = ""
    @State private var goalWeightInput = ""
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
            ScrollView {
                VStack(spacing: 16) {

                    Text("Calorie Tracker")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.white)

                    if hasSavedProfile {
                        VStack(spacing: 6) {
                            Text("Today's Goal: \(maintenanceCalories) cal")

                            Text(
                                "Calories Consumed: \(caloriesConsumed) cal"
                            )
                        }
                        .font(.subheadline)
                        .foregroundStyle(FitnessTheme.secondaryText)

                    } else {
                        Text("Set up your profile to start tracking")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.secondaryText)
                    }

                    VStack(spacing: 10) {

                        Button("Log Food") {
                            manualFoodNameInput = ""
                            manualFoodCaloriesInput = ""
                            currentMealFoods = []
                            showingFoodEntry = true
                        }
                        .frame(maxWidth: 220)
                        .fitnessPrimaryButton(isEnabled: true)

                        Button("Add Food") {
                            showingAddStoredFood = true
                        }
                        .frame(maxWidth: 220)
                        .fitnessPrimaryButton(
                            isEnabled: true,
                            color: FitnessTheme.accentBlue
                        )
                    }

                    if meals.isEmpty {

                        Text("No meals logged yet")
                            .font(.subheadline)
                            .foregroundStyle(FitnessTheme.secondaryText)
                            .padding(.top, 8)

                    } else {

                        VStack(spacing: 12) {

                            ForEach(
                                Array(meals.enumerated()),
                                id: \.element.id
                            ) { index, meal in

                                VStack(
                                    alignment: .leading,
                                    spacing: 8
                                ) {

                                    HStack {

                                        Text("Meal \(index + 1)")
                                            .font(.headline)
                                            .foregroundStyle(.white)

                                        Spacer()

                                        Text("\(meal.totalCalories) cal")
                                            .font(.subheadline)
                                            .foregroundStyle(
                                                FitnessTheme.accent
                                            )

                                        Button {
                                            deleteMeal(at: index)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    ForEach(meal.foods) { food in

                                        HStack {

                                            VStack(
                                                alignment: .leading,
                                                spacing: 2
                                            ) {

                                                Text(food.name)
                                                    .font(.subheadline)
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

                                            Text("\(food.calories) cal")
                                                .font(.caption)
                                                .foregroundStyle(
                                                    FitnessTheme.secondaryText
                                                )
                                        }
                                    }
                                }
                                .fitnessCard()
                            }
                        }
                    }
                }
                .padding()
            }
            .fitnessBackground()
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showingProfileDetails = true
                    } label: {
                        Image(
                            systemName: "person.crop.circle"
                        )
                        .foregroundStyle(
                            FitnessTheme.accent
                        )
                    }
                    .disabled(!hasSavedProfile)
                }
            }
            .toolbarBackground(
                FitnessTheme.background,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
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

                try? await Task.sleep(
                    for: .seconds(60)
                )

                checkForDailyWeightPrompt()
            }
        }

        .sheet(isPresented: $showingProfilePrompt) {

            ProfileEntryView(
                weightInput: $weightInput,
                goalWeightInput: $goalWeightInput,
                heightInput: $heightInput,
                maintenanceCaloriesInput:
                    $maintenanceCaloriesInput
            ) {

                guard
                    let weight = Double(weightInput),
                    let goalWeightValue =
                        Double(goalWeightInput),
                    let heightValue =
                        Double(heightInput),
                    let calories =
                        Int(maintenanceCaloriesInput),
                    weight > 0,
                    goalWeightValue > 0,
                    heightValue > 0,
                    calories > 0
                else {
                    return
                }

                currentWeight = weight
                goalWeight = goalWeightValue
                height = heightValue
                maintenanceCalories = calories

                saveDailyWeightEntry(weight: weight)

                lastWeightEntryDate = todayKey()

                hasSavedProfile = true

                showingProfilePrompt = false
            }
            .interactiveDismissDisabled()
        }

        .sheet(isPresented: $showingDailyWeightPrompt) {

            WeightEntryView(
                weightInput: $dailyWeightInput
            ) {

                guard
                    let weight =
                        Double(dailyWeightInput),
                    weight > 0
                else {
                    return
                }

                currentWeight = weight

                saveDailyWeightEntry(weight: weight)

                lastWeightEntryDate = todayKey()

                dailyWeightInput = ""

                showingDailyWeightPrompt = false
            }
            .interactiveDismissDisabled()
        }

        .sheet(isPresented: $showingProfileDetails) {

            ProfileDetailsView(
                currentWeight: currentWeight,
                goalWeight: goalWeight,
                height: height,
                maintenanceCalories:
                    maintenanceCalories
            ) { newWeight,
                newGoalWeight,
                newHeight,
                newCalories in

                currentWeight = newWeight
                goalWeight = newGoalWeight
                height = newHeight
                maintenanceCalories = newCalories
            }
        }

        .sheet(isPresented: $showingFoodEntry) {

            FoodEntryView(
                storedFoods: storedFoods,
                manualFoodNameInput:
                    $manualFoodNameInput,
                manualFoodCaloriesInput:
                    $manualFoodCaloriesInput,
                currentMealFoods:
                    currentMealFoods,

                onAddManualFood: {
                    _ = addManualFoodToCurrentMeal()
                },

                onAddStoredFood: { food,
                    weightInGrams in

                    addStoredFoodToCurrentMeal(
                        food,
                        weightInGrams: weightInGrams
                    )
                },

                onDone: {
                    saveCurrentMeal()
                }
            )
        }

        .sheet(isPresented: $showingAddStoredFood) {

            AddStoredFoodView { name,
                caloriesPerGram in

                saveStoredFood(
                    name: name,
                    caloriesPerGram:
                        caloriesPerGram
                )

                showingAddStoredFood = false
            }
        }
    }

    // MARK: - Meal Functions

    private func addManualFoodToCurrentMeal() -> Bool {

        let trimmedName =
            manualFoodNameInput
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            let calories =
                Int(manualFoodCaloriesInput),
            !trimmedName.isEmpty,
            calories > 0
        else {
            return false
        }

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

    private func addStoredFoodToCurrentMeal(
        _ food: StoredFood,
        weightInGrams: Double
    ) {

        let calories =
            Int(
                (
                    food.caloriesPerGram *
                    weightInGrams
                ).rounded()
            )

        currentMealFoods.append(
            FoodItem(
                name: food.name,
                weightInGrams: weightInGrams,
                calories: calories
            )
        )
    }

    private func saveCurrentMeal() {

        if
            !manualFoodNameInput
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            ||
            !manualFoodCaloriesInput.isEmpty
        {

            guard addManualFoodToCurrentMeal()
            else {
                return
            }
        }

        guard !currentMealFoods.isEmpty
        else {
            return
        }

        meals.append(
            MealEntry(
                foods: currentMealFoods
            )
        )

        currentMealFoods = []
        manualFoodNameInput = ""
        manualFoodCaloriesInput = ""

        showingFoodEntry = false
    }

    private func deleteMeal(at index: Int) {

        guard meals.indices.contains(index)
        else {
            return
        }

        meals.remove(at: index)
    }

    // MARK: - Weight

    private func saveDailyWeightEntry(
        weight: Double
    ) {

        let key = todayKey()

        let startOfDay =
            Calendar.current.startOfDay(
                for: Date()
            )

        if let existingEntry =
            dailyWeightEntries.first(
                where: {
                    $0.dayKey == key
                }
            ) {

            existingEntry.weight = weight
            existingEntry.date = startOfDay

        } else {

            modelContext.insert(
                DailyWeightEntry(
                    dayKey: key,
                    date: startOfDay,
                    weight: weight
                )
            )
        }
    }

    // MARK: - Stored Food

    private func saveStoredFood(
        name: String,
        caloriesPerGram: Double
    ) {

        let trimmedName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !trimmedName.isEmpty,
            caloriesPerGram > 0
        else {
            return
        }

        if let existingFood =
            storedFoods.first(
                where: {
                    $0.name.localizedCaseInsensitiveCompare(
                        trimmedName
                    ) == .orderedSame
                }
            ) {

            existingFood.caloriesPerGram =
                caloriesPerGram

        } else {

            modelContext.insert(
                StoredFood(
                    name: trimmedName,
                    caloriesPerGram:
                        caloriesPerGram
                )
            )
        }
    }

    private func seedStoredFoodsIfNeeded() {

        guard storedFoods.isEmpty
        else {
            return
        }

        let foods = [

            StoredFood(
                name: "Apple",
                caloriesPerGram: 0.52
            ),

            StoredFood(
                name: "Banana",
                caloriesPerGram: 0.89
            ),

            StoredFood(
                name: "Chicken Breast",
                caloriesPerGram: 1.65
            ),

            StoredFood(
                name: "Cooked Rice",
                caloriesPerGram: 1.30
            ),

            StoredFood(
                name: "Egg",
                caloriesPerGram: 1.55
            ),

            StoredFood(
                name: "Greek Yogurt",
                caloriesPerGram: 0.59
            ),

            StoredFood(
                name: "Oats",
                caloriesPerGram: 3.89
            ),

            StoredFood(
                name: "Salmon",
                caloriesPerGram: 2.08
            ),

            StoredFood(
                name: "White Bread",
                caloriesPerGram: 2.65
            )
        ]

        for food in foods {
            modelContext.insert(food)
        }
    }

    // MARK: - Daily Weight Reminder

    private func checkForDailyWeightPrompt() {

        guard
            hasSavedProfile,
            !showingProfilePrompt,
            !showingDailyWeightPrompt,
            !showingProfileDetails,
            !showingFoodEntry,
            !showingAddStoredFood,
            shouldAskForWeightToday()
        else {
            return
        }

        showingDailyWeightPrompt = true
    }

    private func shouldAskForWeightToday() -> Bool {

        let calendar = Calendar.current
        let now = Date()

        guard let sevenAM =
            calendar.date(
                bySettingHour: 7,
                minute: 0,
                second: 0,
                of: now
            )
        else {
            return false
        }

        return now >= sevenAM &&
            lastWeightEntryDate != todayKey()
    }

    private func todayKey() -> String {

        let components =
            Calendar.current.dateComponents(
                [.year, .month, .day],
                from: Date()
            )

        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    // MARK: - Notifications

    private func requestDailyWeightNotificationPermission() {

        UNUserNotificationCenter
            .current()
            .requestAuthorization(
                options: [.alert, .sound]
            ) { granted, _ in

                guard granted else {
                    return
                }

                scheduleDailyWeightNotification()
            }
    }

    private func scheduleDailyWeightNotification() {

        let notificationID =
            "daily-weight-reminder"

        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    notificationID
                ]
            )

        let content =
            UNMutableNotificationContent()

        content.title =
            "Enter today's weight"

        content.body =
            "Open Fitness Tracker and record your current weight."

        content.sound = .default

        var dateComponents =
            DateComponents()

        dateComponents.hour = 7
        dateComponents.minute = 0

        let trigger =
            UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

        let request =
            UNNotificationRequest(
                identifier: notificationID,
                content: content,
                trigger: trigger
            )

        UNUserNotificationCenter
            .current()
            .add(request)
    }
}
