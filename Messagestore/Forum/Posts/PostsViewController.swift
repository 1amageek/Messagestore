//
//  PostsViewController.swift
//  Messagestore
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Ballcap

extension Forum {
    open class PostsViewController: UIViewController {

        /// Returns the Topic holding the message.
        public let topic: Document<TopicType>

        /// limit The maximum number of transcripts to return.
        public let limit: Int

        /// Returns the DataSource of Transcript.
        public var posts: DataSource<Document<PostType>>!

        /// Returns the DataSource of Member.
        public var members: DataSource<Document<MemberType>>!

        public init(topic: Document<TopicType>, fetching limit: Int = 20) {
            self.limit = limit
            self.topic = topic
            self.posts = DataSource<Document<PostType>>.Query(topic.documentReference.collection("posts"))
                .order(by: "updatedAt", descending: true)
                .limit(to: limit)
                .dataSource()
                .sorted(by: { $0.updatedAt < $1.updatedAt })

            super.init(nibName: nil, bundle: nil)
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        open override func viewDidLoad() {
            super.viewDidLoad()

            // Do any additional setup after loading the view.
        }

    }
}
