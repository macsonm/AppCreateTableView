//
//  MainVC.swift
//  AppCreateTableView
//
//  Created by mac on 01.07.2021.
//

import UIKit
import RealmSwift


final class MainVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil)     // поисковая строка; nil - указывает что результаты отображать на том же VC
    private var places: Results<Place>?   //запрашиваем данные из БД в реальном времени
    private var filteredPlaces: Results<Place>! //массив в котором хранятся результаты поиска
    private var ascendingSorting = true //сортировка по возрастанию
    private var searchBarIsEmpty: Bool {       //пустая строка или нет
        guard let text = searchController.searchBar.text else {return false}
        return text.isEmpty
    }
    
    private var isFiltering: Bool {     //при активации поискового запроса мы отслеживаем это и подгружаем наших брокеров
        return searchController.isActive && !searchBarIsEmpty
    }
    private let storageManager = StorageManager.shared
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
//        createTestData()
        places = storageManager.allPlaces //отображаем всех брокеров (картинки и поля) на экране обратившись к БД
        
        //Setup the search controller
        configureSearchController()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func configureSearchController() {
        searchController.searchResultsUpdater = self        //получатель об изменении текста в поисковой строке будет наш класс
        searchController.obscuresBackgroundDuringPresentation = false   //позволяет взаимодействовать с VC то есть с информацией которая будет отображаться
        searchController.searchBar.placeholder = "Search"   //название для поисковой строчки
        navigationItem.searchController = searchController  //строка поиска будет вставлена в Navigation Bar
        definesPresentationContext = true   //отпустить строку поиска при переходе на другой экран
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {        //отображение объектов если активирова поисковая строка
            return filteredPlaces.count
        }
        return  places?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CustomTableViewCell else { // as! - говорим что работать с нашим класом - указываем ссылку на наш класс и используем все свойства нашего класса
            return UITableViewCell()
        }

//        var place = Place()     //создаем экземпляр модели чтобы присвоить значение из того или иного массива
//        if isFiltering {                                //если поиск запрос активирован
//            place = filteredPlaces[indexPath.row]       //то place присваиваем значения из filteredPlaces
//        } else {
//            place = places[indexPath.row]               //стандартное отображение
//        }
        let place = isFiltering ? filteredPlaces[indexPath.row] : places?[indexPath.row]     //тернарный оператор - замена выше 6 строк
        
        cell.nameLabel?.text = place?.name
        cell.locationLabel.text = place?.location
        cell.typeLabel.text = place?.type
        cell.imageOfPlace.image = UIImage(data: place?.imageData ?? Data())       //изображение ячейки берем из БД
        cell.cosmosView.rating = place?.rating ?? 0//отображение актуальных значений звезд на VC

        return cell
    }
    
    //MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {     //убирает выделение ячейки, которое остается после возврата к списку брокеров
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = places?[indexPath.row]       //объект удаления попределяемый по индексу строки

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {[weak self] _,_,_ in
            if let place = place {
                self?.storageManager.delete(place)  //удаление объекта из БД
            }
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)    //удаление на экране
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {     //тап по ячейке - будем переходит по сегвею showDetail от главного экрана на 2ой
        if segue.identifier == "showDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }     //то передаем на NewPlaceVС запись, для этого в NewPlaceVC создаем объект var = currentPlace: Place - извлекаем индекс выбранной ячейки
            
//            let place: Place        //данные из БД
//            if isFiltering {        //если данные были отфильтрованы то
//                place = filteredPlaces[indexPath.row]   //зная индекс ячейки - извлекаем объект из массива filterdPlaces, который передадим на ViewController для отображения
//            } else {
//                place = places[indexPath.row]   //если не было открыто searchBar и данные не фильтровались то отображать объекты из БД
//            }
            let place = isFiltering ? filteredPlaces[indexPath.row] : places?[indexPath.row]     // замена верхних 8 строк
            
            guard let newPlaceVC = segue.destination as? NewPlaceVC else { return }
            newPlaceVC.currentPlace = place
        }
    }

    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {        //по нажатии кнопки save мы передаем данные из NewPlaceVС в MainVC когда сохраняем инф об брокере
        guard let newBrokerVC = segue.source as? NewPlaceVC else { return }
        
        newBrokerVC.saveBroker()
        tableView.reloadData() //обновляем интерфейс
    }
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    
    @IBAction func revesedSorting(_ sender: Any) {
        ascendingSorting.toggle() //меняет значение на противоположное
        
        if ascendingSorting {
            reversedSortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedSortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        
        sorting()
    }
    
    private func sorting() {     //выполнение сортировки
        if segmentedControl.selectedSegmentIndex == 0 {     //если выбран первый сегмент сегментконтроллера
            places = places?.sorted(byKeyPath: "date", ascending: ascendingSorting)  //то сортируем по полю date и по значению ascending sorting
        } else {
            places = places?.sorted(byKeyPath: "name", ascending: ascendingSorting)   //иначе выбран другой элемент сегментконтроллера и отсортирован по возрастанию
        }
        
        tableView.reloadData()
    }
    
    private func createTestData() {     //тестовые данные
        let storageManager = StorageManager.shared
        
        let b1 = Place(name: "ibkr",
                       location: "One Pickwick Plaza, Greenwich, CT 06830 USA",
                       type: "broker",
                       imageData: #imageLiteral(resourceName: "ibkr").pngData(),
                       rating: 4.0)
        let b2 = Place(name: "Tinkoff",
                       location: "Москва Волоколамский проезд, дом 10, строение 1",
                       type: "broker2",
                       imageData: #imageLiteral(resourceName: "tinkof").pngData(),
                       rating: 4.0)
        let b3 = Place(name: "BCS",
                       location: "Москва проспект мира 69",
                       type: "broker2",
                       imageData: #imageLiteral(resourceName: "bcs").pngData(),
                       rating: 4.0)
        let b4 = Place(name: "Sber",
                       location: "Оружейный пер., 41, Москва",
                       type: "broker2",
                       imageData: #imageLiteral(resourceName: "sber").pngData(),
                       rating: 4.0)
        let b5 = Place(name: "VTB",
                       location: "Долгоруковская ул., д. 2, Москва",
                       type: "broker2",
                       imageData: #imageLiteral(resourceName: "VTB").pngData(),
                       rating: 4.0)
        let b6 = Place(name: "test",
                       location: "Санкт-Петербург",
                       type: "broker2",
                       imageData: #imageLiteral(resourceName: "photo").pngData(),
                       rating: 2.0)
        
        let ar = [b1,b2,b3,b4,b5,b6]
        
        for newBroker in ar {
            storageManager.save(newBroker)
        }
        
    }
}

// MARK: - UISearchResultsUpdating

extension MainVC: UISearchResultsUpdating {     //расширение для серчконтроллера
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }
    
    func filterContentForSearchText(_ searchText: String) {  //фильтрация контента по запросу поисковому
        filteredPlaces = places?.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText) //заполняем коллекцию отфильтрованными объктами из основного массива places с помощью .filter //фильтрация данных с помощью realm
              
        tableView.reloadData()
    }

}

