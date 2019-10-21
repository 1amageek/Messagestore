//
//  TopicViewCell.swift
//  Messagestore
//
//  Created by 1amageek on 2019/10/18.
//  Copyright © 2019 Stamp Inc. All rights reserved.
//

import UIKit

class TopicViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
        self.imageView.image = nil
    }

}
