//
//  StorageManager.swift
//  AppCreateTableView
//
//  Created by mac on 05.07.2021.
//

import RealmSwift

let realm = try! Realm()

final class StorageManager {

    static var shared = StorageManager()

    private init() {}
    
    func saveObject(_ place: Place) {          //сохранение объетов с типом Place
        try! realm.write {     //сохранение в БД
            realm.add(place)
        }
    }
    
    func deleteObject(_ place: Place){
        try! realm.write {
            realm.delete(place) //удаление из БД
        }
    }
    
}
