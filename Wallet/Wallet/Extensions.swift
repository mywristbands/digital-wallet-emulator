//
//  Extensions.swift
//  Wallet
//
//  Created by Weisu Yin on 10/6/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

protocol PinTextFieldDelegate : UITextFieldDelegate {
    func didPressBackspace(textField : PinTextField)
}

class PinTextField: UITextField {

    override func deleteBackward() {
        if let pinDelegate = self.delegate as? PinTextFieldDelegate {
            pinDelegate.didPressBackspace(textField: self)
        }
        super.deleteBackward()
    }
}
