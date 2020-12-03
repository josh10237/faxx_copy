//
//  MockUser.swift
//  Faxx
//
//  Created by Raul Cheng on 11/15/20.
//

import Foundation
import MessageKit

struct MockUser: SenderType, Equatable {
    var senderId: String
    var displayName: String
}
