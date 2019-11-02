//
//  HomeViewController.swift
//  Wallet
//
//  Created by Elias Heffan on 10/23/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var greeting: UILabel!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var totalAmount: UILabel!
    @IBOutlet weak var accountsTable: UITableView!
    
    var wallet = Wallet.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountsTable.dataSource = self
        
        // Get user info, then load user's info into wallet and setup view
        Api.user(completion: {(_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in
            if let responseUnwrapped = response {
                self.wallet = Wallet.init(data: responseUnwrapped, ifGenerateAccounts: true)
                self.displayUsername()
                self.totalAmount.text = "Your Total Amount: $" + String(format: "%0.02f", self.wallet.totalAmount)
                self.accountsTable.reloadData()
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
        if sender.state == .ended {
            userNameField.resignFirstResponder()
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
}
