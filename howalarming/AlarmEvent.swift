//
//  AlarmEvent.swift
//  howalarming
//
//  Defines the data objects for alarm events.
//
//  Created by Jethro Carr on 25/05/16.
//  Copyright © 2016 Jethro Carr. All rights reserved.
//

import Foundation


class AlarmEvent: NSObject, NSCoding {
    
    // MARK: Properties
    var type: String
    var code: String
    var message: String
    var raw: String
    var time: NSDate
    
    // MARK: Data storage paths
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("AlarmEvent")
    
    
    // MARK: Initialization
    init?(type: String, code: String, message: String, raw: String, time: NSDate) {
        // Initalize properties
        self.type = type
        self.code = code
        self.message = message
        self.raw = raw
        self.time = time

        // TODO: No need for validation currently, they are all expected and all strings.
        
        super.init()
    }
    
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(type, forKey: "type")
        aCoder.encodeObject(code, forKey: "code")
        aCoder.encodeObject(message, forKey: "message")
        aCoder.encodeObject(raw, forKey: "raw")
        aCoder.encodeObject(time, forKey: "time")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let type = aDecoder.decodeObjectForKey("type") as! String
        let code = aDecoder.decodeObjectForKey("code") as! String
        let message = aDecoder.decodeObjectForKey("message") as! String
        let raw = aDecoder.decodeObjectForKey("raw") as! String
        let time = aDecoder.decodeObjectForKey("time") as! NSDate
        
        self.init(type: type, code: code, message: message, raw: raw, time: time)
    }
    
}