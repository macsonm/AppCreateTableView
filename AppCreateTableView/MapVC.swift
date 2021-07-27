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
    
    var mapVCDelegate: MapVCDelegate?    //делегат класса MapVCDelegate
    var place = Place()
    let annotationIdentifier = "annotationIdentifier" //содержит уникальный идентификатор для аннотации
    let locationManager = CLLocationManager()   //настройка и управление службами геолокации
    let regionInMeters = 10_000.00
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?    //принимает координаты брокерофиса
    
    var directionsArray: [MKDirections] = []    //хранение маршрутов
    
    var previousLocation: CLLocation? {   //хранение предыдущего местоположения юзера
        didSet {  //позиционируем карту при смене локации юзера
            startTrackingUserLocation()
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
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {         //по нажатии центрирует экран по местоположению юзера
    
        showUserLocation()
        
    }
    
    @IBAction func doneButtonPressed() {
        mapVCDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)     //закрыть VC
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    @IBAction func closeVC() {
        
       dismiss(animated: true) //нажатие на кнопку чтобы закрыть VC
        
    }
    
    private func setupMapView() {       // переход на картру при нажатии местоположения брокера
        
        goButton.isHidden = true
        if incomeSegueIdentifier == "showBroker" {
            setupPlacemark()
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
        
    }
    
        
    private func resetMapView(withNew directions: MKDirections) {   //сбрасываем старые маршруты перед построением новых
        mapView.removeOverlays(mapView.overlays)        //удаляем с карты наложение текущего маршрута
        directionsArray.append(directions)
        
        let _ = directionsArray.map { $0.cancel() } // перебираем все значения массива и отменяем у них маршруты!
        directionsArray.removeAll()
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
            
            self.placeCoordinate = placemarkLocation.coordinate //передаем координаты новому свойству placeCoordinate (получили координаты брокера)
            
            self.mapView.showAnnotations([annotation], animated: true)     //задаем видимую область на карте чтобы было видно наши аннотации для метки
            self.mapView.selectAnnotation(annotation, animated: true)       //выделяем созданную аннотацию
            
        }
    }
    
    private func checkLocationServices() {  //включены ли нужные службы геолокации у юзера
    
        if CLLocationManager.locationServicesEnabled() {        //если служба включена
            setupLocationManager()
            checkLocationAuthorization()
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
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
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
    
    private func startTrackingUserLocation() {      //задаем условия
     
        guard let previousLocation = previousLocation else { return }
        let center = getCenterLocation(for: mapView)    //отображем данные коорд в центре экрана
   
        //обновляем область если расстояние между точками больше 50м
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        //задержка в отображении
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
    }
    private func getDirections() {      //построение маршрута
        
        guard let location = locationManager.location?.coordinate else {        //определение координат юзера .location.coordinate
            showAlert(title: "Error", message: "Current location not found")
            return
        }
        
        locationManager.startUpdatingLocation()     //постоянно отслеживаем местоположение юзера
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        guard let request = createDirectionsRequest(from: location) else {       //присваиваем request результат работы createDirectionRequest
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request)     //создаем маршрут на основании успешного запроса
        resetMapView(withNew: directions)   //сбрасываем текущие маршруты
        
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
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)      // видимость карты делаем по всему маршруту
                
                let distance = String(format: "%.1f", route.distance / 1000)        //определяем расстояние
                let timeInterval = route.expectedTravelTime     //опр время в пути
                
                print("Distance to destination point: \(distance) km.")
                print("Time in way is: \(timeInterval) sec.")
            }
        }
    }
    
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {     //запрос для построения маршрута
        
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
    
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation {      //определение координат отображаемых в центре карты
        let latitude = mapView.centerCoordinate.latitude        //получение широты центра экрана
        let longitude = mapView.centerCoordinate.longitude      //получение долготы
        
        return CLLocation(latitude: latitude, longitude: longitude)
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {   //вызывается каждый раз при смене отображаемого на экране региона и при вызове отображаем адресс который находится в центре этого региона
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showBroker" && previousLocation != nil {       //при построении маршрута previusLocation != nil,
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){               //то позиционируем карту по местоположению юзера с задержкой 3сек
                self.showUserLocation()
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
        checkLocationAuthorization()
    }
}
