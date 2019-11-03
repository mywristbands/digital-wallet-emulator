//
//  AccountViewController.swift
//  Wallet
//
//  Created by Elias Heffan on 11/2/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
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
    }
    
    @IBAction func onDone() {
        performSegue(withIdentifier: "goToHomeView", sender: self)
    }

}
