//
//  StorageManager.swift
//  AppCreateTableView
//
//  Created by mac on 05.07.2021.
//

import RealmSwift

final class StorageManager {

    static var shared = StorageManager()
    
    private let realm: Realm?

    //MARK: Init
    private init() {
        realm = try? Realm()
    }
    
    var allPlaces: Results<Place>? {
        realm?.objects(Place.self)
    }
    
    func save(_ place: Place) {          //сохранение объетов с типом Place
        try? realm?.write {     //сохранение в БД
            realm?.add(place)
        }
    }
    
    func replace(_ old: Place, to new: Place) {
        try? realm?.write {      //если редактируем брокера существующего в БД
            old.name = new.name
            old.location = new.location
            old.type = new.type
            old.imageData = new.imageData
            old.rating = new.rating
        }
    }
    
    func delete(_ place: Place){
        try? realm?.write {
            realm?.delete(place) //удаление из БД
        }
    }
    
}
