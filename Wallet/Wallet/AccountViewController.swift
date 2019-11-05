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

class AccountViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var transferPopup: UIView!
    @IBOutlet weak var accountPicker: UIPickerView!
    @IBOutlet weak var transferAmountField: UITextField!
    @IBOutlet weak var transferDoneButton: UIButton!
    
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
    var pickerOptions: Array<Account> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountLabel.text = "\(name)"
        amountLabel.text = "$" + String(format: "%0.02f", amount)
        
        buttons = [depositButton, withdrawButton, transferButton, deleteButton]
        for button in buttons {
            button.layer.cornerRadius = button.frame.height / 2
        }
        
        setupPopup()
    }
    
    func setupPopup() {
        func setupPopupAppearance() {
            transferPopup.layer.shadowColor = UIColor.darkGray.cgColor
            transferPopup.layer.shadowOpacity = 0.7
            transferPopup.layer.shadowOffset = CGSize(width: 3, height: 3)
            transferPopup.layer.shadowRadius = 15.0
            transferPopup.layer.masksToBounds = false
            
            transferPopup.layer.cornerRadius = transferPopup.frame.height / 10
        }
        func setupPopupInternals() {
            accountPicker.delegate = self
            accountPicker.dataSource = self

            for account in walletContainingAccount.accounts {
                if account.ID != self.ID {
                    pickerOptions.append(account)
                }
            }
            
            transferAmountField.placeholder = "Amount"
            transferAmountField.keyboardType = UIKeyboardType.decimalPad
            
            transferDoneButton.layer.cornerRadius = transferDoneButton.frame.height / 2
        }
        setupPopupAppearance()
        setupPopupInternals()
    }
    
    @IBAction func onDone() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDeposit() {
        let alert = UIAlertController(title: "How much would you like to deposit?", message: nil, preferredStyle: .alert)
        
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
                        self.amount += depositAmountDouble
                        self.amountLabel.text = "$" + String(format: "%0.02f", self.amount)
                    }
            })
        }))

        self.present(alert, animated: true)
    }
    
    @IBAction func onWithdraw() {
        let alert = UIAlertController(title: "How much would you like to withdraw?", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input amount in dollars here···"
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.becomeFirstResponder()
        })

        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { action in
            guard let withdrawAmountString = alert.textFields?.first?.text else {return}
            guard var withdrawAmountDouble = Double(withdrawAmountString) else {return}
            
            // Don't let user withdraw more money than they have in their account
            if withdrawAmountDouble > self.amount {
                withdrawAmountDouble = self.amount
            }
            Api.withdraw(wallet: self.walletContainingAccount, fromAccountAt: self.indexInWallet, amount: withdrawAmountDouble, completion: { (response, error) in
                    if error == nil {
                        self.homeViewDelegate?.accountsUpdated()
                        self.amount -= withdrawAmountDouble
                        self.amountLabel.text = "$" + String(format: "%0.02f", self.amount)
                    }
            })
        }))

        self.present(alert, animated: true)
    }
    
    @IBAction func onTransfer() {
        transferPopup.isHidden = false
        transferAmountField.becomeFirstResponder()
        toggleInteractionBehindPopup(to: false)
    }
    
    func toggleInteractionBehindPopup(to bool: Bool) {
        for button in buttons {
            button.isUserInteractionEnabled = bool
        }
        doneButton.isUserInteractionEnabled = bool
    }
    
    @IBAction func onTransferDone() {
        guard let transferAmountString = transferAmountField.text else {return}
        guard var transferAmountDouble = Double(transferAmountString) else {return}
        
        // Don't let user transfer more money than they have in their account
        if transferAmountDouble > self.amount {
            transferAmountDouble = self.amount
        }
        
        let selectedAccount = pickerOptions[accountPicker.selectedRow(inComponent: 0)]
        guard let selectedAccountIndexInWallet = walletContainingAccount.accounts.firstIndex (where: { $0.ID == selectedAccount.ID }) else {return}
        
        transferAmountField.resignFirstResponder()
        UIApplication.shared.beginIgnoringInteractionEvents()
        Api.transfer(wallet: self.walletContainingAccount, fromAccountAt: self.indexInWallet, toAccountAt: selectedAccountIndexInWallet, amount: transferAmountDouble, completion: { (response, error) in
                if error == nil {
                    self.homeViewDelegate?.accountsUpdated()
                    self.amount -= transferAmountDouble
                    self.amountLabel.text = "$" + String(format: "%0.02f", self.amount)
                    self.transferPopup.isHidden = true
                    self.toggleInteractionBehindPopup(to: true)
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
        })
    }
    
    @IBAction func onDelete() {
        Api.removeAccount(wallet: walletContainingAccount, removeAccountat: indexInWallet, completion: { (_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in
            self.homeViewDelegate?.accountsUpdated()
            self.onDone()
        })
    }
    
    // MARK: PickerView Delegate and DataSource implementations
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(pickerOptions[row].name) $\(String(format: "%0.02f", pickerOptions[row].amount))"
    }
}
