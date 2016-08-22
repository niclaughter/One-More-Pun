//
//  LoginTableViewController.swift
//  One More Pun
//
//  Created by Nicholas Laughter on 8/16/16.
//  Copyright © 2016 Areios. All rights reserved.
//

import UIKit

class LoginTableViewController: UITableViewController, UITextFieldDelegate {
    
    let colorCollection = ColorCollection()
    var backgroundColor: UIColor = .whiteColor()
    var hasAccount: Bool = true {
        didSet {
            userHasAccount()
        }
    }
    
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var haveAccountButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var retypePasswordTextField: UITextField!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var goWithoutSignupLoginButton: UIButton!
    
    @IBAction func screenTapped(sender: AnyObject) {
        resignFirstResponders()
    }
    
    @IBAction func haveAccountButtonTapped(sender: AnyObject) {
        hasAccount = !hasAccount
    }
    
    @IBAction func goButtonTapped(sender: AnyObject) {
        if !hasAccount && passwordTextField.text == retypePasswordTextField.text {
            guard let email = emailTextField.text,
                password = passwordTextField.text,
                name = nameTextField.text else { return }
            UserController.shared.createUser(email, password: password, name: name, completion: { (_, error) in
                if let error = error {
                    self.showErrorInFormAlert(error.localizedDescription)
                } else {
                    self.checkPuns({
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
            })
        } else if !hasAccount {
            showMismatchedPasswordsAlert()
        } else {
            guard let email = emailTextField.text,
                password = passwordTextField.text else { return }
            UserController.shared.signInUser(email, password: password, completion: { (_, error) in
                if let error = error {
                    self.showErrorInFormAlert(error.localizedDescription)
                } else {
                    self.checkPuns({
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
            })
        }
    }
    
    @IBAction func goWithoutSignupLoginButtonTapped(sender: AnyObject) {
        goWithoutSignupLogin()
    }
    
    func checkPuns(completion: () -> Void) {
        PunController.shared.observePuns { (puns) in
            PunController.shared.punsArray = puns
            completion()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundColor = colorCollection.randomColor()
        view.backgroundColor = backgroundColor
        setButtonAttributes([haveAccountButton, goButton, goWithoutSignupLoginButton])
        userHasAccount()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            if hasAccount {
                textField.resignFirstResponder()
            } else {
                retypePasswordTextField.becomeFirstResponder()
            }
        case retypePasswordTextField:
            textField.resignFirstResponder()
        default:
            resignFirstResponders()
        }
        return true
    }
    
    func resignFirstResponders() {
        nameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        retypePasswordTextField.resignFirstResponder()
    }
    
    func userHasAccount() {
        if hasAccount {
            signInLabel.text = "Log in"
            haveAccountButton.setTitle("Don't have an account?", forState: .Normal)
        } else {
            signInLabel.text = "Sign up"
            haveAccountButton.setTitle("Already have an account?", forState: .Normal)
            passwordTextField.returnKeyType = .Next
        }
        nameTextField.hidden = hasAccount
        retypePasswordTextField.hidden = hasAccount
    }
    
    func setButtonAttributes(buttons: [UIButton]) {
        for button in buttons {
            button.tintColor = backgroundColor
            button.layer.cornerRadius = 11
            button.clipsToBounds = true
            button.backgroundColor = UIColor.whiteColor()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = backgroundColor
        cell.selectionStyle = .None
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let destinationVC = segue.destinationViewController as? ViewController else { return }
        destinationVC.checkUserAndReloadData()
    }
    
    
    // MARK: - AlertController
    
    func showMismatchedPasswordsAlert() {
        let alert = UIAlertController(title: "Passwords Don't Match", message: "Please make sure the password is the same in both fields.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default) { (_) in
            self.passwordTextField.text = nil
            self.retypePasswordTextField.text = nil
            self.passwordTextField.becomeFirstResponder()
        }
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showErrorInFormAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: "Something's not right:\n\(message).", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func goWithoutSignupLogin() {
        let alert = UIAlertController(title: "Enter without signing in?", message: "You will be able to use the app to see puns but won't be able to submit or report any. You will have the choice to sign up in the future.", preferredStyle: .Alert)
        let agreeAction = UIAlertAction(title: "That's fine, let's see some puns!", style: .Default) { (_) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(agreeAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
}
