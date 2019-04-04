//
//  Message.swift
//  Messagestore
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import Ballcap

/**
 Messagestore is the core class of chat function.

 In order to use the chat function, it is necessary to conform to the protocol of
 User Protocol, Room Protocol, Transcript Protocol.
 */
open class Message<
    UserType: UserProtocol & Modelable & Codable,
    RoomType: RoomProtocol & Modelable & Codable,
    TranscriptType: TranscriptProtocol & Modelable & Codable
    >: NSObject where RoomType.TranscriptType == TranscriptType
{ }
