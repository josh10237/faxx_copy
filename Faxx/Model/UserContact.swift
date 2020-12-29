//
//  UserContact.swift
//  Faxx
//
//  Created by Raul Cheng on 11/11/20.
//

import Foundation
import SwiftyJSON

class UserContact: NSObject {
    
    var id: Int = 0
    var externalId: String = ""
    var display_name: String = ""
    var avatar: String = ""
    var gender: String = ""
    var age: Int = 0
    var fcm_token: String = ""
    var anon_display_name: String = ""
    var anon_avatar: String = ""
    
    override init() {
        super.init()
    }
    
    init(_ user: JSON) {
        id = user["id"].intValue
        externalId = user["externalId"].stringValue
        display_name = user["display_name"].stringValue
        avatar = user["avatar"].stringValue
        gender = user["gender"].stringValue
        age = user["age"].intValue
        fcm_token = user["fcm_token"].stringValue
        anon_display_name = user["anon_display_name"].stringValue
        anon_avatar = user["anon_avatar"].stringValue
    }
    
}
