//
//  MapVC.swift
//  AppCreateTableView
//
//  Created by mac on 26.07.2021.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController {
    
    var place = Place()
    let annotationIdentifier = "annotationIdentifier" //содержит уникальный идентификатор для аннотации
    let locationManager = CLLocationManager()   //настройка и управление службами геолокации
    let regionInMeters = 10_000.00
    var incomeSegueIdentifier = ""
    
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var adressLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self     //указываем делегат для нашего extension'а
        setupMapView()
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {         //по нажатии центрирует экран по местоположению юзера
    
        showUserLocation()
        
    }
    
    @IBAction func doneButtonPressed() {
    
        
        
    }
    
    @IBAction func closeVC() {
        
       dismiss(animated: true) //нажатие на кнопку чтобы закрыть VC
        
    }
    
    private func setupMapView() {       // переход на картру при нажатии местоположения брокера
        
        if incomeSegueIdentifier == "showBroker" {
            setupPlacemark()
            mapPinImage.isHidden = true
            adressLabel.isHidden = true
            doneButton.isHidden = true
        }
        
    }
    
    private func setupPlacemark() {     //маркер указывающий местоположение на карте
        
        guard let location = place.location else { return }     //извлекаем адрес заведения, чтобы он был иначе просто возврат
        
        let geocoder = CLGeocoder()     //создаем экземпляр класса CLGeocoder для преобразования из поля местоположения Брокера в географ координаты
        
        geocoder.geocodeAddressString(location) { (placemarks, error) in            //определяет местоположение на карте по адресу переданому в параметр (location) в виде строки, возвращает массив меток - (placemarks)
            
            if let  error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }       //если нет ошибок в преобразовании строки в координаты то извлекаем опционал и присваиваем placemarks
            
            let placemark = placemarks.first        //получили метку на карте - маркер на карте
            
            //описываем метку
            let annotation = MKPointAnnotation()        //позволяет описывать метку на карте
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            //привязываем Annotation к конкретной точке на карте в соответствии с координатами маркера
            guard let placemarkLocation = placemark?.location else {return}     //опр местоположение маркера
            
            annotation.coordinate = placemarkLocation.coordinate        //привязываем аннотацию к точке на карте
            
            self.mapView.showAnnotations([annotation], animated: true)     //задаем видимую область на карте чтобы было видно наши аннотации для метки
            self.mapView.selectAnnotation(annotation, animated: true)       //выделяем созданную аннотацию
            
        }
    }
    
    private func checkLocationServices() {  //включены ли нужные службы геолокации у юзера
    
        if CLLocationManager.locationServicesEnabled() {        //если служба включена
            setupLocationManager()
        } else { //вызываем алерт контроллер чтобы включить службы
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Your location is not Available",
                    message: "To give permission Go to: Setting > MyPlaces > Location"
                )
                
            }
        }
        
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest       //максимальная точность местоположения юзера
    }
    
    private func checkLocationAuthorization() {     //проверка статуса на использование геопозиции
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAdress" { showUserLocation() }
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Your location is not Available",
                    message: "To give permission Go to: Setting > MyPlaces > Location"
                )
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    private func showUserLocation() {
        
        if let location = locationManager.location?.coordinate {            //определяем координаты юзера
            let region = MKCoordinateRegion(center: location,               //определяем регион для позиционирования карты с центром юзера
                                            latitudinalMeters: regionInMeters,      //радиус для отображения карты
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)           //отображаем регион на экране
        }
    }
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated:true)
    }
    
}

extension MapVC: MKMapViewDelegate {        //отображение баннеров около аннотаций у метки на карте
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {  //отображение аннотации viewFor annotation
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView    //приводим к типу MKPinAnnotationView - тогда метка не пропадет и баннер будет с булавкой
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true       //аннотация в виде баннера
        }
        
        //отображаем картинку Брокера на баннере
        if let imageData = place.imageData {        //проверка опционального значения
            let imageView = UIImageView(frame: CGRect(x:0, y: 0, width: 50, height: 50))        //создаем место для картинки
            imageView.layer.cornerRadius = 10       //закругление углов
            imageView.clipsToBounds = true      //обрезаем изображение по закруглению
            imageView.image = UIImage(data: imageData)  //помещаем изображение в ImageView, которое хранитсяс типом date
            annotationView?.rightCalloutAccessoryView = imageView  //отображение imageView на баннере справа
        }
        
        return annotationView
        
    }
}

extension MapVC: CLLocationManagerDelegate {        //отслеживаем в релаьном времени изменение статуса разрешений геопозиции
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
