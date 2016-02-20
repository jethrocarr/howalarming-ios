//
//  ViewController.swift
//  howalarming
//
//  Created by Jethro Carr on 20/02/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import UIKit
import Google
import SwiftyJSON

//@objc(ViewController)  // match the ObjC symbol name inside Storyboard
class ViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var registrationProgressing: UIActivityIndicatorView!
    @IBOutlet weak var registeringLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateRegistrationStatus:",
            name: appDelegate.registrationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showReceivedMessage:",
            name: appDelegate.messageKey, object: nil)
        registrationProgressing.hidesWhenStopped = true
        registrationProgressing.startAnimating()
    }
    
    func updateRegistrationStatus(notification: NSNotification) {
        registrationProgressing.stopAnimating()
        if let info = notification.userInfo as? Dictionary<String,String> {
            if let error = info["error"] {
                registeringLabel.text = "Error registering!"
                showAlert("Error registering with GCM", message: error)
            } else if let _ = info["registrationToken"] {
                registeringLabel.text = "Registered!"
                let message = "Check the xcode debug console for the registration token that you " +
                " can use with the demo server to send notifications to your device"
                showAlert("Registration Successful!", message: message)
            }
        } else {
            print("Software failure. Guru meditation.")
        }
    }
    
    func showReceivedMessage(notification: NSNotification) {
        
        let event = JSON(notification.userInfo!)
        
        showAlert("New Message", message: event["message"].stringValue)
    
    }
    
    func showAlert(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Destructive, handler: nil)
        alert.addAction(dismissAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}