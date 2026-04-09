//
//  Utilities.swift
//  ClimaBeats
//
//

import Foundation
import UIKit

class Utilities {

    private static let underlineLayerName = "UnderlineLayer"
    
    static func styleTextField(_ textfield:UITextField) {

        // Remove border on text field
        textfield.borderStyle = .none

        // Remove old underline before adding a fresh one.
        textfield.layer.sublayers?.removeAll(where: { $0.name == underlineLayerName })

        textfield.layoutIfNeeded()

        // Create and position the bottom line as an underline.
        let bottomLine = CALayer()
        bottomLine.name = underlineLayerName
        bottomLine.frame = CGRect(
            x: 0,
            y: max(textfield.bounds.height - 2, 0),
            width: textfield.bounds.width,
            height: 2
        )
        bottomLine.backgroundColor = UIColor.init(red: 30/255, green: 10/255, blue: 87/255, alpha: 1).cgColor

        // Add the line to the text field
        textfield.layer.addSublayer(bottomLine)

    }
    
    static func styleFilledButton(_ button:UIButton) {
        
        // Filled rounded corner style
        button.backgroundColor = UIColor.init(red: 30/255, green: 10/255, blue: 87/255, alpha: 1)
        button.layer.cornerRadius = 25.0
        button.tintColor = UIColor.white
    }
    
    static func styleHollowButton(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 25.0
        button.tintColor = UIColor.black
    }
    
    static func isPasswordValid(_ password : String) -> Bool {
        
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
    
}
