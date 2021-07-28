//
//  MapVC.swift
//  AppCreateTableView
//
//  Created by mac on 26.07.2021.
//

import UIKit
import MapKit
import CoreLocation

protocol MapVCDelegate {        //передача данных от одного VC к другому
    func getAddress(_ address: String?)
}

class MapVC: UIViewController {
    
    let mapManager = MapManager()
    var mapVCDelegate: MapVCDelegate?    //делегат класса MapVCDelegate
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier" //содержит уникальный идентификатор для аннотации
    var incomeSegueIdentifier = ""

    var previousLocation: CLLocation? {   //хранение предыдущего местоположения юзера
        didSet {  //позиционируем карту при смене локации юзера
            mapManager.startTrackingUserLocation(
                for: mapView,
                and: previousLocation) { (currentLocation) in
                
                self.previousLocation = currentLocation
                
                //задержка в отображении
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)
                }
                
            }
        }
    }
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
        mapView.delegate = self     //указываем делегат для нашего extension'а
        setupMapView()
//        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {         //по нажатии центрирует экран по местоположению юзера
    
        mapManager.showUserLocation(mapView: mapView)
        
    }
    
    @IBAction func doneButtonPressed() {
        mapVCDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)     //закрыть VC
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: mapView) { (location) in
            self.previousLocation = location
        }
    }
    
    @IBAction func closeVC() {
       dismiss(animated: true) //нажатие на кнопку чтобы закрыть VC
    }
    
    private func setupMapView() {       // переход на картру при нажатии местоположения брокера
        
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showBroker" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
//
////?????????
//    private func setupLocationManager() {
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest       //максимальная точность местоположения юзера
//    }
//

}

extension MapVC: MKMapViewDelegate {        //отображение баннеров около аннотаций у метки на карте
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {  //отображение аннотации viewFor annotation
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView    //приводим к типу MKPinAnnotationView - тогда метка не пропадет и баннер будет с булавкой
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: annotationIdentifier)
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {   //вызывается каждый раз при смене отображаемого на экране региона и при вызове отображаем адресс который находится в центре этого региона
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showBroker" && previousLocation != nil {       //при построении маршрута previusLocation != nil,
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){               //то позиционируем карту по местоположению юзера с задержкой 3сек
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geocoder.cancelGeocode()        //освобождение ресурсов связаных с геокодированием
        
        //преобразуем координаты в текст
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first        //объект CoreLocation
            let streetName = placemark?.thoroughfare    //извлекаем адрес в текстовом формате через свойство .thoroughfare
            let buildNumber = placemark?.subThoroughfare    //извлекаем номер дома
            
            DispatchQueue.main.async {      //делаем операцию в другом потоке?
                
                if streetName != nil && buildNumber != nil {
                self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    //подсветка возможных маршрутов
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)  //рендерим наложения маршрутов сделанных ранее
        renderer.strokeColor = .blue  //придаем цвет маршруту
        
        return renderer
    }
}

extension MapVC: CLLocationManagerDelegate {        //отслеживаем в релаьном времени изменение статуса разрешений геопозиции
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapManager.checkLocationAuthorization(mapView: mapView, segueIdentifier: incomeSegueIdentifier)
    }
}
