//
//  Keyboard.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/12/24.
//

import UIKit

extension UIView {
    func hideKeyboard() -> Bool {
        // Returns true if hides keyboard
        return UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
