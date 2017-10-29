//
//  AppDelegate.swift
//  howalarming
//
//  Created by Jethro Carr on 20/02/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import UIKit
import UserNotifications
import Google

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GGLInstanceIDDelegate, GCMReceiverDelegate {
    
    var window: UIWindow?
    
    var connectedToGCM = false
    var subscribedToTopic = false
    var gcmSenderID: String?
    var registrationToken: String?
    var registrationOptions = [String: Any]()
    var messagesSent = 0
    
    // We track alarm state in-app, but this also gets push from the server everytime the app view is
    // opened to check the state, since it's possible the app has missed some messages.
    let alarmStateUnknown = 0
    let alarmStateArmed = 1
    let alarmStateDisarmed = 2
    var stateArmed = 0
    
    let registrationKey = "onRegistrationCompleted"
    let messageKey = "onMessageReceived"
    let subscriptionTopic = "/topics/global"
    
    // [START register_for_remote_notifications]
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // [START_EXCLUDE]
        // Configure the Google context: parses the GoogleService-Info.plist, and initializes
        // the services that have entries in the file
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError!)")
        gcmSenderID = GGLContext.sharedInstance().configuration.gcmSenderID
        // [END_EXCLUDE]
        
        // Register for remote notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            //Parse errors and track state
        }
        application.registerForRemoteNotifications()
        // [END register_for_remote_notifications]
        
        // [START start_gcm_service]
        let gcmConfig = GCMConfig.default()!
        gcmConfig.receiverDelegate = self
        GCMService.sharedInstance().start(with: gcmConfig)
        // [END start_gcm_service]
    
        return true
    }
    
    func subscribeToTopic() {
        // If the app has a registration token and is connected to GCM, proceed to subscribe to the topic
        if(registrationToken != nil && connectedToGCM) {
            GCMPubSub.sharedInstance().subscribe(withToken: self.registrationToken, topic: subscriptionTopic,
                options: nil, handler: {(error) -> Void in
                    if (error != nil) {
                        // Treat the "already subscribed" error more gently.
                        // TODO: Is there a smarter way of handling this? Seems to be no code attribute on Swift 4 error object :-(
                        if (error.debugDescription.range(of: "Code=3001") != nil) {
                            print("Already subscribed to the topic, nothing to do");
                        } else {
                            print("Subscription failed: \(error!.localizedDescription)");
                        }
                    } else {
                        self.subscribedToTopic = true;
                        print("Subscribed to \(self.subscriptionTopic)");
                    }
            })
        }
    }
    
    // [START connect_gcm_service]
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Connect to the GCM server to receive non-APNS notifications
        GCMService.sharedInstance().connect(handler: {
            (error) -> Void in
            if error != nil {
                print("Could not connect to GCM: \(error!.localizedDescription)")
                
                // Tell our View Controller about our failure.
                let userInfo = ["error": error!.localizedDescription]
                let notificationName = Notification.Name(self.registrationKey)
                NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
            
            } else {
                self.connectedToGCM = true
                print("Connected to GCM")
                
                self.subscribeToTopic()

                // Send ping to GCM server. This is used to make sure the GCM server is aware of
                // our device and can register it if it's not already done so. Technically, this should
                // live in the registration portion of the application, but as our server is currently
                // not persistent, we ping it on any time the application is opened.
                //
                // The ping also results in a silent status GCM message being sent back advising of
                // the current alarm status (eg armed/disarmed) to assist with maintaining state.
                print("Sending ping message to GCM")
                
                let messageId = ProcessInfo().globallyUniqueString
                let messageData: [String: String] = [
                    "registration_token": self.registrationToken!,
                    "command": "ping",
                    "timestamp": String( Date().timeIntervalSince1970 / 1000 )
                ]
                let messageTo: String = self.gcmSenderID! + "@gcm.googleapis.com"
                
                print("Sending message to GCM:")
                print(messageTo)
                
                GCMService.sharedInstance().sendMessage(messageData, to: messageTo, withId: messageId)
            }
        })

    }
    // [END connect_gcm_service]
    
    // [START disconnect_gcm_service]
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Disconnecting GCM service...")
        
        GCMService.sharedInstance().disconnect()
        self.connectedToGCM = false
    }
    // [END disconnect_gcm_service]
    
    
    // [START receive_apns_token]
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data ) {
        // [END receive_apns_token]
    

        // [START get_gcm_reg_token]
    
        // Create a config and set a delegate that implements the GGLInstaceIDDelegate protocol.
        let instanceIDConfig = GGLInstanceIDConfig.default()!
        instanceIDConfig.delegate = self
    
        // Start the GGLInstanceID shared instance with that config and request a registration
        // token to enable reception of notifications
        GGLInstanceID.sharedInstance().start(with: instanceIDConfig)
            registrationOptions = [
                kGGLInstanceIDRegisterAPNSOption:deviceToken as AnyObject,
                kGGLInstanceIDAPNSServerTypeSandboxOption:true as AnyObject
        ]
        
        GGLInstanceID.sharedInstance().token(withAuthorizedEntity: gcmSenderID, scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
        
        // [END get_gcm_reg_token]
    }
    
    // [START receive_apns_token_error]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error ) {
        print("Registration for remote notification failed with error: \(error.localizedDescription)")
        // [END receive_apns_token_error]
        
        let userInfo = ["error": error.localizedDescription]
        let notificationName = Notification.Name(self.registrationKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }
    
    // [START ack_message_reception]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        print("Remote notification received: \(userInfo)")
        
        // This works only if the app started the GCM service
        GCMService.sharedInstance().appDidReceiveMessage(userInfo);
        
        // Pass the recieved message to the view controller
        let notificationName = Notification.Name(self.messageKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler handler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Remote notification received w/ handler: \(userInfo)")
        
        // This works only if the app started the GCM service
        GCMService.sharedInstance().appDidReceiveMessage(userInfo);
        
        // Handle the received message by passing on to the ViewController.
        let notificationName = Notification.Name(self.messageKey)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
        
        // Invoke the completion handler passing the appropriate UIBackgroundFetchResult value
        handler(UIBackgroundFetchResult.noData);
    }
    // [END ack_message_reception]
    
    func registrationHandler(registrationToken: String!, error: Error!) {
        if (registrationToken != nil) {
            self.registrationToken = registrationToken
            print("Registration Token: \(registrationToken)")
            self.subscribeToTopic()
            let userInfo = ["registrationToken": registrationToken]
            
            // Tell the ViewController that we registered.
            let notificationName = Notification.Name(self.registrationKey)
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
        } else {
            print("Registration to GCM failed with error: \(error.localizedDescription)")
            let userInfo = ["error": error.localizedDescription]
            
            let notificationName = Notification.Name(self.registrationKey)
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
        }
    }
    
    // [START on_token_refresh]
    func onTokenRefresh() {
        // A rotation of the registration tokens is happening, so the app needs to request a new token.
        print("The GCM registration token needs to be changed. :-O")
        GGLInstanceID.sharedInstance().token(withAuthorizedEntity: gcmSenderID, scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
    }
    // [END on_token_refresh]
    
    // [START upstream_callbacks]
    func willSendDataMessage(withID messageID: String!, error: Error!) {
        if (error != nil) {
            // Failed to send the message.
            print ("GCM message failed to send: " + messageID)
        } else {
            // Will send message, you can save the messageID to track the message
            print ("GCM message pending delivery: " + messageID)
        }
    }
    
    func didSendDataMessage(withID messageID: String!) {
        // Did successfully send message identified by messageID
        print ("Successfully sent GCM message: " + messageID)
    }
    // [END upstream_callbacks]
    
    func didDeleteMessagesOnServer() {
        // Some messages sent to this device were deleted on the GCM server before reception, likely
        // because the TTL expired. The client should notify the app server of this, so that the app
        // server can resend those messages.
        print("You lost messages due to expiration")
    }
    
    
}
