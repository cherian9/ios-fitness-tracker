import SwiftUI

struct FitnessBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                FitnessTheme.background
                    .ignoresSafeArea()
            )
    }
}

struct FitnessCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(FitnessTheme.cardBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
    }
}

struct FitnessTextFieldStyle: TextFieldStyle {

    func _body(
        configuration: TextField<Self._Label>
    ) -> some View {
        configuration
            .padding(12)
            .background(
                FitnessTheme.elevatedBackground
            )
            .foregroundStyle(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
    }
}

struct FitnessPrimaryButton: ViewModifier {
    let isEnabled: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isEnabled
                    ? color
                    : FitnessTheme.elevatedBackground
            )
            .foregroundStyle(
                isEnabled
                    ? Color.black
                    : FitnessTheme.secondaryText
            )
            .fontWeight(.semibold)
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
    }
}

extension View {

    func fitnessBackground() -> some View {
        modifier(FitnessBackground())
    }

    func fitnessCard() -> some View {
        modifier(FitnessCard())
    }

    func fitnessPrimaryButton(
        isEnabled: Bool,
        color: Color = FitnessTheme.accent
    ) -> some View {
        modifier(
            FitnessPrimaryButton(
                isEnabled: isEnabled,
                color: color
            )
        )
    }
}
