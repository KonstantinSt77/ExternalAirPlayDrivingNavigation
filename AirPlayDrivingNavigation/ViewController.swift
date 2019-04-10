//
//  ViewController.swift
//  AirPlayDrivingNavigation
//
//  Created by Konstantin Stolyarenko on 4/10/19.
//  Copyright © 2019 Konstantin Stolyarenko. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var speedLabel: UILabel!

    var externalSpeedLabel = UILabel()
    var externalMapView = MKMapView()
    var externalWindow = UIWindow()

    var locationManager = CLLocationManager()
    var internalAdjustRegion: MKCoordinateRegion?
    var externalAdjustRegion: MKCoordinateRegion?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSettings()
        setupExternalScreen()
    }

    private func setupSettings() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()

        let center = NotificationCenter.default
        center.addObserver(forName: UIScreen.didConnectNotification, object: nil, queue: nil) { notification in
            if let screen = notification.object as? UIScreen {
                self.initializeExternalScreen(externalScreen: screen)
            }
        }

        center.addObserver(forName: UIScreen.didDisconnectNotification, object: nil, queue: nil) { notification in
            self.externalWindow.isHidden = true
        }

        speedLabel.text = "0"
    }

    private func setupExternalScreen() {
        // Initialize an external screen if one is present
        let screens = UIScreen.screens
        if screens.count > 1 {
            //An external screen is available. Get the first screen available
            initializeExternalScreen(externalScreen: screens[1] as UIScreen)
        }
    }

    private func initializeExternalScreen(externalScreen: UIScreen) {
        externalWindow = UIWindow(frame: externalScreen.bounds)
        externalWindow.screen = externalScreen

        externalMapView = MKMapView(frame: externalWindow.frame)
        externalMapView.mapType = .mutedStandard
        let mapCamera = MKMapCamera()
        mapCamera.centerCoordinate = externalAdjustRegion?.center ?? CLLocationCoordinate2DMake(0, 0)
        mapCamera.pitch = 90
        mapCamera.heading = 90
        externalMapView.camera = mapCamera
        externalMapView.showsUserLocation = true

        externalSpeedLabel = UILabel(frame: speedLabel.frame)
        externalSpeedLabel.text = "0"
        externalSpeedLabel.textColor = UIColor.blue
        externalSpeedLabel.font = speedLabel.font
        externalSpeedLabel.backgroundColor = .white
        externalSpeedLabel.layer.cornerRadius = 10
        externalSpeedLabel.clipsToBounds = true
        externalSpeedLabel.layer.borderColor = UIColor.blue.cgColor
        externalSpeedLabel.layer.borderWidth = 2.0
        externalSpeedLabel.textAlignment = .center
        externalSpeedLabel.alpha = 0.5

        let view = UIView(frame: externalWindow.frame)
        view.addSubview(externalMapView)
        view.addSubview(externalSpeedLabel)

        externalWindow.addSubview(view)
        externalWindow.makeKeyAndVisible()
    }

    private func updateLocation(location: CLLocationCoordinate2D) {
        let internalMapRegion = MKCoordinateRegion(center: location, latitudinalMeters: 5000, longitudinalMeters: 5000)
        internalAdjustRegion = mapView.regionThatFits(internalMapRegion)
        mapView.setRegion(internalAdjustRegion!, animated: true)

        let externalMapRegion = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
        externalAdjustRegion = externalMapView.regionThatFits(externalMapRegion)
        externalMapView.setRegion(externalAdjustRegion!, animated: true)

//externalMapView.camera.centerCoordinate = externalAdjustRegion.center
    }

    private func updateSpeed(speed: CLLocationSpeed?) {
        guard let speed = speed else {
            speedLabel.text = "0"
            return
        }

        externalSpeedLabel.text = "\(speed)"
        speedLabel.text = "\(speed)"
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // the location object that we want to initialize based on the string
        let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        updateLocation(location: location)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else {
            return
        }

        updateLocation(location: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))
        updateSpeed(speed: manager.location?.speed)
    }
}
