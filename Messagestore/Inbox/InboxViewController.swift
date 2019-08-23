//
//  InboxViewController.swift
//  Sample
//
//  Created by 1amageek on 2018/07/27.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import UIKit
import Ballcap

extension Message {
    /**
     A ViewController that displays conversation-enabled rooms.
    */
    open class InboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

        /// The ID of the user holding the DataSource.
        public let userID: String

        /// Room's DataSource
        public private(set) var dataSource: DataSource<Document<RoomType>>!

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

        public let tableView: UITableView = UITableView(frame: .zero, style: .plain)

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

        public init(userID: String, fetching limit: Int = 20) {
            self.userID = userID
            self.limit = limit
            super.init(nibName: nil, bundle: nil)
            self.title = "Message"
            self.dataSource = dataSource(userID: userID, fetching: limit)
        }

        /// You can customize the data source by overriding here.
        ///
        /// - Parameters:
        ///   - userID: Set the ID of the user who is participating in the Room.
        ///   - limit: Set the number of Transcripts to display at once.
        /// - Returns: Returns the DataSource with Query set.
        open func dataSource(userID: String, fetching limit: Int = 20) -> DataSource<Document<RoomType>> {
            return Document<RoomType>
                .order(by: "lastTranscriptReceivedAt", descending: true)
                .where("members", arrayContains: userID)
                .where("isHidden", isEqualTo: false)
                .limit(to: limit)
                .dataSource()
                .sorted(by: { $0.data!.lastTranscriptReceivedAt.rawValue > $1.data!.lastTranscriptReceivedAt.rawValue })
        }

        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        open override func loadView() {
            super.loadView()
            self.view.addSubview(self.tableView)
            self.tableView.register(UINib(nibName: "InboxViewCell", bundle: nil), forCellReuseIdentifier: "InboxViewCell")
        }

        open override func viewDidLoad() {
            super.viewDidLoad()
            if #available(iOS 13.0, *) {
                self.tableView.backgroundColor = UIColor.systemBackground
            }
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.rowHeight = UITableView.automaticDimension
            let section: Int = self.targetSection
            self.dataSource
                .retrieve(from: { (snapshot, documentSnapshot, done) in
                    let document: Document<RoomType> = Document(snapshot: documentSnapshot)!
                    document.get { (item, error) in
                        if let error = error {
                            print(error)
                            done(document)
                            return
                        }
                        done(item ?? document)
                    }
                })
                .onChanged({ [weak self] (snapshot, dataSourceSnapshot) in
                    guard let snapshot = snapshot else { return }
                    guard let tableView: UITableView = self?.tableView else { return }
                    
                    if !snapshot.metadata.hasPendingWrites {

                        let insertIndexPaths: [IndexPath] = dataSourceSnapshot.changes.insertions.map { IndexPath(row: dataSourceSnapshot.after.firstIndex(of: $0)!, section: section) }
                        let deleteIndexPaths: [IndexPath] = dataSourceSnapshot.changes.deletions.map { IndexPath(row: dataSourceSnapshot.before.firstIndex(of: $0)!, section: section) }

                        tableView.performBatchUpdates({
                            tableView.insertRows(at: insertIndexPaths, with: .automatic)
                            tableView.deleteRows(at: deleteIndexPaths, with: .automatic)
                        }, completion: nil)

                        if dataSourceSnapshot.before == dataSourceSnapshot.after {
                            dataSourceSnapshot.changes.modifications
                                .map { IndexPath(item: dataSourceSnapshot.after.firstIndex(of: $0)!, section: section)}
                                .filter { (tableView.indexPathsForVisibleRows ?? []).contains($0) }
                                .forEach { indexPath in
                                    if let cell: UITableViewCell = tableView.cellForRow(at: indexPath) {
                                        self?.configure(cell: cell, forAt: indexPath)
                                    }
                            }
                        } else {
                            for (beforeIndex, beforeRoom) in dataSourceSnapshot.before.enumerated() {
                                for (afterIndex, afterRoom) in dataSourceSnapshot.after.enumerated() {
                                    if beforeRoom.id == afterRoom.id {
                                        let atIndexPath: IndexPath = IndexPath(row: beforeIndex, section: section)
                                        let toIndexPath: IndexPath = IndexPath(row: afterIndex, section: section)
                                        tableView.performBatchUpdates({
                                            tableView.moveRow(at: atIndexPath, to: toIndexPath)
                                        }, completion: nil)
                                        if let cell: UITableViewCell = tableView.cellForRow(at: atIndexPath) {
                                            self?.configure(cell: cell, forAt: atIndexPath)
                                        }
                                        if let cell: UITableViewCell = tableView.cellForRow(at: toIndexPath) {
                                            self?.configure(cell: cell, forAt: toIndexPath)
                                        }
                                        return
                                    }
                                }
                            }
                        }
                    }
                })
        }

        open override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.tableView.reloadData()
        }

        open override func viewWillLayoutSubviews() {
            self.tableView.frame = self.view.bounds
        }

        /// Start listening
        public func listen() {
            self.dataSource.listen()
        }

        // MARK: -

        /// It is called after the first fetch of the data source is finished.
        open func didInitialize(of dataSource: DataSource<Document<RoomType>>) {
            // override
        }

        /// Transit to the selected Room. Always override this function.
        /// - parameter room: The selected Room is passed.
        /// - returns: Returns the MessagesViewController to transition.
        open func messageViewController(with room: Document<RoomType>) -> MessagesViewController {
            return MessagesViewController(roomID: room.id)
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

        open func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }

        open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.dataSource.count
        }

        open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell: InboxViewCell = tableView.dequeueReusableCell(withIdentifier: "InboxViewCell", for: indexPath) as! InboxViewCell
            configure(cell: cell, forAt: indexPath)
            return cell
        }

        open func configure(cell: UITableViewCell, forAt indexPath: IndexPath) {
            guard let cell: InboxViewCell = cell as? InboxViewCell else { return }
            let room: Document<RoomType> = self.dataSource[indexPath.item]
            cell.dateLabel.text = self.dateFormatter.string(from: room.updatedAt.dateValue())
            if let name: String = room.data?.name {
                cell.nameLabel.text = name
            }
            if let text: String = room.data?.lastTranscript?.text {
                cell.messageLabel?.text = text
            }

            // Read
            let document: Document<UserType> = Document(room.documentReference.collection("members").document(userID))
            document.get { (member, error) in
                if let error = error {
                    print(error)
                    return
                }
                if let timestamp = member?.updatedAt, let lastTranscriptReceivedAt = room.data?.lastTranscriptReceivedAt {
                    if timestamp < lastTranscriptReceivedAt.rawValue {
                        cell.format = .bold
                    } else {
                        cell.format = .normal
                    }
                } else {
                    cell.format = .bold
                }
            }
            cell.setNeedsDisplay()
        }

        open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let room: Document<RoomType> = self.dataSource![indexPath.item]
            let viewController: MessagesViewController = messageViewController(with: room)
            self.navigationController?.pushViewController(viewController, animated: true)
        }

        open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            // Cancel image loading
        }

        @available(iOS 11.0, *)
        open func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            return nil
        }
    }
}
