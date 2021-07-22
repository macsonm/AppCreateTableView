//
//  CustomTableViewCell.swift
//  AppCreateTableView
//
//  Created by mac on 01.07.2021.
//

import UIKit
import Cosmos

final class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imageOfPlace: UIImageView! {
        didSet {
            imageOfPlace?.layer.cornerRadius = imageOfPlace.frame.size.height / 2     //закругляем imageView
            imageOfPlace?.clipsToBounds = true        // обрезаем изображение по границам imageView
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var cosmosView: CosmosView!  {
        didSet {
            cosmosView.settings.updateOnTouch = false   //отключаем возможность на главном экране при нажатии на участок со звездами задавать рейтинг (осущ просто переход внутрь выбранной ячейки) или через интерфейс билдер "Update On Touch = off"
        }
    }
}
