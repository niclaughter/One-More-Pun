//
//  ViewController.swift
//  One More Pun
//
//  Created by Nicholas Laughter on 12/6/15.
//  Copyright © 2015 Areios. All rights reserved.
//

import UIKit
import MessageUI
import Firebase



class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let colorCollection = ColorCollection()
    var pun = Pun(body: "")
    var color = UIColor()
    var punsReadCount = 0 {
        didSet {
            if punsReadCount >= PunController.shared.punsArray.count {
                presentEndOfPunsAlert()
            }
        }
    }
    
    var retrievingFromNetwork: Bool = false {
        didSet {
            UIApplication.shared.isNetworkActivityIndicatorVisible = retrievingFromNetwork
        }
    }
    
    func printFonts() {
        for familyName in UIFont.familyNames {
            print("\n-- \(familyName) \n")
            for fontName in UIFont.fontNames(forFamilyName: familyName) {
                print(fontName)
            }
        }
    }
    
    @IBOutlet weak var punLabel: UILabel!
    @IBOutlet weak var submitterLabel: UILabel!
    @IBOutlet weak var punButtonColor: UIButton!
    @IBOutlet weak var infoButtonColor: UIButton!
    @IBOutlet weak var addPunButtonColor: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        printFonts()
        
        UserController.shared.getLoggedInUser { (user) in
            if user == nil {
                self.showLoginSignUpView()
            }
        }
        
        checkUserAndReloadData()
        
        infoButtonColor.isHidden = true
        addPunButtonColor.isHidden = true
        
        let rate = RateMyApp.sharedInstance
        rate.appID = "1008575898"
        DispatchQueue.main.async(execute: { () -> Void in
            rate.trackAppUsage()
        })
        
        getNewPunAndColor()
    }
    
    // MARK: - Pun Info Options
    
    @IBAction func infoButtonTapped(_ sender: AnyObject) {
        showPunInfoActionSheet()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getNewPunAndColor()
    }
    
    func checkUserAndReloadData() {
        checkIfCurrentUserIsNil({ 
            UserController.shared.checkUserAgainstDatabase { (success, error) -> Void in
                if success {
                    self.observePuns()
                } else {
                    guard let error = error else { return }
                    self.presentErrorAlert(error.localizedDescription, completion: {
                        self.showLoginSignUpView()
                    })
                }
            }
        }) {
            self.observePuns()
        }
    }
    
    func observePuns() {
        self.punLabel.text = "Fetching puns..."
        PunController.shared.observePuns { (puns) in
            self.retrievingFromNetwork = true
            PunController.shared.punsArray = puns
            DispatchQueue.main.async(execute: {
                self.retrievingFromNetwork = false
                self.getNewPunAndColor()
            })
        }
    }
    
    func showLoginSignUpView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginTableViewController else { return }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func nextPunButton(_ sender: AnyObject) {
        getNewPunAndColor()
        punsReadCount += 1
    }
    
    @IBAction func addPunButtonTapped(_ sender: AnyObject) {
        checkIfCurrentUserIsNil({ 
            self.presentSubmitPunAlert(nil)
            }) { 
                self.presentNoAccountAlert()
        }
    }
    
    func getNewPunAndColor() {
        pun = PunController.shared.randomPun()
        setUpColor()
        punLabel.text = pun.body
        submitterLabel.text = submitterLabelText(pun)
    }
    
    func setUpColor() {
        color = colorCollection.randomColor()
        view.backgroundColor = color
        punButtonColor.tintColor = color
        infoButtonColor.isHidden = false
        infoButtonColor.tintColor = color
        addPunButtonColor.isHidden = false
        addPunButtonColor.tintColor = color
    }
    
    func submitterLabelText(_ pun: Pun) -> String {
        if let submitter = pun.submitter {
            return "Submitted by \(submitter)"
        } else {
            return ""
        }
    }
    
    func checkIfCurrentUserIsNil(_ ifNotNil: () -> Void, ifNil: () -> Void) {
        if FIRAuth.auth()?.currentUser != nil {
            ifNotNil()
        } else {
            ifNil()
        }
    }
    
    // MARK: - AlertController
    
    func presentSubmitPunAlert(_ storedPun: String?) {
        let alert = UIAlertController(title: "Got a pun?", message: "Submitting puns is punderful.", preferredStyle: .alert)
        alert.addTextField { (punTextField) in
            punTextField.placeholder = "Enter pun here"
            punTextField.text = storedPun
            punTextField.autocorrectionType = .yes
            punTextField.autocapitalizationType = .sentences
            punTextField.spellCheckingType = .yes
        }
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            guard let textFields = alert.textFields,
                let punTextField = textFields.first,
                let punText = punTextField.text, !punText.isEmpty else { return }
            self.presentSubmitPunConfirmationAlert(punText)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentSubmitPunConfirmationAlert(_ punBody: String) {
        let alert = UIAlertController(title: "All done?", message: "Be sure to check spelling and grammar! Here's how it looks:\n\(punBody)", preferredStyle: .alert)
        let submitAction = UIAlertAction(title: "Looks good!", style: .default) { (_) in
            PunController.shared.createPun(punBody)
        }
        let reEnterAction = UIAlertAction(title: "Re-enter", style: .destructive) { (_) in
            self.presentSubmitPunAlert(punBody)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(submitAction)
        alert.addAction(reEnterAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentErrorAlert(_ error: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) in
            if let completion = completion {
                completion()
            }
        }
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentEndOfPunsAlert() {
        let alert = UIAlertController(title: "You're about to run out of puns!", message: "One More Pun only works if people like you submit puns! Tap the + to add one!", preferredStyle: .alert)
        let submitAction = UIAlertAction(title: "Let's go!", style: .default) { (_) in
            self.punsReadCount = 0
            self.presentSubmitPunAlert(nil)
        }
        let cancelAction = UIAlertAction(title: "No thanks", style: .cancel) { (_) in
            self.punsReadCount = 0
        }
        alert.addAction(submitAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showPunInfoActionSheet() {
        let actionSheet = UIAlertController(title: "", message: "Options", preferredStyle: .actionSheet)
        let shareAction = UIAlertAction(title: "Share Pun", style: .default) { (_) in
            self.share()
        }
        let googleAction = UIAlertAction(title: "Don't get it?", style: .default) { (_) in
            self.openGoogleForPun()
        }
        let reportAction = UIAlertAction(title: "Report", style: .default) { (_) in
            self.checkIfCurrentUserIsNil({
                self.presentReportPunAlert()
                }, ifNil: { 
                    self.presentNoAccountAlert()
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(shareAction)
        actionSheet.addAction(googleAction)
        actionSheet.addAction(reportAction)
        actionSheet.addAction(cancelAction)
        present(actionSheet, animated: true, completion: nil)
    }
    
    func share() {
        let items = PunController.shared.getItemsToShare(pun, color: color)
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.copyToPasteboard, UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.assignToContact, UIActivityType.postToTencentWeibo, UIActivityType.postToVimeo, UIActivityType.print, UIActivityType.postToWeibo]
        present(activityViewController, animated: true, completion: nil)
    }
    
    func openGoogleForPun() {
        let replaced = pun.body.replacingOccurrences(of: " ", with: "+")
        if let url = URL(string: "http://lmgtfy.com/?q=\(replaced)") {
            UIApplication.shared.openURL(url)
        }
    }
    
    func presentReportPunAlert() {
        let alert = UIAlertController(title: "Report pun?", message: "Only use this feature if you want to report this pun as inappropriate or not a real pun.", preferredStyle: .alert)
        let reportAction = UIAlertAction(title: "Report", style: .destructive) { (_) in
            PunController.shared.reportPun(self.pun)
            self.presentPunReportedConfirmation()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(reportAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentPunReportedConfirmation() {
        let alert = UIAlertController(title: "Pun Reported", message: "Your complaint has been recorded. Thank you for keeping One More Pun awesome!", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    func presentNoAccountAlert() {
        let alert = UIAlertController(title: "Oops!", message: "Looks like you don't have an account. Please sign up or log in to use this feature.", preferredStyle: .alert)
        let signupLoginAction = UIAlertAction(title: "Sign up or login", style: .default) { (_) in
            self.showLoginSignUpView()
        }
        let cancelAction = UIAlertAction(title: "Never mind", style: .cancel, handler: nil)
        alert.addAction(signupLoginAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}
