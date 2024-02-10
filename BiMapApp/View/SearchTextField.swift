//
//  SearchTextField.swift
//  BiMapApp
//
//  Created by Kyrylo Derkach on 17.09.2023.
//

import Foundation
import UIKit

class SearchTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
}
