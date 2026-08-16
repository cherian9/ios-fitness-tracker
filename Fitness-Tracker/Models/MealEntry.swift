import Foundation

struct MealEntry: Identifiable {
    let id = UUID()
    let foods: [FoodItem]

    var totalCalories: Int {
        foods.reduce(0) { total, food in
            total + food.calories
        }
    }
}
