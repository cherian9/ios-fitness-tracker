import SwiftUI
import UIKit

func dismissKeyboard() {

    UIApplication.shared.sendAction(
        #selector(
            UIResponder.resignFirstResponder
        ),
        to: nil,
        from: nil,
        for: nil
    )
}//
//  View+Keyboard.swift
//  Fitness-Tracker
//
//  Created by Cherian Chirackal Joseph on 11/08/2026.
//

