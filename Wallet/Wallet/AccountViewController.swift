//
//  AccountViewController.swift
//  Wallet
//
//  Created by Elias Heffan on 11/2/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

//protocol DisplayViewControllerDelegate : NSObjectProtocol{
//    func doSomethingWith(data: String)
//}

class AccountViewController: UIViewController {

    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
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
        amountLabel.text = "$\(amount)"
    }
    
    @IBAction func onDone() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDelete() {
        Api.removeAccount(wallet: walletContainingAccount, removeAccountat: indexInWallet, completion: { (_ response: [String: Any]?, _ error: Api.ApiError?) -> Void in
            self.onDone()
        })
    }
}
