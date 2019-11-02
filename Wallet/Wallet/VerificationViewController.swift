//
//  VerificationViewController.swift
//  Wallet
//
//  Created by Elias Heffan on 10/13/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

class VerificationViewController: UIViewController, PinTextFieldDelegate {
   
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet var verificationCodeFieldsOptional: Array<PinTextField>?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var tapGesture = UITapGestureRecognizer()
    
    var phoneNumber: String = "" // but variable should be overwritten with the value passed through segue by LoginViewController
    var verificationCodeFields: Array<PinTextField> = []
    var tagOfCurrentField = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        unwrapAndSortVerificationCodeFieldsOptional()
        disableTextFieldsBesidesFirstOne()
        setupTextFieldDelegates()
        initUI()
        setupKeyboardActions()
    }
        
    func unwrapAndSortVerificationCodeFieldsOptional() {
        guard let verificationCodeFieldsTemp = verificationCodeFieldsOptional else {
            return
        }
        verificationCodeFields = verificationCodeFieldsTemp
        
        verificationCodeFields.sort { $0.tag < $1.tag }
    }

    func disableTextFieldsBesidesFirstOne() {
        for textField in verificationCodeFields {
            if (textField.tag != 0) {
                textField.isUserInteractionEnabled = false
            } else {
                textField.isUserInteractionEnabled = true
            }
        }
    }
    
    func setupTextFieldDelegates() {
        for textField in verificationCodeFields {
            textField.delegate = self
        }
    }

    func initUI() {
        phoneNumberLabel.text = "Enter the code sent to \(phoneNumber)"
        resendButton.layer.cornerRadius = resendButton.frame.height / 2
    }
        
    func setupKeyboardActions() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        verificationCodeFields[0].becomeFirstResponder()
    }
    
    @objc func dismissKeyboard() {
        verificationCodeFields[tagOfCurrentField].resignFirstResponder()
    }
        
    @IBAction func onDigitEntry() {
        if (tagOfCurrentField != 5) {
            switchToFieldWith(tag: tagOfCurrentField + 1)
        } else {
            checkVerificationCode()
        }
    }
    
    func switchToFieldWith(tag: Int) {
        let currentField = verificationCodeFields[tagOfCurrentField]
        currentField.isUserInteractionEnabled = false
        currentField.resignFirstResponder()
        
        let nextField = verificationCodeFields[tag]
        nextField.text = "" // Clear text of field in case the user is editting a field they have already entered
        nextField.isUserInteractionEnabled = true
        nextField.becomeFirstResponder()
        
        tagOfCurrentField = tag
    }
    
    func checkVerificationCode() {
        var verificationCode = ""
        for textField in verificationCodeFields {
            if let character = textField.text {
                verificationCode += character
            }
        }
        UIApplication.shared.beginIgnoringInteractionEvents()
        activityIndicator.startAnimating()
        Api.verifyCode(phoneNumber: phoneNumber, code: verificationCode) { response, error in
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if (error != nil) {
                self.errorLabel.text = error?.message ?? "An unknown error occurred when verifying code"
                self.errorLabel.textColor = .red
                self.clearFields()
            } else {
                self.errorLabel.text = ""
                Storage.phoneNumberInE164 = self.phoneNumber
                if let authToken = response?["auth_token"] as? String {
                    Storage.authToken = authToken
                }
                self.goToHomeView()
            }
        }
    }
    
    func clearFields() {
        disableTextFieldsBesidesFirstOne()
        for textField in verificationCodeFields {
            textField.text = ""
        }
        tagOfCurrentField = 0
        verificationCodeFields[0].becomeFirstResponder()
    }
        
    func goToHomeView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //It is ok here to use the ! below, since we would always want the app to crash if for some reason we couldn't switch to the HomeView
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeView") as! HomeViewController
        homeVC.modalPresentationStyle = .fullScreen
        self.present(homeVC, animated: true, completion: nil)
    }

    @IBAction func resend() {
        clearFields()
        UIApplication.shared.beginIgnoringInteractionEvents()
        activityIndicator.startAnimating()
        Api.sendVerificationCode(phoneNumber: phoneNumber) { response, error in
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if (error != nil) {
                self.errorLabel.text = error?.message ?? "An unknown error occurred when sending verification code"
                self.errorLabel.textColor = .red
            } else {
                self.errorLabel.text = "Resent verification code"
                self.errorLabel.textColor = .green
                
            }
        }
    }
    
    // MARK: PinTextField protocol implementation
    func didPressBackspace(textField: PinTextField) {
        if tagOfCurrentField != 0 {
            switchToFieldWith(tag: tagOfCurrentField - 1)
        }
    }
}
