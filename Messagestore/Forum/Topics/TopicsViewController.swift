//
//  TopicsViewController.swift
//  Messagestore
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Ballcap

extension Forum {
    
    /**
     A ViewController that displays conversation-enabled topics.
     */
    open class TopicsViewController: UIViewController {

        /// The ID of the user holding the DataSource.
        public let userID: String

        /// Room's DataSource
        public private(set) var dataSource: DataSource<Document<TopicType>>!

        /// limit The maximum number of rooms to return.
        public let limit: Int

        public init(userReference: DocumentReference, fetching limit: Int = 20) {
            self.userID = userReference.documentID
            self.limit = limit
            super.init(nibName: nil, bundle: nil)
            self.title = "Topics"
            self.dataSource = dataSource(userReference: userReference, fetching: limit)
        }

        /// You can customize the data source by overriding here.
        ///
        /// - Parameters:
        ///   - userReference: Set the DocumentReference of the user who is participating in the topic.
        ///   - limit: Set the number of Transcripts to display at once.
        /// - Returns: Returns the DataSource with Query set.
        open func dataSource(userReference: DocumentReference, fetching limit: Int = 20) -> DataSource<Document<TopicType>> {
            return DataSource<Document<TopicType>>.Query(userReference.collection("subscribedTopics"))
                .order(by: "updatedAt", descending: true)
                .where("isHidden", isEqualTo: false)
                .limit(to: limit)
                .dataSource()
                .sorted(by: { $0.updatedAt > $1.updatedAt })
        }

        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// Start listening
        public func listen() {
            self.dataSource.listen()
        }
    }
}


