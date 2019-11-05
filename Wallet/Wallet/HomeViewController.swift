//
//  HomeViewController.swift
//  Wallet
//
//  Created by Elias Heffan on 10/23/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UpdateHomeViewControllerDelegate {

    @IBOutlet weak var greeting: UILabel!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var totalAmount: UILabel!
    @IBOutlet weak var accountsTable: UITableView!
    
    @IBOutlet weak var newAccountPopup: UIView!
    @IBOutlet weak var newAccountField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    var wallet = Wallet.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountsTable.dataSource = self
        accountsTable.delegate = self
        
        getUserInfoIntoView()
    }
    
    func getUserInfoIntoView() {
        Api.user(completion: {(_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in
            if let responseUnwrapped = response {
                self.wallet = Wallet.init(data: responseUnwrapped, ifGenerateAccounts: false)
                self.displayUsername()
                self.totalAmount.text = "Your Total Amount: $" + String(format: "%0.02f", self.wallet.totalAmount)
                self.accountsTable.reloadData()
                self.setupPopup()
            }
        })
    }
    
    // If username is nil or an empty string, display phone number instead
    func displayUsername() {
        if wallet.userName == nil || wallet.userName == Optional("") {
            userNameField.text = wallet.phoneNumber
        } else {
            userNameField.text = wallet.userName
        }
    }

    func setupPopup() {
        newAccountPopup.layer.shadowColor = UIColor.darkGray.cgColor
        newAccountPopup.layer.shadowOpacity = 0.7
        newAccountPopup.layer.shadowOffset = CGSize(width: 3, height: 3)
        newAccountPopup.layer.shadowRadius = 15.0
        newAccountPopup.layer.masksToBounds = false
        
        newAccountPopup.isHidden = true
        newAccountPopup.layer.cornerRadius = newAccountPopup.frame.height / 10
        
        setPlaceholderText()
        
        doneButton.layer.cornerRadius = doneButton.frame.height / 2
    }
    func setPlaceholderText() {
        func isValid(_ accountNumber: Int) -> Bool {
            for account in wallet.accounts {
                if account.name == "Account \(accountNumber)" {
                    return false
                }
            }
            return true
        }
        
        var potentialNewAccountNumber = 1
        while (true) {
            if(isValid(potentialNewAccountNumber)) {
                break
            }
            potentialNewAccountNumber += 1
        }
        newAccountField.placeholder = "Account \(potentialNewAccountNumber)"
    }
    
    @IBAction func onUpdateUserName() {
        wallet.userName = userNameField.text
        displayUsername() // basically just displays the phone number if the user deletes their username

        guard let name = wallet.userName else {
            return
        }
        Api.setName(name: name) {(_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in }
    }
    
    // Closes the keyboard upon tapping anywhere on the screen
    @IBAction func onTapAnywhere(_ sender: UITapGestureRecognizer) {
        sender.delegate = self
        if sender.state == .ended {
            userNameField.resignFirstResponder()
        }
    }
    
    @IBAction func onAddAccount(_ sender: Any) {
        newAccountPopup.isHidden = false
        newAccountField.becomeFirstResponder()
    }
    
    @IBAction func onDone() {
        var newAccountName:String = ""
        
        if let defaultAccountName = newAccountField.placeholder {
            newAccountName = defaultAccountName
        }
        if let enteredAccountName = newAccountField.text {
            if (enteredAccountName != "") {
                newAccountName = enteredAccountName
            }
        }
        
        newAccountField.resignFirstResponder()
        UIApplication.shared.beginIgnoringInteractionEvents()
        Api.addNewAccount(wallet: wallet, newAccountName: newAccountName) {(_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in
            if error == nil {
                self.getUserInfoIntoView()
                self.newAccountPopup.isHidden = true
                self.newAccountField.text = "" //Reset field for next time
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        }
    }
    
    @IBAction func onLogout(_ sender: Any) {
        goToLoginView()
    }
    
    func goToLoginView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //It is ok here to use the ! below, since we would always want the app to crash if for some reason we couldn't switch to the LoginView
        let navigationC = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        navigationC.modalPresentationStyle = .fullScreen
        self.present(navigationC, animated: true, completion: nil)
    }
    
    // MARK: UpdateHomeViewControllerDelegate implementation
    func accountsUpdated() {
        getUserInfoIntoView()
    }
    
    // MARK: UIGestureRecognizerDelegate implementation
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Ensures that the UITapGestureRecognizer only recognizes taps in the Home View (not the Table View)
        return touch.view == gestureRecognizer.view
    }

    // MARK: table view data source implementation
    // This function is called by tableView so that it knows how many rows it should have
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallet.accounts.count
    }
    
    // This function is called by tableView to fill in each row (we tell it how many rows there should be based on the above function)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell") ?? UITableViewCell(style: .default, reuseIdentifier: "accountCell")
        let account = self.wallet.accounts[indexPath.row]
        let accountAmount = String(format: "%0.02f", account.amount)
        cell.textLabel?.text = "\(account.name): $\(accountAmount)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentAccount = self.wallet.accounts[indexPath.row]
          
        goToAccountView(of: currentAccount, locatedAt: indexPath.row)
    }
    
    func goToAccountView(of account: Account, locatedAt index: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //It is ok here to use the ! below, since we would always want the app to crash if for some reason we couldn't switch to the LoginView
        let accountVC = storyboard.instantiateViewController(withIdentifier: "AccountView") as! AccountViewController
        accountVC.homeViewDelegate = self //So that Account View can reload Home View
        
        accountVC.modalPresentationStyle = .fullScreen
        accountVC.name = account.name
        accountVC.ID = account.ID
        accountVC.amount = account.amount
        accountVC.walletContainingAccount = wallet
        accountVC.indexInWallet = index
        
        self.present(accountVC, animated: true, completion: nil)
    }
}
