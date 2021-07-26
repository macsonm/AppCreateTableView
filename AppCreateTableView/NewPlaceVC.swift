//
//  NewPlaceVC.swift
//  AppCreateTableView
//
//  Created by mac on 02.07.2021.
//

import UIKit

final class NewPlaceVC: UITableViewController {

    var currentPlace: Place!
    var imageIsChanged = false //если юзер будет загружать своё изображение то должно быть true
    private let storageManager = StorageManager.shared
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var brokerImage: UIImageView!
    @IBOutlet weak var bName: UITextField!
    @IBOutlet weak var bLocation: UITextField!
    @IBOutlet weak var bType: UITextField!
    @IBOutlet weak var ratingControl: RatingC!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,      //убираем лишние линии ячеек, в которых нет контента и под звездами
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1))
        
        saveButton.isEnabled = false        //по умолчанию saveButton отключена // если заполняется поле name должна снова быть доступна
        bName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        setupEditScreen()
    }

    
    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let photoIcon = #imageLiteral(resourceName: "photo")
            
//загрузка картинки:
            let actionSheet = UIAlertController(title: nil,     //вывод алерта с выбором меню: (алертконтроллер)
                                                message: nil,
                                                preferredStyle: .actionSheet)
            //пользовательские действия
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            camera.setValue(cameraIcon, forKey: "image")    //устанавливаем параметру camera значение cameraIcon (картинка загруженная в Assets)
            camera.setValue(CATextLayerAlignmentMode.left, forKey:  "titleTextAlignment")
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            //добавляем все действия пользователя в АлертКонтроллер
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            //вызов alertController'а
            present(actionSheet, animated: true)
        } else {
            view.endEditing(true)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {     //переход на MapVC
        
        guard
            let identifier = segue.identifier,
            let mapVC = segue.destination as? MapVC
        else { return }
        
        mapVC.incomeSegueIdentifier = identifier
        if identifier == "showBroker" {
            //передаем конктретные значения из полей в MapVC
            mapVC.place.name = bName.text
            mapVC.place.location = bLocation.text
            mapVC.place.type = bType.text
            mapVC.place.imageData = brokerImage.image?.pngData()
        }
    }
    
//сохранение информации при нажатии на кнопку save, то есть вызывается метод позволяющий сохранить поля заполненные
    func saveBroker() {

        let image = imageIsChanged ? brokerImage.image : #imageLiteral(resourceName: "start")
        let imageData = image?.pngData()    //конвертируем изображение в pngData, (image - это UIimage поэтому конв в тип Data)
        
        //инициализируем через инициализатор в PlaceModel:
        let newBroker = Place(name: bName.text,
                              location: bLocation.text,
                              type: bType.text,
                              imageData: imageData,
                              rating: Double(ratingControl.rating))
        
        if currentPlace != nil {        //определяем действие (редактирование или новый брокер)
            storageManager.replace(currentPlace, to: newBroker)
        } else {
            storageManager.save(newBroker)    //сохраняем новый объект в БД
        }
    }
    
    //при переходе по сегвею showDetails мы будем открывать экран редактирования объекта
    private func setupEditScreen() {
        if currentPlace != nil {
            
            setupNavigationBar()
            imageIsChanged = true
            
            guard let data = currentPlace?.imageData,
                  let image = UIImage(data: data) else { return }
        
            brokerImage.image = image
            brokerImage.contentMode = .scaleAspectFit     //корректируем отображаемое изображение
            bName.text = currentPlace?.name
            bLocation.text = currentPlace?.location
            bType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
        }
    }
    
    //отображение в NavigationBar'e имени выбранной ячейки
    private func setupNavigationBar() {
        if let topItem = navigationController?.navigationBar.topItem {      //убираем название ViewController'а на которых переходим обратно
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
        
        navigationItem.leftBarButtonItem = nil //убираем кнопку cancel
        title = currentPlace?.name      //присваиваем название брокера
        saveButton.isEnabled = true //включаем кноку save
    }
    
    //выгрузка из памяти не сохраняемой информации, при отмене добавления нового брокера
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
       dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Text field delegate

extension NewPlaceVC: UITextFieldDelegate {
    //скрытие клавиатуры по нажатии на кнопку done
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func textFieldChanged() {
        if bName.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }

}

// MARK: - Work with image

extension NewPlaceVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(source) { //проверка на доступность источника выбора картинки - откуда она будет браться
            let imagePicker = UIImagePickerController()     //создаем экземпляр класса UIImagePickerController
            imagePicker.delegate = self //  imagePicker - делегирует выполнение данного метода (делигирует объект с типом UIImagePickerController) а объект который выполняет данный метод (назначаем делегат) - это наш класс NewPlaceVC
            imagePicker.allowsEditing = true        //позволяет пользователю редактировать изображение - масштабировать перед загрузкой
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
            
        }
        
    }
    
//didFinishPickingMediaWithInfo - отображаем выбранную пользователем картинку
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        brokerImage.image = info[.editedImage] as? UIImage // обращаемся к параметру info и берем значение по ключу editedImage и приводим это значение к типу UIImage то есть мы присваиваем отредактированное изображение к свойству ImageOfPlace
        brokerImage.contentMode = .scaleAspectFill //масштабируем изображение по содержимому UIImage
        brokerImage.clipsToBounds = true   //обрезаем по границе изображение
        
        imageIsChanged = true // фоновая картинка не меняется
        
        dismiss(animated: true) //закрываем ImagePickerController после добавления картинки
    }

}
