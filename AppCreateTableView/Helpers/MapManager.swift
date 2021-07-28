//
//  MapManager.swift
//  AppCreateTableView
//
//  Created by mac on 28.07.2021.
//

import UIKit
import MapKit

class MapManager {      //выносим все св и методы к не влияют на работу контроллера mapVC
    
    let locationManager = CLLocationManager()   //настройка и управление службами геолокации
    
    //эти св-ва нужны только в пределах этого класса поэтому private
    private var placeCoordinate: CLLocationCoordinate2D?    //принимает координаты брокерофиса
    private let regionInMeters = 10_000.00
    private var directionsArray: [MKDirections] = []    //хранение маршрутов
    
    //маркер указывающий местоположение на карте
    func setupPlacemark(place: Place, mapView: MKMapView) { //указываем доп параметры так как класс MapManager не имеет соответствующих свойств
        
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
            annotation.title = place.name
            annotation.subtitle = place.type
            
            //привязываем Annotation к конкретной точке на карте в соответствии с координатами маркера
            guard let placemarkLocation = placemark?.location else {return}     //опр местоположение маркера
            
            annotation.coordinate = placemarkLocation.coordinate        //привязываем аннотацию к точке на карте
            
            self.placeCoordinate = placemarkLocation.coordinate //передаем координаты новому свойству placeCoordinate (получили координаты брокера)
            
            mapView.showAnnotations([annotation], animated: true)     //задаем видимую область на карте чтобы было видно наши аннотации для метки
            mapView.selectAnnotation(annotation, animated: true)       //выделяем созданную аннотацию
            
        }
    }
    
    //включены ли нужные службы геолокации у юзера
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
    
        if CLLocationManager.locationServicesEnabled() {        //если служба включена
            locationManager.desiredAccuracy = kCLLocationAccuracyBest    //setupLocationManager()
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)    //checkLocationAuthorization()
            closure()
        } else { //вызываем алерт контроллер чтобы включить службы
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Your location is not Available",
                    message: "To give permission Go to: Setting > MyPlaces > Location"
                )
                
            }
        }
        
    }
    
   func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {     //проверка статуса на использование геопозиции
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
            break
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
    
    func showUserLocation(mapView: MKMapView) {
        
        if let location = locationManager.location?.coordinate {            //определяем координаты юзера
            let region = MKCoordinateRegion(center: location,               //определяем регион для позиционирования карты с центром юзера
                                            latitudinalMeters: regionInMeters,      //радиус для отображения карты
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)           //отображаем регион на экране
        }
    }
    
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {      //построение маршрута
        
        guard let location = locationManager.location?.coordinate else {        //определение координат юзера .location.coordinate
            showAlert(title: "Error", message: "Current location not found")
            return
        }
        
        locationManager.startUpdatingLocation()     //постоянно отслеживаем местоположение юзера
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else {       //присваиваем request результат работы createDirectionRequest
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request)     //создаем маршрут на основании успешного запроса
        
        resetMapView(withNew: directions, mapView: mapView)   //сбрасываем текущие маршруты
        
        directions.calculate { (response, error) in     //расчет маршрута
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {        //если нет ошибок, то извлекаем обработанный маршрут
                self.showAlert(title: "Error", message: "Direcrions is not available")
                return
            }
            
            for route in response.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)      // видимость карты делаем по всему маршруту
                
                let distance = String(format: "%.1f", route.distance / 1000)        //определяем расстояние
                let timeInterval = route.expectedTravelTime     //опр время в пути
                
                print("Distance to destination point: \(distance) km.")
                print("Time in way is: \(timeInterval) sec.")
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {     //запрос для построения маршрута
        
        guard let destinationCoordinate = placeCoordinate else { return nil }   //определение коорд назначения
        let startingLocation = MKPlacemark(coordinate: coordinate)   //точка начала маршрута на карте
        let destination = MKPlacemark(coordinate: destinationCoordinate)    //точка назначения
        
        let request = MKDirections.Request()    //определяет начальную и конечную точку маршрута
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile //задаем тип транспорта
        request.requestsAlternateRoutes = true  // позволяет строить альтернативные маршруты
        
        return request
    }
    
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {      //задаем условия
     
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)    //отображем данные коорд в центре экрана
   
        //обновляем область если расстояние между точками больше 50м
        guard center.distance(from: location) > 50 else { return }
        
        closure(center)
        
//        self.previousLocation = center
//        //задержка в отображении
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.showUserLocation()
//        }
        
    }
    
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {   //сбрасываем старые маршруты перед построением новых
        mapView.removeOverlays(mapView.overlays)        //удаляем с карты наложение текущего маршрута
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() } // перебираем все значения массива и отменяем у них маршруты!
        directionsArray.removeAll()
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {      //определение координат отображаемых в центре карты
        let latitude = mapView.centerCoordinate.latitude        //получение широты центра экрана
        let longitude = mapView.centerCoordinate.longitude      //получение долготы
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        
        //MapManager не имеет ничего общего с VC поэтому нельзя вызвать метод present(alert) из метода showAlert
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)     //создаем объект UIWindow
        alertWindow.rootViewController = UIViewController()         //инициализируем его свойства rootViewController
        alertWindow.windowLevel = UIWindow.Level.alert + 1          //позиционирование окна относительно других (поверх остальных)
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated:true)   //вызываем окно с предупреждением
        
    }
}
