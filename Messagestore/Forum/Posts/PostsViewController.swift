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
    open class PostsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

        /// Returns the Topic holding the message.
        public let topic: Document<TopicType>

        /// limit The maximum number of transcripts to return.
        public let limit: Int

        /// Returns the DataSource of Transcript.
        public var posts: DataSource<Document<PostType>>!

        /// Returns the DataSource of Member.
        public var members: DataSource<Document<MemberType>>!

        /// Returns a CollectionView that displays posts.
        public private(set) var collectionView: UICollectionView!

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

        open func customLayout() -> UICollectionViewLayout {
            let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 320)
            return layout
        }

        open override func loadView() {
            super.loadView()
            self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.customLayout())
            self.collectionView.alwaysBounceVertical = true
            self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
            self.view.addSubview(self.collectionView)
        }
        
        open override func viewDidLoad() {
            super.viewDidLoad()
            if #available(iOS 13.0, *) {
                self.collectionView.backgroundColor = UIColor.systemBackground
            }
        }

        open func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }

        open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.posts.count
        }

        open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
            return cell
        }

        /// Start listening
        open func listen() {
            self.posts.listen()
        }

    }
}
