//
//  MemberProtocol.swift
//  Messagestore
//
//  Created by 1amageek on 2018/07/31.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import Ballcap
import FirebaseFirestore

/**
 Define the properties that the `Member` object should have.
 */
public protocol MemberProtocol {

    /// The display name of the user. The display name is used by InboxViewController and MessagesViewController.
    var name: String? { get set }

    /// thumbnail image.
    /// size 64x64@3x
    var thumbnailImage: File? { get set }
}
