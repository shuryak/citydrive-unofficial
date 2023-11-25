import Foundation
import SwiftUI
import MapKit
import Combine

// MARK: Representable to UIKit
struct ImperativeMapView: UIViewControllerRepresentable {
    @ObservedObject var mapVM: MapViewModel

    func makeUIViewController(context: Context) -> MapViewController {
        let mapVC = MapViewController()
        mapVC.mapVM = mapVM
        mapVC.mapView = MKMapView()
        mapVC.locationManager = CLLocationManager()
        return mapVC
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {}
}

// MARK: ViewController with map
class MapViewController: UIViewController {
    var mapVM: MapViewModel!

    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    private var currentUserLocationIsLoad: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        mapSetup()
        createSink()

        self.view = mapView
    }

    func renderGreenArea(area: Area) {
        let coordinates: [CLLocationCoordinate2D] = area.points.map { $0.coordinate }
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polygon)
    }

    func updateCars() {
        mapView.removeAnnotations(mapView.annotations)

        var carAnnotations = [ImperativeMapPin]()

        for car in mapVM.cars {
            let pin = ImperativeMapPin(
                id: car.id,
                coordinate: car.location.coordinate,
                transferable: car.transferable
            )
            carAnnotations.append(pin)
        }

        mapView.addAnnotations(carAnnotations)
    }

    func goToUser() {
        guard let userCoordinate = mapView.userLocation.location?.coordinate else { return }
        goTo(coordinate: userCoordinate)
    }

    func goTo(
        coordinate: CLLocationCoordinate2D,
        offsetLat: CLLocationDegrees? = nil,
        offsetLon: CLLocationDegrees? = nil
    ) {
        var lat = coordinate.latitude
        var lon = coordinate.longitude

        if let offset = offsetLat {
            lat += offset
        }
        if let offset = offsetLon {
            lon += offset
        }

        let сenter = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        let region = MKCoordinateRegion(
            center: сenter,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: true)
    }

    func createSink() {
        mapVM.$cars
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.updateCars()
            }
            .store(in: &cancellables)
        mapVM.$greenArea
            .receive(on: DispatchQueue.main)
            .sink { [weak self] greenArea in
                for area in greenArea?.areas ?? [] {
                    self?.renderGreenArea(area: area)
                }
            }
            .store(in: &cancellables)
        mapVM.$goToUser
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.goToUser()
            }
            .store(in: &cancellables)
        mapVM.$openCarDetail
            .receive(on: DispatchQueue.main)
            .sink { flag in
                if !flag {
                    self.mapView.deselectAnnotation(nil, animated: false)
                }
            }
            .store(in: &cancellables)
    }

    func mapSetup() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        mapView.delegate = self
        mapView.showsUserLocation = true

        updateMapInteractions()
        updateMapType()
    }

    func updateMapType() {
        let mapType = mapVM.mapType?.mapType
        mapView.mapType = mapType ?? .standard
    }

    func updateMapInteractions() {
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = false
    }
}

// MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    // MARK: view for annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ImperativeMapPin {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "ImperativeMapPin")
            annotationView.image = annotation.image
            return annotationView
        }
        if annotation is MKUserLocation {
            let userAnnotationView = UserAnnotationView(
                annotation: annotation,
                reuseIdentifier: "UserAnnotationView"
            )
            return userAnnotationView
        }
        return nil
    }

    // MARK: renderer poligon
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = AppColor.green()
            renderer.lineWidth = 5.0
            renderer.fillColor = AppColor.green().withAlphaComponent(0.05)
            return renderer
        }
        return MKOverlayRenderer()
    }

    // MARK: did select annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? ImperativeMapPin {
            goTo(coordinate: annotation.coordinate, offsetLat: -0.002)

            mapVM.openCarDetail = true
            mapVM.setCurrentCar(id: annotation.id)

            let image = annotation.transferable ? UIImage.pinBigGiveaway : UIImage.pinBigCar
            view.image = image.resizePin(height: 50, width: 30)
            view.centerOffset.y -= 20
        }
    }

    // MARK: did deselect annotation
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotation = view.annotation as? ImperativeMapPin {
            view.image = annotation.image
            view.centerOffset.y += 20
        }
    }
}

// MARK: CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    // MARK: start map position -> user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, !currentUserLocationIsLoad {
            let initialLocation = CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            let region = MKCoordinateRegion(
                center: initialLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
            currentUserLocationIsLoad = true
        }
    }

    // MARK: rotate phone
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let userAnnotationView = mapView.view(for: mapView.userLocation) as? UserAnnotationView {
            userAnnotationView.transform = CGAffineTransform(
                rotationAngle: newHeading.trueHeading * .pi / 180
            )
        }
    }
}