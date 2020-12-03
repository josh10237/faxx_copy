//
//  UserContact.swift
//  Faxx
//
//  Created by Raul Cheng on 11/11/20.
//

import Foundation

class UserContact: NSObject {
    
    var userId: String = ""
    var displayName: String = ""
    var avatar: String = ""
    var time_ref: Double = getCurrentUtcTimeInterval()
    var isNew: Bool = false
    var amIAnon: Bool = false
    var fcm_token: String = ""
    var gender: String = ""
    var isTyping: Bool = false
    
    override init() {
        super.init()
    }
    
    init(_ id: String, _ user: NSDictionary) {
        userId = id
        displayName = user["DisplayName"] as? String ?? ""
        avatar = user["Avatar"] as? String ?? DefaultAvatarUrl
        time_ref = user["time"] as? Double ?? getCurrentUtcTimeInterval()
        isNew = user["isNew"] as? Bool ?? false
        amIAnon = id.hasPrefix(AnnoymousIdPrefix)
        gender = user["Sex"] as? String ?? "Other"
        fcm_token = user["FCM_Token"] as? String ?? ""
        isTyping = false
    }
    
}
