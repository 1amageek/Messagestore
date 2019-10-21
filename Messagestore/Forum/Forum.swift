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
>: NSObject {

    /// Create a new topic.
    /// - Parameter topic: A new topic
    /// - Parameter subscribers: The first user to subscribe.
    /// - Parameter completion: The Firestore batch callback.
    open class func create<T: DataRepresentable, U: DataRepresentable>(topic: T, subscribers: [U], completion: ((Error?) -> Void)? = nil) where T: Object, U: Object, T.Model == TopicType, U.Model == MemberType {
        let batch: Batch = Batch()
        let subscription: Document<Subscription> = Document()
        subscription.data?.topic = topic.documentReference
        batch.save(topic)
        batch.save(subscribers, to: topic.documentReference.collection("subscribers"))
        subscribers.forEach { member in
            batch.save(subscription, to: member.documentReference.collection("subscribedTopics"))
        }
        batch.commit(completion)
    }

    /// Start a topic subscription.
    /// - Parameter topic: The topic to subscribe to.
    /// - Parameter subscribers: Specify the user to subscribe to. Specify MemberType but you must have user documentReference to save subscribedTopics to user's subCollection.
    ///
    ///     ex.
    ///     DocumentReference: `/users/:uid`
    ///
    /// - Parameter completion: The Firestore batch callback.
    open class func subscribe<T: DataRepresentable, U: DataRepresentable>(topic: T, subscribers: [U], completion: ((Error?) -> Void)? = nil) where T: Object, U: Object, T.Model == TopicType, U.Model == MemberType {
        let batch: Batch = Batch()
        let subscription: Document<Subscription> = Document()
        subscription.data?.topic = topic.documentReference
        batch.save(subscribers, to: topic.documentReference.collection("subscribers"))
        subscribers.forEach { member in
            batch.save(subscription, to: member.documentReference.collection("subscribedTopics"))
        }
        batch.commit(completion)
    }

    /// Post to the target topic.
    /// - Parameter post: The post is posted to the topic.
    /// - Parameter topic: Post to this topic.
    /// - Parameter completion: The Firestore batch callback.
    open class func post<T: DataRepresentable, U: DataRepresentable>(_ post: T, to topic: U, completion: ((Error?) -> Void)? = nil) where T: Object, U: Object, T.Model == PostType, U.Model == TopicType {
        let batch: Batch = Batch()
        batch.save(post, to: topic.documentReference.collection("posts"))
        batch.commit(completion)
    }
}

/**
 Subscription represents the relationship with Topic.
 When a user subscribes to Topic, the subscription is saved in `/users/:uid/subscribedTopics/`.
 */
public struct Subscription: Modelable, Codable {

    public var topic: DocumentReference!

    public var isHidden: Bool = false

    public init() { }

    public init(topic: DocumentReference) {
        self.topic = topic
    }
}

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
