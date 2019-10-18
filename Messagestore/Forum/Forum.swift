//
//  Forum.swift
//  Messagestore
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import FirebaseFirestore
import Ballcap

/**
 Messagestore is the core class of chat function.
 
 In order to use the chat function, it is necessary to conform to the protocol of
 User Protocol, Room Protocol, Transcript Protocol.
 */
open class Forum<
    MemberType: MemberProtocol & Modelable & Codable,
    TopicType: TopicProtocol & Modelable & Codable,
    PostType: PostProtocol & Modelable & Codable
    >: NSObject
{ }


/**
 Define the properties that the `Post` object should have.
 */
public protocol PostProtocol {
    
    /// Set the Post's DocumentReference
    var reply: DocumentReference? { get set }
    
    /// Set the sender's ID.
    var from: String { get set }
    
    // MARK: -
    
    /// Text content
    var text: String? { get set }
    
    /// Text content
    var image: File? { get set }
    
    /// Video content
    var video: File? { get set }
    
    /// Audio content
    var audio: File? { get set }
    
    /// Location content
    var location: GeoPoint? { get set }
    
    /// Sticker content
    var sticker: String? { get set }
    
    /// Image map content
    var imageMap: [File] { get set }
}


/**
 Define the properties that the `Topic` object should have.
 */
public protocol TopicProtocol {
    
    /// It is the display name of the topic.
    var title: String? { get set }
    
    /// It is the thumbnail image of the room.
    var thumbnailImage: File? { get set }
    
    /// Returns if message is possible. default true.
    var isAvailable: Bool { get set }
    
    /// If it is false, it is not displayed in InBoxViewController.
    var isHidden: Bool { get set }
}
