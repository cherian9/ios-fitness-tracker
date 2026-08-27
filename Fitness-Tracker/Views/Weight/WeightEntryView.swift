/*import SwiftUI

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
}*/
import SwiftUI

 struct WeightEntryView: View {
    
    @Binding var weightInput: String
    
    let userId: Int
    let onSave: (Weight) -> Void
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let weightService = WeightService()
    
    
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
            
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            
            Button {
                Task {
                    await saveWeight()
                }
            } label: {
                
                if isSaving {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Save")
                }
            }
            .disabled(!canSave || isSaving)
            .fitnessPrimaryButton(
                isEnabled: canSave && !isSaving
            )
            
            
            Spacer()
        }
        .padding()
        .fitnessBackground()
        .presentationBackground(FitnessTheme.background)
    }
    
    
    private func saveWeight() async {
        
        guard let weight = Double(weightInput) else {
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            
            let newWeight = try await weightService.addWeight(
                weight: weight,
                date: Date(),
                userId: userId
            )
            
            onSave(newWeight)
            
            weightInput = ""
            
            dismiss()
            
        } catch {
            
            errorMessage = error.localizedDescription
            
        }
        
        isSaving = false
    }
}
