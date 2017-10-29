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
    var time: Date
    
    // MARK: Data storage paths
    static let DocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("AlarmEvent")
    
    
    // MARK: Initialization
    init?(type: String, code: String, message: String, raw: String, time: Date) {
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
    func encode(with: NSCoder) {
        with.encode(type, forKey: "type")
        with.encode(code, forKey: "code")
        with.encode(message, forKey: "message")
        with.encode(raw, forKey: "raw")
        with.encode(time, forKey: "time")
    }
    
    // This is an alternative init for NSCoding compatibility. Basically "alternative init" function.
    required convenience init?(coder: NSCoder) {
        let type = coder.decodeObject(forKey: "type") as! String
        let code = coder.decodeObject(forKey: "code") as! String
        let message = coder.decodeObject(forKey: "message") as! String
        let raw = coder.decodeObject(forKey: "raw") as! String
        let time = coder.decodeObject(forKey: "time") as! Date
        
        self.init(type: type, code: code, message: message, raw: raw, time: time)
    }
    
}
