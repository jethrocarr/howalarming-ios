//
//  AlarmEventTableViewController.swift
//  howalarming
//
//  Created by Jethro Carr on 20/02/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON


class AlarmEventTableViewController: UITableViewController {
    
    // MARK: Properties
    var alarmEvents = [AlarmEvent]()
    @IBOutlet weak var armActionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for GCM registration
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // Listen for registration events from AppDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(updateRegistrationStatus), name: Notification.Name(appDelegate.registrationKey), object: nil)

        // Listen for messages arriving from GCM that require a UI update or display.
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedMessage), name: Notification.Name(appDelegate.messageKey), object: nil)

        // Load the saved state
        if let savedAlarmEvents = loadAlarmEvents() {
            alarmEvents += savedAlarmEvents
        }
    }
    
    deinit {
        // Don't care about your shit anymore AppDelegate!
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Load data at launch
    func loadAlarmEvents() -> [AlarmEvent]? {
        print("Loading saved Alarm Events...")
        return NSKeyedUnarchiver.unarchiveObject(withFile: AlarmEvent.ArchiveURL.path) as? [AlarmEvent]
    }
    
    
    // MARK: Debugging
    func loadSampleEvents() {
        let event1 = AlarmEvent(type: "alarm", code: "666", message: "The alarm is going off, evil is afoot", raw: "666", time: Date(timeIntervalSinceNow: Double(60)) )!
        let event2 = AlarmEvent(type: "armed", code: "051", message: "System is armed, burgulars beware", raw: "051ARM", time: Date(timeIntervalSinceNow: Double(300)) )!
        let event3 = AlarmEvent(type: "disarmed", code: "052", message: "System is disarmed, welcome home", raw: "052DISARM", time: Date(timeIntervalSinceNow: Double(3600)) )!
        let event4 = AlarmEvent(type: "info", code: "000", message: "This is a boring info level update", raw: "000INFO", time: Date(timeIntervalSinceNow: Double(86400)) )!

        let newAlarmEvents = [event1, event2, event3, event4]
        
        for newAlarmEvent in newAlarmEvents {
            let newIndexPath = IndexPath(row: alarmEvents.count, section: 0)
            alarmEvents.append(newAlarmEvent)
            tableView.insertRows(at: [newIndexPath], with: .bottom)
        }
    }
    
    
    // MARK: GCM Registration. Since we are using selectors, need to annotate with objc
    @objc
    func updateRegistrationStatus(notification: Notification) {
        
        if let info = notification.userInfo as? Dictionary<String,String> {
            if let error = info["error"] {
                
                if error == "REMOTE_NOTIFICATION_SIMULATOR_NOT_SUPPORTED_NSERROR_DESCRIPTION" {
                    // No FCM in the simulator, so load some sample data.
                    // TODO: Need to write an event simulator
                    loadSampleEvents()
                }
                
                showAlert(title: "Error registering with FCM", message: error)
                
            } else if let _ = info["registrationToken"] {
                print("Registration with FCM was successful");
            } else {
                print ("Software failure. Guru meditation.")
            }
        } else {
            print("Software failure. Guru meditation.")
        }
    }
    
    
    // MARK: Recieve new alert. Since we are using selectors, need to annotate with objc
    @objc
    func handleReceivedMessage(notification: Notification) {
        
        let event = JSON(notification.userInfo!)
        
        if (event["raw"] == "HOWALARMING") {
            // The one type of message we shouldn't display to the user.
            print("Status message recieved from HowAlarming server. Silent information update.");
        } else {
            // Add event to the table of events for display
            let eventTime = Date(timeIntervalSince1970:Double(event["timestamp"].stringValue)!)
            let newAlarmEvent = AlarmEvent(type: event["type"].stringValue, code: event["code"].stringValue, message: event["message"].stringValue, raw: event["raw"].stringValue, time: eventTime)!
            let newIndexPath = IndexPath(row: 0, section: 0)
            alarmEvents.insert(newAlarmEvent, at: 0)
            tableView.insertRows(at: [newIndexPath], with: .top)
            
            // Save events to persistent store
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(alarmEvents, toFile: AlarmEvent.ArchiveURL.path)
            if !isSuccessfulSave {
                print("Unable to save latest AlarmEvent data to storage")
            }
            
            // Apply max size constraints on the table
            if (alarmEvents.count > 50) {
                print("Truncating max length event table...")
                let lastIndexInt = alarmEvents.endIndex - 1
                let lastIndexPath = IndexPath(row: lastIndexInt, section: 0)
                alarmEvents.removeLast()
                tableView.deleteRows(at: [lastIndexPath], with: .bottom)
            }
        }
        
        
        // Perform specific actions for different alarm types
        // TODO: messy, need to move appDelegate to constructor
        switch event["type"].stringValue {
            case "alarm":
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.stateArmed = appDelegate.alarmStateArmed
                
                armActionButton.title = "Disarm"
                armActionButton.isEnabled = true
            break
            
            case "armed":
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.stateArmed = appDelegate.alarmStateArmed
            
                armActionButton.title = "Disarm"
                armActionButton.isEnabled = true
            break
            
            case "disarmed":
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.stateArmed = appDelegate.alarmStateDisarmed
                
                armActionButton.title = "Arm"
                armActionButton.isEnabled = true
            break

            default:
            break
            
        }
        
        
        // Change the title colour in certain conditions (eg alarming)
        // TODO: Want to get transparency or gradiant working.
        
        if event["type"].stringValue == "alarm" {
            self.navigationController!.navigationBar.barTintColor = UIColor.init(red: (255/255.0), green: (0/255.0), blue: (0/255.0), alpha: 1.0)
        } else {
            self.navigationController!.navigationBar.barTintColor = nil
        }
    }
    
    func showAlert(title:String, message:String) {
        
        // TODO: There is a bug here, we clobber one alert with another if it already exists. It seems to work, but iOS tells
        // us off for attending to load one view whilst it's already deallocating and this could cause unexpected fun. A better
        // option is probably to ditch the nastiness of alerts and instead use the table cells for messages.
        
        print("Showing Alert: " + title + " : " + message)
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Perform user arm/disarm actions
    @IBAction func armActionButton(_ sender: Any) {

        // Disable the button. We've issued a command and we don't want repeat action... once the command is executed,
        // the server will send back an armed/disarmed event, which will result in the UI being updated and the button
        // being re-enabled.
        armActionButton.isEnabled = false

        // We perform the arm/disarm by checking the state and selecting the appropiate action
        // and sending an command upstream via FCM to the HowAlarming server.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        var command: String
        
        switch (appDelegate.stateArmed) {
            case appDelegate.alarmStateUnknown:
                command = "disarm"
            break

            case appDelegate.alarmStateDisarmed:
                command = "arm"
            break
            
            case appDelegate.alarmStateArmed:
                command = "disarm"
            break
            
            default:
                command = "disarm"
            break
        }
        
        if (Messaging.messaging().isDirectChannelEstablished) {
            let messageId = ProcessInfo.processInfo.globallyUniqueString
            
            let messageData: [String: Any] = [
                "registration_token": appDelegate.registrationToken!,
                "command": command,
                "timestamp": String( Date().timeIntervalSince1970 / 1000 )
            ]
            let messageTo: String = appDelegate.gcmSenderID! + "@gcm.googleapis.com"
            let ttl: Int64 = 3600 // Assume this is seconds? No fucking idea, thanks Google Firebase docs!
            
            print("Sending \(command) action to FCM upstream FCM server: \(messageTo)")
            
            Messaging.messaging().sendMessage(messageData, to: messageTo, withMessageID: messageId, timeToLive: ttl)
            
        } else {
            print("Warning: Unable to send upstream fCM message due to direct connection not being established")
        }
    }
    
    
    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarmEvents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Table view cells are reused and should be dequeued using an identifier
        let cellIdentifier = "AlarmEventTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AlarmEventTableViewCell
        
        // Fetch appropiate alarm event for data source layout
        let alarmEvent = alarmEvents[indexPath.row]
        
        cell.typeLabel.text = alarmEvent.type
        cell.messageLabel.text = alarmEvent.message
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.medium
        dateFormatter.doesRelativeDateFormatting = true
        cell.timeLabel.text = dateFormatter.string(from: alarmEvent.time)

        return cell
    }
    
    
}
