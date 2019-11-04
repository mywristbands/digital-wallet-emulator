//
//  AccountViewController.swift
//  Wallet
//
//  Created by Elias Heffan on 11/2/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

protocol UpdateHomeViewControllerDelegate : NSObjectProtocol{
    func accountsUpdated()
}

class AccountViewController: UIViewController {
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var homeViewDelegate: UpdateHomeViewControllerDelegate?
    
    var walletContainingAccount = Wallet.init()
    var indexInWallet: Int = 0
    var name = ""
    var ID = ""
    var amount: Double = 0
    var buttons: Array<UIButton> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttons = [depositButton, withdrawButton, transferButton, deleteButton]
        
        for button in buttons {
            button.layer.cornerRadius = button.frame.height / 2
        }
        accountLabel.text = "\(name)"
        amountLabel.text = "$ " + String(format: "%0.02f", amount)
    }
    
    @IBAction func onDone() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDeposit() {
        let alert = UIAlertController(title: "How much would you like to deposit", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input amount in dollars here···"
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.becomeFirstResponder()
        })

        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { action in
            guard let depositAmountString = alert.textFields?.first?.text else {return}
            guard let depositAmountDouble = Double(depositAmountString) else {return}
            Api.deposit(wallet: self.walletContainingAccount, toAccountAt: self.indexInWallet, amount:
                depositAmountDouble, completion: { (response, error) in
                    if error == nil {
                        self.homeViewDelegate?.accountsUpdated()
                        self.amount = self.amount + depositAmountDouble
                        self.amountLabel.text = "$ " + String(format: "%0.02f", self.amount)
                    }
            })
        }))

        self.present(alert, animated: true)
    }
    
    @IBAction func onDelete() {
        Api.removeAccount(wallet: walletContainingAccount, removeAccountat: indexInWallet, completion: { (_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in
            self.homeViewDelegate?.accountsUpdated()
            self.onDone()
        })
    }
    
    // MARK: PickerView Delegate and DataSource implementations
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return choices.count
//    }
//
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return choices[row]
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        if row == 0 {
//            typeValue = "Toyota"
//        } else if row == 1 {
//            typeValue = "Honda"
//        } else if row == 2 {
//            typeValue = "Chevy"
//        } else if row == 3 {
//            typeValue = "Audi"
//        } else if row == 4 {
//            typeValue = "BMW"
//        }
//    }
}
