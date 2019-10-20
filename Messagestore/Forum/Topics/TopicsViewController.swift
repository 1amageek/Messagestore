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
    open class TopicsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {


        /// The ID of the user holding the DataSource.
        public let userID: String

        /// Room's DataSource
        public private(set) var dataSource: DataSource<Document<TopicType>>!

        /// limit The maximum number of rooms to return.
        public let limit: Int

        /// Returns the date format of the message.
        open var dateFormatter: DateFormatter = {
            let dateFormatter: DateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true
            return dateFormatter
        }()

        /// Returns a CollectionView that displays a topic.
        public private(set) var collectionView: UICollectionView!

        /// Returns a Section that reflects the update of the data source.
        open var targetSection: Int {
            return 0
        }

        public var isLoading: Bool = false {
            didSet {
                if isLoading != oldValue, isLoading {
                    self.dataSource.next()
                }
            }
        }

        // MARK: -

        internal var isFirstFetching: Bool = true

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

        open override func loadView() {
            super.loadView()
            let collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: collectionViewLayout)
            self.collectionView.alwaysBounceVertical = true
            self.view.addSubview(self.collectionView)
            if #available(iOS 13.0, *) {
                 self.view.backgroundColor = UIColor.systemBackground
                 self.collectionView.backgroundColor = UIColor.systemBackground
            } else {
                self.view.backgroundColor = UIColor.white
                self.collectionView.backgroundColor = UIColor.white
            }
            self.collectionView.register(UINib(nibName: "TopicViewCell", bundle: nil), forCellWithReuseIdentifier: "TopicViewCell")
        }

        open override func viewDidLoad() {
            super.viewDidLoad()
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.dataSource
                .retrieve(from: { (snapshot, documentSnapshot, done) in
                    let subscription: Document<Subscription> = Document(snapshot: documentSnapshot)!
                    let document: Document<TopicType> = Document(subscription[\.topic])
                    document.get { (topic, error) in
                        if let error = error {
                            print(error)
                            done(document)
                            return
                        }
                        done(topic ?? document)
                    }
                })
                .onChanged({ [weak self] (snapshot, dataSourceSnapshot) in
                    guard let snapshot = snapshot else { return }
                    guard let collectionView: UICollectionView = self?.collectionView else { return }
                    if !snapshot.metadata.hasPendingWrites {
                        collectionView.reloadData()
                    }
                })
        }

        open override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.collectionView.reloadData()
        }

        open override func viewWillLayoutSubviews() {
            self.collectionView.frame = self.view.bounds
        }

        /// Start listening
        public func listen() {
            self.dataSource.listen()
        }

        // MARK: -

        /// It is called after the first fetch of the data source is finished.
        open func didInitialize(of dataSource: DataSource<Document<TopicType>>) {
            // override
        }

        /// Transit to the selected Room. Always override this function.
        /// - parameter room: The selected Room is passed.
        /// - returns: Returns the MessagesViewController to transition.
        open func postsViewController(with topic: Document<TopicType>) -> PostsViewController {
            return PostsViewController(topic: topic)
        }

        // MARK: -

        private var threshold: CGFloat {
            if #available(iOS 11.0, *) {
                return -self.view.safeAreaInsets.top
            } else {
                return -self.view.layoutMargins.top
            }
        }

        private var canLoadNextToDataSource: Bool = true

        open func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if isFirstFetching {
                self.isFirstFetching = false
                return
            }
            // TODO: スクロールが逆になってる問題
            if canLoadNextToDataSource && scrollView.contentOffset.y < threshold && !scrollView.isDecelerating {
                if !self.dataSource.isLast && self.limit <= self.dataSource.count {
                    self.isLoading = true
                    self.canLoadNextToDataSource = false
                }
            }
            if !canLoadNextToDataSource && !scrollView.isTracking && scrollView.contentOffset.y <= threshold {
                self.canLoadNextToDataSource = true
            }
        }

        // MARK: -

        open func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }

        open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.dataSource.count
        }

        public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell: TopicViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopicViewCell", for: indexPath) as! TopicViewCell
            configure(cell: cell, forAt: indexPath)
            return cell
        }

        open func configure(cell: UICollectionViewCell, forAt indexPath: IndexPath) {
            guard let cell: TopicViewCell = cell as? TopicViewCell else { return }
            let topic: Document<TopicType> = self.dataSource[indexPath.item]
            cell.titleLabel.text = topic.data?.title
            cell.setNeedsDisplay()
        }

        open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let topic: Document<TopicType> = self.dataSource[indexPath.item]
            let viewController: PostsViewController = self.postsViewController(with: topic)
            self.navigationController?.pushViewController(viewController, animated: true)
        }

        open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        }

        open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {

        }

        open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: UIScreen.main.bounds.width, height: 320)
        }
    }
}


