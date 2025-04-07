//
//  PickerHandler.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/3/24.
//

import UIKit

class PickerHandler: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // Array of numbers from 0.0 to 1.4 with a 0.1 interval
    let pickerData: [Float] = stride(from: 0.1, to: 1.4, by: 0.05).map { Float($0) }
    
    // Callback to pass selected value to the view controller
    var selectedValue : Float = 0.0
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // Single component (column)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count // Number of rows (values) in the picker
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        
        // Set the text and customize its appearance
        label.text = String(format: "%.2f", pickerData[row])
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18) // Change font size if needed
        
        // Customize text color (e.g., blue color)
        label.textColor = .white
        
        return label
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(format: "%.2f", pickerData[row]) 
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedValue = pickerData[row]
        print("Debug - selectedValue", selectedValue)
    }
}
