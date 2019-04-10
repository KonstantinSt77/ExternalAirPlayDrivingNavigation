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

    var locationManager = CLLocationManager()
    var adjustRegion: MKCoordinateRegion?
    var externalWindow: UIWindow!
    var externalMap: MKMapView?
    var myLocation = CLLocationCoordinate2DMake(0, 0)

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
            if let externalWindow = self.externalWindow {
                externalWindow.isHidden = true
                self.externalWindow = nil
            }
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

    // Initialize an external screen
    private func initializeExternalScreen(externalScreen: UIScreen) {
        // Create a new window sized to the external screen's bounds
        externalWindow = UIWindow(frame: externalScreen.bounds)
        // Assign the screen object to the screen property of the new window
        externalWindow.screen = externalScreen
        // Configure the MapView
        let view = UIView(frame: externalWindow.frame)
        externalMap = MKMapView(frame: externalWindow.frame)
        if let map = externalMap {
            map.mapType = .mutedStandard
            let mapCamera = MKMapCamera()
            mapCamera.centerCoordinate = myLocation
            mapCamera.pitch = 90
            mapCamera.heading = 90
            map.camera = mapCamera
            map.showsUserLocation = true
            view.addSubview(map)
        }

        externalWindow.addSubview(view)
        // Make the window visible
        externalWindow.makeKeyAndVisible()
        // Zoom in on the map in the external display
        adjustExternalScreenRegion()
    }

    private func updateLocation(location: CLLocationCoordinate2D) {
        myLocation = location
        var region = MKCoordinateRegion(center: location, latitudinalMeters: 5000, longitudinalMeters: 5000)
        adjustRegion = mapView.regionThatFits(region)
        mapView.setRegion(adjustRegion!, animated: true)
        region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
        adjustRegion = mapView.regionThatFits(region)

        adjustExternalScreenRegion()
    }

    private func updateSpeed(speed: CLLocationSpeed?) {
        guard let speed = speed else {
            speedLabel.text = "0"
            return
        }

        speedLabel.text = "\(speed)"
    }

    private func adjustExternalScreenRegion() {
        if let externalMap = self.externalMap, let adjustRegion = self.adjustRegion {
            externalMap.camera.centerCoordinate = adjustRegion.center
        }
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

        let location = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        updateLocation(location: location)

        updateSpeed(speed: manager.location?.speed)
    }
}
