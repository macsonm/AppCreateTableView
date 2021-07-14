//
//  PlaceModel.swift
//  AppCreateTableView
//
//  Created by mac on 01.07.2021.
//

import RealmSwift

class Place: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?  //для хранения изображения, которое будет загружать юзер
    @objc dynamic var date = Date() //свойство для сортировки по дате добавления: необходимо 
    @objc dynamic var rating = 0.0
    
    convenience init(name: String, location: String?, type: String?, imageData: Data?, rating: Double) {  // convience инициализирует все свойства в классе
        self.init() //инициализирует параметры по умолчанию
        
        //далее присваивает уже конкретные, теперь нет необходимости указывать инициальзатор ы NewPlaceVC
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}
