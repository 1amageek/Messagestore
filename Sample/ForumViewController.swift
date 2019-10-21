//
//  ForumViewController.swift
//  Sample
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Ballcap

struct Topic: Modelable, Codable, TopicProtocol {

    var title: String?

    var thumbnailImage: File?

    var isAvailable: Bool = true

    var isHidden: Bool = false
}

struct Post: Modelable, Codable, PostProtocol {

    var reply: DocumentReference?

    var from: String = ""

    var text: String?

    var image: File?

    var video: File?

    var audio: File?

    var location: GeoPoint?

    var sticker: String?

    var imageMap: [File] = []
}

class ForumViewController: Forum<Member, Topic, Post>.TopicsViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {

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

    @objc func addTopic() {
        let storyboard: UIStoryboard = UIStoryboard(name: "AddTopicViewController", bundle: nil)
        let viewController: AddTopicViewController = storyboard.instantiateInitialViewController() as! AddTopicViewController
        self.present(viewController, animated: true, completion: nil)
    }

    func postsViewController(with topic: Document<Topic>) -> Forum<Member, Topic, Post>.PostsViewController {
        let viewController: PostViewController = PostViewController(topic: topic)
        viewController.hidesBottomBarWhenPushed = true
        return viewController
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.dataSource
            .retrieve(from: { (snapshot, documentSnapshot, done) in
                let subscription: Document<Subscription> = Document(snapshot: documentSnapshot)!
                let document: Document<Topic> = Document(subscription[\.topic])
                document.get { (topic, error) in
                    if let error = error {
                        print(error)
                        done(document)
                        return
                    }
                    done(topic ?? document)
                }
            })
            .onChanged { [weak self] (_, _) in
                self?.collectionView.reloadData()
        }

        self.listen()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Topic", style: .done, target: self, action: #selector(addTopic))
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
    }

    open override func viewWillLayoutSubviews() {
        self.collectionView.frame = self.view.bounds
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
        let topic: Document<Topic> = self.dataSource[indexPath.item]
        cell.titleLabel.text = topic.data?.title
        cell.setNeedsDisplay()
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topic: Document<Topic> = self.dataSource[indexPath.item]
        let viewController: PostViewController = PostViewController(topic: topic)
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
