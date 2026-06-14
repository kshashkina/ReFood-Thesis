#import "@preview/hei-synd-thesis:0.1.1": *
#import "/metadata.typ": *
#pagebreak()
= #i18n("appendix-title", lang: option.lang) <sec:appendix>

==  Initial Product Backlog

*Product Scanning*
- Scan products using a barcode and display the corresponding product page.
- Automatic barcode recognition and product data retrieval.
- Manual scan confirmation via a *"Scan"* button if automatic recognition fails.
- Manual barcode entry with subsequent product page display.
- Display a modal window when a product cannot be found in the database.
- Allow users to manually submit product information for missing products.

*Product Details Page*

- Display core product information after scanning.
- Save products to Favorites.
- Share products via a generated App Store link.
- Allow users to supplement or correct missing product information.
- *"How to Recycle?"* button in the packaging section.
- Dedicated recycling information page for the selected product.
- *"Find Nearest Recycling Point"* button linking the product page with the recycling map.
- Display the nearest recycling location capable of processing the selected packaging type.
- Compare products by Nutri-Score and Eco-Score.
- Compare products by nutritional values.
- AI-powered product comparison and recommendation.

*Sustainability and Recycling*

- Display all packaging components and classify them by material type.
- Display recycling labels and recycling codes whenever available.
- Provide detailed recycling instructions for the selected product.
- Display detailed information about each packaging component.
- Provide packaging preparation instructions before recycling.
- Display contextual recycling tips and recommendations.
- Display all supported packaging types while highlighting those associated with the selected product.
- Provide a *"Find Recycling Point"* action linking packaging information directly to the recycling map.

*Recycling Map*

- Display the user's current location on the map.
- Display recycling point markers.
- Display recycling point details including address, distance, estimated travel time and accepted materials.
- Generate navigation routes to recycling points.
- Filter recycling points by accepted material type.
- Display routes from the user's current location to the selected recycling point.

*User Profile*

- Sign in with Apple.
- Preserve user data across application reinstalls and device changes.
- Display user statistics including scanned products, recycled products and usage streaks.
- Achievement and gamification system with unlockable badges and milestones.
- Display achievement progress and completion status.
- Display achievement unlock dates.
- Application permissions management.
- Language selection.
- Delete account and all associated user data.

== Client-side Implementation

=== BarcodeScannerService

GitHub source file:
https://github.com/kshashkina/ReFood/blob/main/apps/ios/ReFood/ReFood/Infrastructure/Services/BarcodeScannerService.swift

The following fragments show how the scanner session is started, stopped and protected from repeated barcode emissions.

```swift
// starts the camera session on a background queue.
// the isRunning check prevents starting the same AVCaptureSession multiple times.
public func start() {
    sessionQueue.async { [weak self] in
        guard let self else { return }
        guard !self.isRunning else { return }

        // allow a new barcode to be emitted after scanner restart
        self.didEmitCode = false

        self.session.startRunning()
        self.isRunning = true
    }
}

// stops the camera session on the same background queue.
// this is called immediately after a barcode is detected.
public func stop() {
    sessionQueue.async { [weak self] in
        guard let self else { return }
        guard self.isRunning else { return }

        self.session.stopRunning()
        self.isRunning = false
    }
}

// called by AVFoundation when metadata objects are detected in the camera stream.
public func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
) {
    // ignore additional detections after the first successful scan.
    guard !didEmitCode else { return }

    guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
          let value = object.stringValue,
          !value.isEmpty
    else { return }

    // mark barcode as emitted and pass it to the ViewModel through callback.
    didEmitCode = true
    onCodeScanned?(value)
}
```

=== ScannerViewModel

GitHub source file:
https://github.com/kshashkina/ReFood/blob/main/apps/ios/ReFood/ReFood/Presentation/Scanner/ScannerViewModel.swift

The main scanner-to-product loading flow is shown in Section 4.3.6. The full ViewModel source code is referenced here because it also contains UI state management, loading animation, network error handling and navigation-related logic.

=== MapViewModel

GitHub source file:
https://github.com/kshashkina/ReFood/blob/main/apps/ios/ReFood/ReFood/Presentation/Main/Map/MapViewModel.swift

The main controlled geodata loading flow is presented in Section 4.3.7. The full ViewModel source code is referenced here because it also contains route building, tracking mode management, camera animations, filtering logic and error handling.

The following fragment demonstrates asynchronous route construction and validation of required conditions before requesting route data from the backend.

```swift
func buildRoute(to point: MapPoint, mode: RouteMode = .walk) {
    // cancel previous route request if the user selected another point or mode
    currentRouteTask?.cancel()

    currentRouteTask = Task {
        // check internet connection before requesting route data
        if !(await networkMonitor.waitForConnectionStatus()) {
            if !Task.isCancelled {
                selectedPoint = nil
                showNoInternet = true
            }
            return
        }

        // get current user location as the route starting point
        guard let from = locationService.currentLocation?.coordinate else {
            if !Task.isCancelled {
                selectedPoint = nil
                showLocationSettings = true
            }
            return
        }

        // stop execution if the task was cancelled
        if Task.isCancelled { return }

        // show route loading state for the selected transport mode
        isBuildingRoute = true
        loadingRouteMode = mode

        do {
            // request route from the backend through repository layer
            let fetchedRoute = try await repository.getRoute(
                from: from,
                to: point.coordinate,
                mode: mode.rawValue
            )

            // ignore response if a newer route request was started
            if Task.isCancelled { return }

            withAnimation(.spring()) {
                // save route and selected point for rendering on the map
                self.route = fetchedRoute
                self.routedPoint = point

                // close point details and reset loading state
                self.selectedPoint = nil
                self.isBuildingRoute = false
                self.loadingRouteMode = nil

                // move camera to show the full route
                focusOnRoute(fetchedRoute)
            }
        } catch {
            if !Task.isCancelled {
                withAnimation {
                    // reset loading state and show route error message
                    self.isBuildingRoute = false
                    self.loadingRouteMode = nil
                    self.selectedPoint = nil
                    self.showNoRouteToast = true
                }

                // hide error message after a short delay
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    withAnimation {
                        self.showNoRouteToast = false
                    }
                }
            }
        }
    }
}
```

=== HistoryRepositoryImpl

GitHub source file:
https://github.com/kshashkina/ReFood/blob/main/apps/ios/ReFood/ReFood/Data/ScannedHistory/HistoryRepositoryImpl.swift

The following fragment demonstrates how scanned products are stored locally using SwiftData. Existing records are updated when the same barcode is scanned again, preventing duplicate history entries.

```swift
func saveProduct(_ product: Product, isFavorite: Bool = false) async throws {

    // encode the full product object for local offline storage
    let data = try encoder.encode(product)

    let id = product.barcode
    let name = product.productName ?? String(localized: "common_unknown")
    let brand = product.brands ?? String(localized: "search_unknown_brand")
    let imageUrl = product.imageUrl

    // check whether the product already exists in local history
    let fetchDescriptor = FetchDescriptor<ScannedHistoryModel>(
        predicate: #Predicate { $0.id == id }
    )

    if let existing = try context.fetch(fetchDescriptor).first {

        // update the existing history entry after a repeated scan
        existing.scanDate = Date()
        existing.productData = data
        existing.productName = name
        existing.brand = brand
        existing.imageUrl = imageUrl

    } else {

        // create a new history record for a first-time scan
        let newModel = ScannedHistoryModel(
            id: id,
            productData: data,
            scanDate: Date(),
            isFavorite: isFavorite,
            productName: name,
            brand: brand,
            imageUrl: imageUrl
        )

        context.insert(newModel)
    }

    // persist all changes in SwiftData
    try context.save()
}
```

=== Authentication Flow
GitHub source file:
https://github.com/kshashkina/ReFood/blob/main/apps/ios/ReFood/ReFood/Domain/Auth/RegistrationDomain.swift

The main Apple ID linking flow is presented in Section 4.3.9. The full source code is referenced here because it additionally contains anonymous registration, reinstall recovery, account deletion and user data synchronization logic.