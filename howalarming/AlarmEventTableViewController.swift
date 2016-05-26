//
//  AlarmEventTableViewController.swift
//  howalarming
//
//  Created by Jethro Carr on 20/02/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import UIKit
import Google
import SwiftyJSON

class AlarmEventTableViewController: UITableViewController {
    
    // MARK: Properties
    var alarmEvents = [AlarmEvent]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for GCM registration
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateRegistrationStatus(_:)),
            name: appDelegate.registrationKey, object: nil)
        
        // Listen for GCM messages being recieved
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleReceivedMessage(_:)),
            name: appDelegate.messageKey, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: Debugging
    func loadSampleEvents() {
        let event1 = AlarmEvent(type: "alarm", code: "666", message: "The alarm is going off, evil is afoot", raw: "666", time: NSDate(timeIntervalSinceNow: Double(60)) )!
        let event2 = AlarmEvent(type: "armed", code: "051", message: "System is armed, burgulars beware", raw: "051ARM", time: NSDate(timeIntervalSinceNow: Double(300)) )!
        let event3 = AlarmEvent(type: "disarmed", code: "052", message: "System is disarmed, welcome home", raw: "052DISARM", time: NSDate(timeIntervalSinceNow: Double(3600)) )!
        let event4 = AlarmEvent(type: "info", code: "000", message: "This is a boring info level update", raw: "000INFO", time: NSDate(timeIntervalSinceNow: Double(86400)) )!

        let newAlarmEvents = [event1, event2, event3, event4]
        
        for newAlarmEvent in newAlarmEvents {
            let newIndexPath = NSIndexPath(forRow: alarmEvents.count, inSection: 0)
            alarmEvents.append(newAlarmEvent)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
        }
    }
    
    
    // MARK: GCM Registration
    func updateRegistrationStatus(notification: NSNotification) {
        
        if let info = notification.userInfo as? Dictionary<String,String> {
            if let error = info["error"] {
                
                if error == "REMOTE_NOTIFICATION_SIMULATOR_NOT_SUPPORTED_NSERROR_DESCRIPTION" {
                    // No GCM in the simulator, so load some sample data.
                    // TODO: Need to write an event simulator
                    loadSampleEvents()
                }
                
                showAlert("Error registering with GCM", message: error)
                
            } else if let _ = info["registrationToken"] {
                let message = "Check the xcode debug console for the registration token that you " +
                " can use with the demo server to send notifications to your device"
                showAlert("Registration Successful!", message: message)
                
            } else {
                print ("Software failure. Guru meditation.")
            }
        } else {
            print("Software failure. Guru meditation.")
        }
    }
    
    
    // MARK: Recieve new alert
    func handleReceivedMessage(notification: NSNotification) {
        
        let event = JSON(notification.userInfo!)
        
        // Add event to list
        let eventTime = NSDate(timeIntervalSince1970:Double(event["timestamp"].stringValue)!)
        let newAlarmEvent = AlarmEvent(type: event["type"].stringValue, code: event["code"].stringValue, message: event["message"].stringValue, raw: event["raw"].stringValue, time: eventTime)!
//        let newIndexPath = NSIndexPath(forRow: alarmEvents.count, inSection: 0)
        let newIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        alarmEvents.insert(newAlarmEvent, atIndex: 0)
        tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
        
        
        // Change the title colour in certain conditions (eg alarming)
        // TODO: Want to get transparency or gradiant working.
        
        if event["type"].stringValue == "alarm" {
            self.navigationController!.navigationBar.barTintColor = UIColor.init(colorLiteralRed: (255/255.0), green: (0/255.0), blue: (0/255.0), alpha: 1.0)
        } else {
            self.navigationController!.navigationBar.barTintColor = nil
        }
    }
    
    func showAlert(title:String, message:String) {
        
        // TODO: There is a bug here, we clobber one alert with another if it already exists. It seems to work, but iOS tells
        // us off for attending to load one view whilst it's already deallocating and this could cause unexpected fun. A better
        // option is probably to ditch the nastiness of alerts and instead use the table cells for messages.
        
        print("Showing Alert: " + title + " : " + message)
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Destructive, handler: nil)
        alert.addAction(dismissAction)
        self.presentViewController(alert, animated: true, completion: nil)
 
    }
    
    
    // MARK: Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarmEvents.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using an identifier
        let cellIdentifier = "AlarmEventTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! AlarmEventTableViewCell
        
        
        // Fetch appropiate alarm event for data source layout
        let alarmEvent = alarmEvents[indexPath.row]
        
        cell.typeLabel.text = alarmEvent.type
        cell.messageLabel.text = alarmEvent.message
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.doesRelativeDateFormatting = true
        cell.timeLabel.text = dateFormatter.stringFromDate(alarmEvent.time)

        return cell
    }
    
    
}