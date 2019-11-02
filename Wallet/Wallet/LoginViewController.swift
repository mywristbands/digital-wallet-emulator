//
//  ViewController.swift
//  Wallet
//
//  Created by Weisu Yin on 9/29/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit
import PhoneNumberKit

class LoginViewController: UIViewController {

    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var numberTextField: PhoneNumberTextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var tapGesture = UITapGestureRecognizer()
    let phoneNumberKit = PhoneNumberKit()
    
    var phoneNumber: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setupKeyboardActions()
    }
    
    func initUI() {
        countryTextField.isUserInteractionEnabled = false
        sendButton.layer.cornerRadius = sendButton.frame.height / 2
        errorLabel.numberOfLines = 0
        if Storage.phoneNumberInE164 != "" {
            fillFieldWithPreviousPhoneNumber()
        }
    }
    
    func fillFieldWithPreviousPhoneNumber() {
        // PhoneNumberKit will automatically format text field
        numberTextField.text = Storage.phoneNumberInE164
        
        // However, we still need to remove the "+1 " from the phone number
        guard let phoneNumber = numberTextField.text else { return }
        
        let startIndex = phoneNumber.startIndex
        let newStartIndex = phoneNumber.index(startIndex, offsetBy: 3)
        let phoneNumberWithoutCountryCode = phoneNumber[newStartIndex...]
        
        numberTextField.setTextUnformatted(newValue: String(phoneNumberWithoutCountryCode))
    }
    
    func setupKeyboardActions() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        numberTextField.becomeFirstResponder()
    }
    
    @objc func dismissKeyboard() {
        numberTextField.resignFirstResponder()
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        let phoneNumber = numberTextField.text?.filter { $0 >= "0" && $0 <= "9" } ?? ""
        if phoneNumber.count == 0 {
            errorLabel.text = "Please enter your phone number."
        } else if phoneNumber.count != 10 {
            errorLabel.text = "The phone number should be 10 digits."
        } else {
            do {
                let parsedPhoneNumber = try phoneNumberKit.parse(numberTextField.text ?? "")
                self.phoneNumber = phoneNumberKit.format(parsedPhoneNumber, toType: .e164)
                errorLabel.text = ""
                dismissKeyboard()
                UIApplication.shared.beginIgnoringInteractionEvents()
                activityIndicator.startAnimating()
                switchViews()
            }
            catch {
                errorLabel.text = "Please enter a valid phone number"
            }
        }
    }
    
    func switchViews() {
        if Storage.authToken != nil, Storage.phoneNumberInE164 ==
            phoneNumber {
            // This user is the last successfully logged in user.
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            goToHomeView()
        } else {
            Api.sendVerificationCode(phoneNumber: phoneNumber) { response, error in
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                if (error != nil) {
                    self.errorLabel.text = error?.message ?? "An unknown error occurred when sending verification code"
                } else {
                    self.goToVerificationView()
                }
            }
        }
    }
    
    func goToHomeView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //It is ok here to use the ! below, since we would always want the app to crash if for some reason we couldn't switch to the HomeView
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeView") as! HomeViewController
        homeVC.modalPresentationStyle = .fullScreen
        self.present(homeVC, animated: true, completion: nil)
    }
    
    func goToVerificationView() {
        performSegue(withIdentifier: "goToVerificationView", sender: self)
    }
    
    // Define what variables to pass to VerificationViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let viewController = segue.destination as? VerificationViewController
        {
            viewController.phoneNumber = phoneNumber
        }
    }

}

