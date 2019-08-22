//
//  MessagesViewController.swift
//  Messagestore
//
//  Created by 1amageek on 2018/07/31.
//  Copyright © 2018年 1amageek. All rights reserved.
//

import UIKit
import Ballcap
import FirebaseFirestore
import Toolbar

extension Message {
    /**
     A ViewController that displays a message.
     */
    open class MessagesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching, UITextViewDelegate {
        
        /// Returns the Room holding the message.
        public let room: Document<RoomType>
        
        /// Returns the toolbar to display in inputAccessoryView.
        public var toolBar: Toolbar = Toolbar()
        
        /// limit The maximum number of transcripts to return.
        public let limit: Int
        
        /// Returns the DataSource of Transcript.
        public var dataSource: DataSource<Document<TranscriptType>>!
        
        /// Returns a CollectionView that displays a message.
        public private(set) var collectionView: MessagesView!
        
        /// Returns a Section that reflects the update of the data source.
        open var targetSection: Int {
            return 0
        }
        
        open var calendar: Calendar = Calendar.current
        
        /// Returns the textView of inputAccessoryView.
        open var textView: UITextView = {
            let textView: UITextView = UITextView(frame: .zero)
            textView.font = UIFont.systemFont(ofSize: 15)
            textView.layer.cornerRadius = 12
            textView.layer.borderColor = UIColor.lightGray.cgColor
            textView.layer.borderWidth = 1 / UIScreen.main.scale
            textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            return textView
        }()
        
        open lazy var titleView: MessagesTitleView? = {
            guard let senderID: String = self.senderID else {
                fatalError("[Messagestore] error: You need to override senderID.")
            }
            let titleView: MessagesTitleView = UINib(nibName: "MessagesTitleView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! MessagesTitleView
            if let name: String = self.room.data?.name {
                titleView.nameLabel.text = name
            }
//            else if let config: [String: Any] = room.config[senderID] as? [String: Any] {
//                if let nameKey: String = RoomType.configNameKey {
//                    titleView.nameLabel.text = config[nameKey] as? String
//                }
//            }
            return titleView
        }()
        
        public var isLoading: Bool = false {
            didSet {
                if isLoading != oldValue, isLoading {
                    self.dataSource?.next()
                }
            }
        }
        
        /// Always override this property.
        open var senderID: String? {
            return nil
        }
        
        /// A Boolean value that determines whether the `MessagesCollectionView` scrolls to the
        /// bottom whenever the `InputTextView` begins editing.
        ///
        /// The default value of this property is `false`.
        open var scrollsToBottomOnKeybordBeginsEditing: Bool = false
        
        open override var canBecomeFirstResponder: Bool {
            return true
        }
        
        open override var inputAccessoryView: UIView? {
            return self.toolBar
        }
        
        open override var shouldAutorotate: Bool {
            return false
        }
        
        /// Returns the date format of the message.
        open var dateFormatter: DateFormatter = {
            let formatter: DateFormatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            formatter.doesRelativeDateFormatting = true
            return formatter
        }()
        
        /// Returns the date format of the message.
        open var timeFormatter: DateFormatter = {
            let formatter: DateFormatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            formatter.doesRelativeDateFormatting = true
            return formatter
        }()
        
        // MARK: -
        
        internal var constraint: NSLayoutConstraint?
        
        internal var isFirstFetching: Bool = true

        internal var collectionViewBottomInset: CGFloat = 0 {
            didSet {
                self.collectionView.contentInset.bottom = collectionViewBottomInset
                self.collectionView.scrollIndicatorInsets.bottom = collectionViewBottomInset
            }
        }
        
        internal var keyboardOffsetFrame: CGRect {
            guard let inputFrame = inputAccessoryView?.frame else { return .zero }
            return CGRect(origin: inputFrame.origin, size: CGSize(width: inputFrame.width, height: inputFrame.height - self.collectionView.safeAreaBottomInset))
        }
        
        internal func addKeyboardObservers() {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        }
        
        internal func removeKeyboardObservers() {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        }
        
        // MARK: -
        
        public convenience init(roomID: String, fetching limit: Int = 20) {
            let room: Document<RoomType> = Document(id: roomID)
            self.init(room: room, fetching: limit)
        }
        
        public init(room: Document<RoomType>, fetching limit: Int = 20) {
            self.limit = limit
            self.room = room
            self.dataSource = DataSource<Document<TranscriptType>>.Query(room.documentReference.collection("transcripts"))
                .order(by: "updatedAt", descending: true)
                .limit(to: limit)
                .dataSource()
                .sorted(by: { $0.updatedAt < $1.updatedAt })
            super.init(nibName: nil, bundle: nil)
        }
        
        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        open override func loadView() {
            super.loadView()
            self.textView.delegate = self
            let collectionViewLayout: MessagesViewFlowLayout = MessagesViewFlowLayout()
            self.collectionView = MessagesView(frame: self.view.bounds, collectionViewLayout: collectionViewLayout)
            if #available(iOS 13.0, *) {
                self.collectionView.backgroundColor = UIColor.systemBackground
            } else {
                self.collectionView.backgroundColor = .white
            }
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.prefetchDataSource = self
            self.collectionView.isPrefetchingEnabled = true
            self.collectionView.bounces = true
            self.collectionView.alwaysBounceVertical = true
            self.collectionView.keyboardDismissMode = .interactive
            self.collectionView.register(UINib(nibName: "MessageViewCell", bundle: nil), forCellWithReuseIdentifier: "MessageViewCell")
            self.collectionView.register(UINib(nibName: "MessageViewLeftCell", bundle: nil), forCellWithReuseIdentifier: "MessageViewLeftCell")
            self.collectionView.register(UINib(nibName: "MessageViewRightCell", bundle: nil), forCellWithReuseIdentifier: "MessageViewRightCell")
            self.view.addSubview(self.collectionView)
            self.toolBar.setItems([ToolbarItem(customView: self.textView)], animated: false)
        }
        
        open override func viewDidLoad() {
            super.viewDidLoad()
            self.navigationItem.titleView = self.titleView
            self.addKeyboardObservers()
            self.dataSource
                .retrieve(from: { (snapshot, documentSnapshot, done) in
                    let document: Document<TranscriptType> = Document(documentSnapshot.reference)
                    document.get { (item, error) in
                        done(item!)
                    }
                })
                .onChanged({ [weak self] (snapshot, dataSourceSnapshot) in
                    guard let collectionView: MessagesView = self?.collectionView else { return }
                    guard let section: Int = self?.targetSection else { return }
                    collectionView.performBatchUpdates({
                        collectionView.insertItems(at: dataSourceSnapshot.changes.insertions.map { IndexPath(row: dataSourceSnapshot.after.firstIndex(of: $0)!, section: section) })
                        collectionView.deleteItems(at: dataSourceSnapshot.changes.deletions.map { IndexPath(row: dataSourceSnapshot.before.firstIndex(of: $0)!, section: section) })
                        collectionView.reloadItems(at: dataSourceSnapshot.changes.modifications.map { IndexPath(row: dataSourceSnapshot.after.firstIndex(of: $0)!, section: section) })
                        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
                        if snapshot?.metadata.hasPendingWrites ?? false {
                            collectionView.scrollToBottom(animated: true)
                        }
                    }, completion: nil)

                    self?.isLoading = false
                    if !(snapshot?.metadata.hasPendingWrites ?? true) {
                        self?.markAsRead()
                    }
                })

        }

        open override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
        }

        open override func viewWillLayoutSubviews() {
            self.collectionView.frame = self.view.bounds
        }

        open override func viewDidLayoutSubviews() {
            self.collectionViewBottomInset = keyboardOffsetFrame.height
        }

        open override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            self.markAsRead()
        }

        open override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
        }

        open override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
        }

        deinit {
            self.removeKeyboardObservers()
        }

        /// Start listening
        open func listen() {
            self.dataSource.listen()
        }
        
        open func markAsRead() {
            guard let uid: String = self.senderID else { return }
            self.room.data?.lastViewedTimestamps[uid] = .pending
            self.room.update()
        }
        
        /// It is called after the first fetch of the data source is finished.
        open func didInitialize(of dataSource: DataSource<Document<TranscriptType>>) {
            // override
        }
        
        /// Call this method to send the message.
        @objc
        public func send() {
            guard let senderID: String = self.senderID else {
                fatalError("[Messagestore] error: You need to override senderID.")
            }
            let room: Document<RoomType> = self.room
            let transcript: Document<TranscriptType> = Document(collectionReference: room.documentReference.collection("transcripts"))
            let batch: Batch = Batch()
            transcript[\.from] = senderID
            transcript[\.to] = room.id
            if !self.transcript(transcript, shouldSendTo: room) {
                return
            }
            self.transcript(transcript, willSendTo: room, with: batch)
            self.room.data?.recentTranscript = transcript.data
            batch.save(transcript)
            batch.update(self.room)
            batch.commit { [weak self] (error) in
                self?.transcript(transcript, didSend: room, reference: transcript.documentReference, error: error)
            }
        }

        /// - returns: If false is set, messages will not be sent.
        open func transcript(_ transcript: Document<TranscriptType>, shouldSendTo room: Document<RoomType>) -> Bool {
            return true
        }
        
        /// Set contents in Transcript.
        /// It must be overridden.
        open func transcript(_ transcript: Document<TranscriptType>, willSendTo room: Document<RoomType>, with batch: Batch) {

        }
        
        /// Called after the message has been sent.
        open func transcript(_ transcript: Document<TranscriptType>, didSend room: Document<RoomType>, reference: DocumentReference?, error: Error?) {
            
        }
        
        // MARK: -
        
        open func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
        
        open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.dataSource.count
        }

        open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
            return true
        }

        open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        }

        open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

        }

        open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
            return false
        }

        open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
            return true
        }

        open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
            return true
        }

        open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let senderID: String = self.senderID else {
                fatalError("[Messagestore] error: You need to override senderID.")
            }

            if indexPath.section == self.targetSection {
                let transcript: Document<TranscriptType> = self.dataSource[indexPath.item]
                var day: String? = nil
                if indexPath.item == 0 {
                    day = self.dateFormatter.string(from: transcript.updatedAt.dateValue())
                } else if indexPath.item > 0 {
                    let previousIndex: Int = indexPath.item - 1
                    let previousTranscript: Document<TranscriptType> = self.dataSource[previousIndex]
                    let previousDateComponents: DateComponents = self.calendar.dateComponents(in: TimeZone.current, from: previousTranscript.updatedAt.dateValue())
                    let dateComponents: DateComponents = self.calendar.dateComponents(in: TimeZone.current, from: transcript.updatedAt.dateValue())
                    if dateComponents.day != previousDateComponents.day {
                        day = self.dateFormatter.string(from: transcript.updatedAt.dateValue())
                    }
                }

                if transcript.data?.from == senderID {
                    let cell: MessageViewRightCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageViewRightCell", for: indexPath) as! MessageViewRightCell
                    if let day: String = day {
                        cell.titleLabel.text = day
                        cell.isDateSectionHeaderHidden = false
                    }
                    cell.textLabel.text = transcript.data?.text
                    cell.dateLabel.text = self.timeFormatter.string(from: transcript.updatedAt.dateValue())
                    return cell
                } else {
                    let cell: MessageViewLeftCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageViewLeftCell", for: indexPath) as! MessageViewLeftCell
                    if let day: String = day {
                        cell.titleLabel.text = day
                        cell.isDateSectionHeaderHidden = false
                    }
                    cell.textLabel.text = transcript.data?.text
                    cell.dateLabel.text = self.timeFormatter.string(from: transcript.updatedAt.dateValue())
                    return cell
                }
            } else {
                fatalError("[Messagestore] error: targetSection is incorrect..")
            }
        }
        
        open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        }
        
        open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            guard let senderID: String = self.senderID else {
                fatalError("[Messagestore] error: You need to override senderID.")
            }

            if indexPath.section == self.targetSection {
                let transcript: Document<TranscriptType> = self.dataSource[indexPath.item]
                var day: String? = nil
                if indexPath.item == 0 {
                    day = self.dateFormatter.string(from: transcript.updatedAt.dateValue())
                } else if indexPath.item > 0 {
                    let previousIndex: Int = indexPath.item - 1
                    let previousTranscript: Document<TranscriptType> = self.dataSource[previousIndex]
                    let previousDateComponents: DateComponents = self.calendar.dateComponents(in: TimeZone.current, from: previousTranscript.updatedAt.dateValue())
                    let dateComponents: DateComponents = self.calendar.dateComponents(in: TimeZone.current, from: transcript.updatedAt.dateValue())
                    if dateComponents.day != previousDateComponents.day {
                        day = self.dateFormatter.string(from: transcript.updatedAt.dateValue())
                    }
                }

                if transcript.data?.from == senderID {
                    let cell: MessageViewRightCell = UINib(nibName: "MessageViewRightCell", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! MessageViewRightCell
                    cell.textLabel.text = transcript.data?.text
                    if let day: String = day {
                        cell.titleLabel.text = day
                        cell.isDateSectionHeaderHidden = false
                    }
                    var size: CGSize = cell.sizeThatFits(.zero)
                    size.width = UIScreen.main.bounds.width
                    return size
                } else {
                    let cell: MessageViewLeftCell = UINib(nibName: "MessageViewLeftCell", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! MessageViewLeftCell
                    cell.textLabel.text = transcript.data?.text
                    if let day: String = day {
                        cell.titleLabel.text = day
                        cell.isDateSectionHeaderHidden = false
                    }
                    var size: CGSize = cell.sizeThatFits(.zero)
                    size.width = UIScreen.main.bounds.width
                    return size
                }
            } else {
                fatalError("[Messagestore] error: targetSection is incorrect.")
            }
        }
        
        // MARK: -
        
        open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
            
        }
        
        // MARK: -
        
        @objc internal func keyboardWillChangeFrame(_ notification: Notification) {
            guard let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let newBottomInset: CGFloat = self.view.frame.height - keyboardEndFrame.minY + self.view.frame.origin.y - self.collectionView.safeAreaBottomInset
            collectionViewBottomInset = newBottomInset
        }
        
        // MARK: -
        
        open func textViewDidBeginEditing(_ textView: UITextView) {
            if scrollsToBottomOnKeybordBeginsEditing {
                collectionView.scrollToBottom(animated: true)
            }
        }
        
        open func textViewDidChange(_ textView: UITextView) {
            let size: CGSize = textView.sizeThatFits(textView.bounds.size)
            textView.isScrollEnabled = size.height > self.toolBar.maximumHeight
            if let constraint: NSLayoutConstraint = self.constraint {
                textView.removeConstraint(constraint)
            }
            self.constraint = textView.heightAnchor.constraint(equalToConstant: size.height)
            self.constraint?.priority = .defaultHigh
            self.constraint?.isActive = true
        }

        open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            return true
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
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if isFirstFetching {
                self.isFirstFetching = false
                return
            }
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
    }
}
