#import "@preview/hei-synd-thesis:0.1.1": *
#import "/metadata.typ": *

#pagebreak()
= Implementation

== Development Methodology and Team Organization

=== Agile Development Approach
The ReFood development followed the Agile methodology, organized into three sprints, each lasting one month. Given the small team size, we chose Agile over the formal Scrum approach, which allowed us to quickly adapt to changes in the project and implement the feedback received into the app.

Sprint Organization

- Each sprint began with planning and prioritizing tasks for the following month using the RICE framework.
- A lightweight product backlog was maintained throughout the project and served as the primary source for sprint planning. The complete initial backlog is provided in Appendix AA.
- During the sprint, we held meetings every two days to determine whether we were on track and to identify potential issues and areas where additional support was needed.
- At the end of each sprint, we received feedback from our supervisor and conducted a retrospective analysis of the previous sprint.

#figure(
  image("/resources/img/rice.png", width: 80%),
  caption: [Sprint 2 feature prioritization using the RICE framework.]
)

*Team Responsibilities Distribution:*
- *Yaroslava Mala:* Responsible for the entire serverless backend architecture, AWS cloud engineering and API integrations. This included developing all AWS Lambda microservices, configuring the NoSQL DynamoDB database, managing Amazon S3 bucket triggers and storage layout parameters, API gateway logic and executing third-party API integrations (Open Food Facts endpoints, Geoapify, PubMed and AI model).
- *Kateryna Shashkina:* Responsible for the entire iOS mobile client application and user experience layer. This included implementing the responsive iOS frontend using Swift and the declarative SwiftUI framework, designing interface components, managing layout views and setting up the complete client-side event tracking architecture via Amplitude Tracking to log, monitor and evaluate production analytics and user behavior patterns.

=== Iterative Design

Before implementing the final version of ReFood, several architectural and product decisions were validated through iterative prototyping.

*Architecture Validation*
- The application architecture was tested through several iterations of the client-side structure. Before finalizing the current architecture, based on Clean Architecture principles combined with MVVM for the presentation layer, various approaches to organizing the presentation, domain and data layers were evaluated. This approach ensured a clear separation of responsibilities while maintaining a reasonable implementation complexity for the mobile application.

*Database Design Validation*
- Early prototypes relied on retrieving historical data from the backend. During testing, this approach resulted in noticeable delays when opening scan history and reduced usability in poor network conditions. As a result, SwiftData was adopted to ensure local data storage and support offline operation.

*AI Service Evaluation*
- Multiple prompt structures were tested during development. Initial prompts produced inconsistent formatting and varying explanation quality. Through iterative refinement, structured prompts and predefined response formats were introduced, resulting in more predictable AI-generated product analyses.

*Recycling Infrastructure Research*
- Initially, we experimented with a direct OpenStreetMap solution. However, retrieving recycling points, searching nearby locations and generating routes was noticeably slower than expected and required additional processing on the backend side. As a result, Geoapify was selected because it provided significantly faster responses and better support for routing and geolocation features.

*User Interface and Responsive Layout Prototyping*
- Before finalizing the design, we created numerous prototypes and collected feedback from potential users. Based on user preferences, we adjusted the design, especially on the product details screen to ensure key information was clearly visible.

This iterative prototyping process significantly reduced risks and allowed us to validate our key architectural decisions before development began.

== Architectural Patterns and Coding Standards
Since the project has a distributed client-server architecture, architectural patterns and coding standards were adapted to the specifics of the server (Backend) and mobile (iOS Frontend) parts of the system.

=== Server-side architecture and patterns

The server-side component of the ReFood application is built using a serverless architecture with AWS Lambda. Each Lambda function is an independent microservice with a clearly defined scope of responsibility according the Single Responsibility Principle.

*Design and Cloud Architectural Patterns Implementation*

- *Front Controller:* Each Lambda function has a centralized entry point (`index.mjs`) that acts as a front controller. It receives invocation events from AWS API Gateway, checks the corresponding HTTP methods and resource routing paths and directs execution to the appropriate isolated function handler.

- *Cache-Aside Pattern:* This strategy is implemented in the product data gathering (`ProductHandler`). When a request for a product barcode arrives, we first check our own internal cache in DynamoDB. In the event of a cache miss, it fetches data from the Open Food Facts API, runs it through AI processing and stores the record in the database so that subsequent requests are retrieved from the database and are faster.

- *Data Mapper Pattern:* We used separate mapper modules to transform external data models into internal ones (for example, from the Open Food Facts API into our product model). This isolates the data transformation logic from the business logic.

- *Event-Driven Pattern:* Lambda function (`news-service`) is triggered not by HTTP requests, but by AWS events. It runs on a schedule via AWS EventBridge to automatically collect scientific publications. Additionally, s3-service responds to S3 events to validate uploaded images.

*Naming Conventions*

- CamelCase was used for file naming (for example `fetchOffApi.mjs`).
- Directory names reflect the module's role in the architecture: handlers/ - request handlers, services/ - interaction with infrastructure, helpers/ - utility functions, mappers/ - data transformation.
- Environment variable names are formatted in SCREAMING_SNAKE_CASE style.

=== Client-side architecture and patterns
*MVVM Architecture Implementation*

The ReFood application is built on the Model-View-ViewModel (MVVM) architectural pattern, which is one of the most common approaches when developing SwiftUI applications. This architecture provides a clear division of responsibility between the layers of the system and simplifies further support and development of the application.

- *Model* is responsible for storing and providing data. This layer includes product models and user data.
- *ViewModel* contains the business logic of the application. It is responsible for data processing and also prepares data for display in the user interface.
- *View* consists of declarative SwiftUI components responsible for displaying data and interacting with the user. The View is automatically updated when the state of the data in the ViewModel changes

*Key benefits:*
- Separation of Concerns: The user interface is completely isolated from the logic of working with the network or database.
- Reactive UI: The use of state properties (`@State`, `@Published`, `@Bindable`) allows the interface to update automatically without direct manipulation of elements.

#figure(
  image("/resources/img/mvvm.jpg", width: 55%),
  caption: [MVVM architectural pattern used in the ReFood.]
)

*Naming Conventions*

- PascalCase style was used for named structures, classes, protocols and enums  (for example, `ProductPreviewScreen`, `AnalyticsServiceProtocol`).
- CamelCase style was used for variables, constants and methods (for example, `scanBarcode()`).
- For localization keys, the snake_case style was used in accordance with the accepted structure of localization files.

*Design Pattern Implementation*

- *Observer / Reactive Pattern:* Used at the core of SwiftUI and Combine. UI components "subscribe" to changes in data models and react to them instantly.
- *Repository Pattern:* Implemented using SwiftData (`@Query` and `@Model`), which provides an offline approach to storing and quickly accessing scan history without constantly accessing the network.


== Critical Code Implementations
This section presents the key backend and iOS client implementations that form the core of the ReFood system.

=== User Handler: Implementation of User Services and Authentication

The ReFood app implements a hybrid identity model designed to maximize user retention. Users can launch and use the app completely anonymously, with their scan history and settings tracked instantly. At any time, the user can choose to upgrade to a fully authenticated account via Apple Sign-In without losing any accumulated data.

*Architectural Identity Lifecycle Flows:*
- Anonymous Session Onboarding: App Launch #sym.arrow AWS Amplify (Cognito Identity Pool) #sym.arrow POST /users/register #sym.arrow AWS Lambda (registerUser) #sym.arrow _the session is established using physical deviceId and AWS IAM temporary credentials attached to the identityId._
- Authenticated Account Linking Upgrade: Apple OAuth Sign-In #sym.arrow AWS Cognito User Pool Validation #sym.arrow JWT token (cognitoSub within claims) #sym.arrow POST /users/register/link-account #sym.arrow AWS Lambda (registerLinkAccount).

In this way, when a user deletes the app and reinstalls it, their anonymous data reappears because it is tied to deviceId. When a user signs in with Apple on any other iOS device - their full history and favorites are restored via cognitoSub.

*Anonymous Registration Implementation*

The following code snippet of `registerUser` processes initial device checks, updates outdated identityId tokens and guarantees database entity uniqueness using DynamoDB conditional checks:

```javascript
  ...
    try {
      const existingUser = await findUserByDevice(body.deviceId);

      if (existingUser) {
        // if identityId changed (e.g. Cognito refreshed it) - update it
        if (existingUser.identityId !== body.identityId) {
          await updateIdentityId(existingUser.userId, body.identityId);
        }
        return response(200, { message: "User recognized" });
      }

      const newUser = toUserDBModel(body.deviceId, body.identityId);

      try {
        await createUser(newUser);
      } catch (error) {
        // race condition guard: if two requests hit simultaneously
        if (error.name === 'ConditionalCheckFailedException') {
          const findedUser = await findUserByDevice(body.deviceId);
          if (findedUser) {
            return response(200, { message: "User recognized" });
          }
        }
        throw error;
      }

      return response(201, { message: "New user created" });
    }
  ...
```

*User DB Model*

```javascript
  export const toUserDBModel = (deviceId, identityId) => {
      return {
          userId: randomUUID(),       // our internal primary key
          deviceId: deviceId,         // physical device identifier
          identityId: identityId,     // AWS Cognito Identity Pool ID
          isPremium: false,
          scansCount: 0,
          createdAt: new Date().toISOString()
      };
  };
```

*Apple ID Account Linking Logic*

When transitioning into an authenticated state, the app sends a request to the /link-account endpoint. This handler transfers the anonymous data to a permanent user account.

```javascript
  ...
    try {
      // case 1: returning Apple user on a new/same device
      const existingAppleUser = await findUserByCognitoSub(cognitoSub);

      if (existingAppleUser) {
        await updateUserDevice(existingAppleUser.userId, deviceId);
        return response(200, { message: "Welcome back" });
      }

      // case 2: first Apple sign-in — link to the existing anonymous record
      const anonymousUser = await findUserByDevice(deviceId);

      if (anonymousUser) {
        await linkUserToApple(anonymousUser.userId, { cognitoSub, email, givenName });

        console.log(`Anonymous user linked to Apple: ${anonymousUser.userId}`);

        return response(200, { message: "Account linked" });
      }

      return response(409, { error: "No user session found for this device. Call /users/register first." });
    }
    ...
```
In that way, a shared helper extracts the caller's identity from either authentication method allowing all handlers to resolve a user uniformly.

```javascript
  export const getRequestIdentity = (event) => {
    // authenticated via Apple ID (JWT from Cognito User Pool)
    const jwtSub = event.requestContext.authorizer?.claims?.sub || event.requestContext.authorizer?.jwt?.claims?.sub;

    if (jwtSub) {
      return { type: 'jwt', id: jwtSub };
    }

    // anonymous user authenticated via Cognito Identity Pool (IAM)
    const identityId = event.requestContext.identity?.cognitoIdentityId;

    if (identityId) {
      return { type: 'identityId', id: identityId };
    }

    // for testing auth out of the prod stage
    const mockIdentityId = event.headers?.['x-mock-identity-id'];
    if (mockIdentityId && process.env.STAGE !== 'prod') {
      return { type: 'identityId', id: mockIdentityId };
    }

    return null;
  };
```

*Benefits:*

- *Easy to start:* No registration required to start scanning products.
- *Data persistence:* Anonymous scan history survives app reinstalls.
- *Seamless upgrade:* Apple Sign-In merges with existing anonymous data, no data loss.

=== Product Handler & AI Service: Intelligent Product Analysis

When a user scans a barcode, the system must: retrieve product information, translate it into Ukrainian and English and analyze the product's nutritional value using our AI Service. In addition, the system builds its own product database by collecting information from the Open Food Facts (OFF) API and enhancing it with translations generated by AI. This allows for a reduction in the number of external API calls in the future and shorter response times for repeat scans.

*Product Query and Fallback Cache Execution*

The getProduct handler manages cache queries, coordinates external data access and maps localized responses:

```javascript
  ...
    // step 1: check our own database first
    const dbProduct = await getLatestProductFromDB(barcode);
    if (dbProduct) {
      console.log(`Found product in DB for barcode: ${barcode}`);
      return response(200, {
        source: "local",
        product: dbProduct
      });
    }

    // step 2: fetch from Open Food Facts if not in local DB
    console.log(`DB miss, fetching from OFF: ${barcode}`);
    const offProduct = await fetchFromOpenFoodFacts(barcode);

    if (!offProduct) {
      return response(404, {
        error: "Product not found"
      });
    }

    // step 3: translate and structure via AI
    const translated = await translateProduct(offProduct);
    const { categories_tags, allergens_tags, ingredients_text, packaging, ...baseProduct } = offProduct;
    const product = { ...baseProduct, ...translated };

    // step 4: persist to our own database - next scan will be local
    await saveProductToDB(product);

  ...
```

*Fetching from Open Food Facts*

If the product is not found in the local database, the system queries the Open Food Facts API. This external dataset serves as the primary source for product information.

```javascript
  export async function fetchFromOpenFoodFacts(barcode) {
    const url = `${OFF_API_URL}/${barcode}.json`;

    try {
        const res = await fetch(url, {
            headers: {
                "User-Agent": USER_AGENT,
                Accept: "application/json",
            },
        });

        if (!res.ok) {
            console.error(`OFF API returned ${res.status}`);
            return null;
        }

        const data = await res.json();
        if (data.status !== 1) return null;

        const product = data.product || {};
        const barcodeFromAPI = product.barcode || product.code || data.code || barcode;

        return offProductToProduct(barcodeFromAPI, product);
    } catch (error) {
        console.error("OFF API Error:", error);
        return null;
    }
}
```

*Collaborative Data Contribution with AI Validation*

When a user manually enters data about a missing product, this creates serious security risks, such as unreliable text data and unverified images. The platform uses a two-tier verification process:

#underline[Prompt Injection Defense & AI Input Validation]: Before analysis, the user's text input is checked using special classification filters to detect malicious “prompt injection” attacks aimed at disrupting the artificial intelligence model. After that, our AI function checks each input field for unacceptable wording or unrealistic phrases.

#underline[Asynchronous Event-Driven Media Analysis]: User-submitted product images cannot be trusted or served immediately. The system decouples this workflow via an asynchronous event-driven pattern using AWS S3, Lambda AIService and AWS EventBridge.

*Image Verification Lifecycle Flow:*

Step 1: The iOS client requests a pre-signed URL and uploads the packaging image directly to a restricted transient directory (/temp/) within the AWS S3 bucket.

Step 2: The successful S3 image upload automatically emits an ObjectCreated state change event.

Step 3: AWS EventBridge intercepts this event and safely routes it to trigger an asynchronous background validation function.

Step 4: The background function passes the S3 image URI to the AIService using multimodal vision analysis to confirm if the file is a real product packaging image (checking for inappropriate content, blurring or mismatching data).

Step 5: The evaluation output is written to the UploadJobs table. Upon approval, the image is moved to the permanent production folder, updating the record status. If rejected, the job documents specific error details for client tracking.

The snippet code of `validateImage function`:

```javascript
  ...
    try {
        const imageUrl = `https://${BUCKET_NAME}.s3.amazonaws.com/${s3Key}`;
        const aiResult = await checkPhoto(imageUrl);       // call AI to check image

        const isValid = aiResult?.isValid ?? false;
        const error_en = aiResult?.error_en || null;
        const error_ua = aiResult?.error_ua || null;
        const status = isValid ? "APPROVED" : "REJECTED";

        // update for client to know about status of job
        await updateJobStatus(imageId, status, error_en, error_ua);

        results.push({ imageId, status });
    } catch (error) {
        await updateJobStatus(imageId, "REJECTED", {
            error_en: "Validation error. Please try again.",
            error_ua: "Помилка валідації. Спробуйте ще раз.",
        });
        results.push({ imageId, status: "REJECTED", error: error.message });
    }
  ...
```

*Benefits:*

- *Own product database:* Each OFF lookup is saved locally - subsequent scans are instant with no external API call.
- *Multilingual support:* AI translates product data to Ukrainian and English regardless of the original product language.
- *AI health analysis:* Users receive an immediate analysis of hidden sugars and harmful additives.
- *Safety gate:* User-submitted products must pass AI validation before entering the database.

=== Map Service: Geoinformation System and Routing

The Map Service provides recycling points search capabilities and navigation route generation for users. Both features integrate directly with the Geoapify API.

#underline[Geographic Data Storage and Licensing Compliance]: Under the Geoapify API license agreement, caching or persistently storing geographic coordinate points, spatial indexes and routing details in a local database is explicitly prohibited. The ReFood architecture strictly enforces this compliance by treating responses as transient data: they are fetched on-demand, processed, transformed in memory and immediately transmitted to the client. Additionally, this architectural design eliminates geospatial table maintenance and reduces DynamoDB storage requirements.

*Route Request Handler*

The following snippet of `getRoute` function represents the handler routing parameters, making external requests and returning simplified geometry coordinates:

```javascript
export async function getRoute(event) {
    try {
        const params = event.queryStringParameters || {};
        const fromLat = params.fromLat;
        const fromLon = params.fromLon;
        const toLat = params.toLat;
        const toLon = params.toLon;
        const mode = params.mode;

        if (!fromLat || !fromLon || !toLat || !toLon) {
            return response(400, {
                message: 'Missing required parameters: fromLat, fromLon, toLat, toLon'
            });
        }

        const rawData = await fetchRoute({
            fromLat,
            fromLon,
            toLat,
            toLon,
            mode: mode || 'walk'
        });

        const route = routeMapper(rawData);

        if (!route) {
            return response(404, {
                message: 'Route not found'
            });
        }

        // invoke metrics functions to update user statistics and achievements
        const identity = getRequestIdentity(event);
        const userId = await findUserIdByAnyMethod(identity);
        invokeMetrics('increment_sorted', userId);
        invokeMetrics('track_map_check', userId);

        return response(200, route);
    } catch (error) {
        console.error("Error occurred", error);
        return response(500, { message: "Internal Server Error" });
    }
}
```

*Benefits:*
- *License compliance:* All routing and geoinformation queries are processed without additional caching, ensuring full compliance with API provider licenses.
- *Zero storage overhead:* No local DynamoDB table storage or complex algorithm for routing is required on AWS.

=== Metrics Service: Gamification and Achievements Tracking

The ReFood backend implements a gamification system designed to increase user engagement. The gamification mechanics rely on a set of static achievements calculated dynamically from real-time user statistics stored in DynamoDB.

*Incremental Metrics System*

The following snippet showcases one part of metric logic's implementation - the increment of scanned product count in `incrementScanned` function:

```javascript
  ...
    // just incrementation for metric
    let updateExpr = "ADD scannedCount :inc SET lastUpdated = :now";
    const exprAttrValues = { ":inc": 1, ":now": now };

    // check if scanning matches any other achievements goals
    if (hour < 9) {
        updateExpr += ", earlyBirdUnlocked = :true";
        updateExpr += ", earlyBirdUnlockedAt = if_not_exists(earlyBirdUnlockedAt, :now)";
        exprAttrValues[":true"] = true;
    }

    if (isWeekend) {
        updateExpr += ", weekendHasScanned = :true";
        exprAttrValues[":true"] = true;
    }

    await docClient.send(new UpdateCommand({
        TableName: USER_METRICS_TABLE,
        Key: { userId },
        UpdateExpression: updateExpr,
        ExpressionAttributeValues: exprAttrValues
    }));

    if (isWeekend) {
        await checkAndSetEcoWeekend(userId, now);
    }
  ...
```

=== News Service: Research and Nutritional Education Materials

The News Service provides research studies and nutritional education materials to the application's daily dashboard. The service architecture separates into a scheduled background research aggregation pipeline via PubMed API query and AWS EventBridge scheduler.

*Automated Data Collection Process:*
- Scheduled update cycle: AWS EventBridge (daily scheduled rule) #sym.arrow AWS Lambda (fetchNews).
- External data retrieval: Query to the external NCBI PubMed HTTP API.
- Processing cycle: Analysis of internal parameters using `fast-xml-parser` #sym.arrow Filtering existing records using a quick search by primary key in local NoSQL tables.
- Data Processing: Executing an internal lambda #sym.arrow AWS Lambda (AIService: “process_research” action).
- AI translation and simplification: AI runs automatic summarization algorithms, removing complex terms and creating clear, structured arrays and translate information into both Ukrainian and English.
- Storage synchronization: Storing processed records in DynamoDB.

*PubMed Data Retrieval and Processing*

The following snippet represents the scheduled task that performs data retrieval and enrichment loop:

```javascript
export const fetchNews = async () => {
    const rawResearches = await fetchNewsFromPubMed();
    console.log(`Step 1: Found in PubMed: ${rawResearches.length}`);

    if (rawResearches.length === 0) {
        return { message: "No researches found" };
    }

    const newResearches = [];
    for (const item of rawResearches) {
        const alreadyExists = await checkNewsExists(item.id);
        if (!alreadyExists) {
            newResearches.push(item);
        }
    }

    if (newResearches.length === 0) {
        return { message: "All fetched news already exist in database" };
    }

    console.log(`Step 2: New articles to process: ${newResearches.length}`);

    const aiResponse = await processNewsWithAI(newResearches);
    const processedArticles = Array.isArray(aiResponse) ? aiResponse : (aiResponse.processed_news || []);

    console.log(`Step 3: AI responded with: ${JSON.stringify(aiResponse)}`);

    for (const processedItem of processedArticles) {
        const original = newResearches.find(r => r.id === processedItem.id);

        await saveNewsToDb({
            id: processedItem.id,
            date: original?.date || new Date().toISOString().split('T')[0],
            resource: original?.resource || "PubMed",
            ai_processed: processedItem
        });
    }

    return { message: `Successfully processed new articles` };
};
```

*Daily Dashboard handler*

When the client queries the daily summary, the database queries both the date-based tip and the latest 10 articles concurrently:

```javascript
export const getSummary = async (event) => {
    const requestTimestamp = event.requestContext?.timeEpoch ? new Date(event.requestContext.timeEpoch) : new Date();
    const tipDate = `${String(requestTimestamp.getUTCDate()).padStart(2, '0')}.${String(requestTimestamp.getUTCMonth() + 1).padStart(2, '0')}`;

    const [tipResult, newsResult] = await Promise.all([
        getDailyTip(tipDate),
        getLatestNewsFromDb(10)
    ]);

    return response(200, {
        date_utc: requestTimestamp.toISOString().split('T')[0],
        tip: tipResult.Item || null,
        news: newsResult || []
    });
};
```

*Benefits:*
- *Autonomic Ingestion:* Aggregation runs entirely in the background, requiring zero manual operations or content moderation.
- *Low-Latency Serving:* Scientific article aggregation and AI translations are done ahead of time. Therefore client dashboard reads require only quick concurrent queries.

=== iOS Scanner Service: Barcode Recognition and Session Control

Barcode scanning functionality was implemented as a separate service based on the `AVFoundation` framework. To avoid coupling the user interface directly to the camera API, all core scanner operations were abstracted into the `BarcodeScanning` protocol. It defines methods for configuring the scanner, starting and stopping scanning, resetting the state and controlling the device's flashlight.

The `BarcodeScannerService` manages an `AVCaptureSession` object and performs camera configuration in a separate background queue. By using this approach we avoid blocking the main thread and can maintain smooth UI operation. The scanner supports the most common barcode formats that are used on product packaging, like EAN-13, EAN-8, UPC-E and Code 128.

One important implementation feature is protection against scanning of the same barcode multiple times. After the first barcode is successfully recognized, the service sets an internal flag and ignores subsequent scans until the user initiates a new scan. This prevents sending multiple identical requests if the camera is still pointed at the same product.

The `ScannerViewModel` controls the scanner's operation. After receiving a barcode, the ViewModel stores its value, stops the camera and initiates an asynchronous download of product information:

```swift
private func bindScanner() {
    scanner.onCodeScanned = { [weak self] code in
        guard let self else { return }

        // save the detected barcode
        self.scannedCode = code
        self.lastScannedBarcode = code

        // stop the camera session to prevent duplicate scans
        self.stopScanning()

        // load product information asynchronously
        Task {
            await self.loadProduct(barcode: code)
        }
    }
}
```

A separate `CameraPermissionService` component was also implemented. It is responsible for checking and requesting camera permissions. This allows the application to correctly handle various access scenarios, including allowed, denied and restricted access to the camera.

Appendix AB provides selected implementation fragments of the scanner service. The complete source code is available in the project GitHub repository.

=== Map Flow: Geodata Loading and Route Requests

The iOS app's map functionality was implemented using `MapKit` and a separate `MapViewModel` component. This component is responsible for loading recycling points, handling map movement, applying filters by material type, building routes and managing user interface state.

To handle geolocation, separate services like `LocationService` and `LocationPermissionService` were implemented. The first one provides the user's current coordinates via `CLLocationManager` and the other one is responsible for checking and requesting geolocation permissions.

Retrieving recycling points and building routes is performed through the `LocationRepository` layer, which hides the details of interaction with the backend API. The repository executes network requests, converts server responses into `MapPoint` and `MapRoute` models and then passes them to the `ViewModel` for display on the map.

One of the key solutions was managing the loading of geodata as the map moves. Instead of executing a new request every time the camera position changes, the app saves the coordinates of the last successfully loaded area and calculates the distance to the new map center. If the user has moved far enough, the app either automatically downloads new data in user tracking mode or displays a `"Search in this Area"` button, allowing the user to initiate a search. This approach significantly reduces the number of network requests and reduces the load on external APIs.

```swift
func onCameraChange(context: MapCameraUpdateContext) {
    // store the current camera position and map center
    currentMapCenter = context.region.center
    currentCamera = context.camera

    // initial data load when the map is opened for the first time
    if lastFetchedCenter == nil {
        fetchData(center: context.region.center)
    } else if let lastCenter = lastFetchedCenter {

        // calculate distance between the previous and current map centers
        let distance = CLLocation(
            latitude: context.region.center.latitude,
            longitude: context.region.center.longitude
        ).distance(from: CLLocation(
            latitude: lastCenter.latitude,
            longitude: lastCenter.longitude
        ))

        // trigger loading only when the user moved far enough
        if distance > MapConstants.fetchThreshold {

            // automatically refresh points while following user location
            if trackingMode != .none {
                fetchData(center: context.region.center)

            // otherwise show "Search in this Area" button
            } else {
                withAnimation(.spring()) {
                    showSearchButton = true
                }
            }
        }
    }
}
```

Route construction is also performed asynchronously. Before sending a request, the app checks for an internet connection and the user's current geolocation. After successfully receiving the route, the ViewModel saves it and automatically adjusts the camera position so that the entire route is within the user's view.

Appendix AB provides selected implementation fragments of the map service. The complete source code is available in the project GitHub repository.

=== SwiftData Scan History and Local Metrics: Offline-First Persistence

The iOS app's scan history was implemented using an offline-first approach with `SwiftData`. This solution allows users to view previously scanned products even without an internet connection, which is especially important in supermarkets where mobile networks can be unstable.

The history is stored using the `ScannedHistoryModel` model, annotated with the `@Model` macro. It stores the product's unique ID, scan date, favorite status, name, brand, image link and serialized product data. The id field is marked as unique, so rescanning the same product doesn't create a duplicate but updates the existing record.

Local storage is handled in the `HistoryRepository` layer. This approach hides `SwiftData` details from the `ViewModel` and maintains a clean separation of concerns.

In addition to history, local user metrics are also stored on the client. This is accomplished using the `MetricsRepository`, which stores scan counters, sort counters, streak counters and achievement status.

The `ScannerViewModel` is one example of a point where various types of data are updated after a product is successfully loaded. In this flow, the application increments the local scan counter, saves the product to local history and additionally sends a scan event to the backend:

```swift
self.product = fetchedProduct

// update local scan metric for profile and achievements
metricsRepository.incrementScannedCount()

Task {
    // save product locally for offline scan history
    try? await historyRepository.saveProduct(fetchedProduct, isFavorite: false)

    // record scan on backend for server-side history and statistics
    try? await productRepository.recordScan(product: fetchedProduct)
}
```

It is important to note that this fragment is just one example of data recording on the client. A similar approach is used in other parts of the application: when manually entering a barcode, adding new products, changing the status of a favorite product and confirming successful sorting.

Within `HistoryRepositoryImpl`, the product is first encoded as `JSON` data, after which the repository checks whether a record with the same barcode already exists. If the record already exists, the scan date, product details, name, brand and image are updated. If the product is being scanned for the first time, a new record is created in the local database.

Appendix AB provides selected implementation fragments of the local history. The complete source code is available in the project GitHub repository.

=== iOS Authentication Flow: Anonymous Session and Apple ID Linking

ReFood's authorization system was implemented so that users can start using the app without mandatory registration. Instead of creating an account on first launch, the app automatically creates an anonymous user session, which allows access to all the app's core features.

The authorization logic is divided between several components. `AmplifyAuthRepository` handles interactions with `AWS Cognito` and `Apple Sign-In`, `UserRepositoryImpl` makes requests to the backend API and separate `Use Case` components manage anonymous user registration, Apple ID linking and data synchronization.

During the first app launch, anonymous user registration occurs. The client receives the `Cognito identityId`, combines it with the stored `deviceId` and sends this data to the backend. As a result, the server creates or updates an anonymous user session, which is used to store scan history, user preferences and statistics until the Apple ID is linked.

Particular attention was paid to the app reinstallation scenario. To achieve this, the `device ID` is stored in the `Keychain`, which is not cleared when the app is uninstalled. During the next launch, the client detects the existing device ID and initiates a user data sync. This allows scan history, favorites, achievements and user metrics to be restored even without first registering with an Apple ID.

When the user selects `Apple ID sign-in`, the app initiates the standard authorization process through AWS Amplify. After successful sign-in, the client receives a `Cognito ID Token` and passes it, along with the device ID, to the backend to link the anonymous account to the Apple profile:

```swift
func execute() async throws {

    // perform Apple Sign-In through AWS Amplify and receive Cognito ID token
    let idToken = try await authRepository.signInWithApple()

    // get persistent device identifier stored in Keychain
    let deviceId = deviceIDProvider.getDeviceID()

    // send token and device ID to backend to link anonymous data with Apple account
    try await userRepository.linkAccount(
        idToken: idToken,
        deviceId: deviceId
    )

    // save local flag that the account has been linked with Apple ID
    localStorage.isAppleLinked = true

    // synchronize scans, favorites, achievements and metrics in the background
    Task(priority: .background) {
        await syncUseCase.execute()
    }
}
```

After linking the account, the app initiates background synchronization of user data. This synchronization process downloads scan history, favorites, achievements and user metrics from the backend, merges the data with the local app state and stores it on the device. This allows the user to continue using the app on a new device without losing their progress.

Appendix AB provides selected implementation fragments of the authentication service. The complete source code is available in the project GitHub repository.

== Testing Approach and Quality Assurance Measures

This section describes in detail the testing methods and tools that were applied to the entire project code base to ensure the stability and reliability of the client and server components of the system.

=== Server-side testing approach

To ensure the stability and reliability of the ReFood serverless backend, a testing strategy for modular testing of Lambda functions was developed using the *Vitest* framework.

*Mocking Strategy*

To avoid dependencies on actual cloud infrastructure during testing, a system of mock objects was implemented using the `vi.mock()` mechanism built into Vitest. All external dependencies are mocked:

- AWS SDK (`@aws-sdk/client-dynamodb`, `@aws-sdk/lib-dynamodb`, `@aws-sdk/client-s3`) to isolate from actual calls to DynamoDB and S3.
- Service layer modules (`newsDatabase.mjs`, `userMetricsDatabase.mjs`, `aiService.mjs`) - to verify the business logic of handlers independently of the infrastructure.
- Mock Lambda functions - for testing cross-service interactions without actual calls through AWS.

This approach allows us to run a full list of tests locally without access to the AWS environment and without any financial costs for cloud resources.

*Unit Testing*
The core business logic of the server-side is covered by unit tests using the *Vitest* framework. Testing is performed at the level of individual Lambda functions. The main areas of testing include:

- *Routing:* Verifying the correct differentiation of input event types - HTTP requests, EventBridge triggers and direct Lambda invocation and delegating them to the appropriate handlers with the return of correct status codes.

- *Business logic and calculations:* Validation of data transfer and processing logic and algorithms. Specifically, tracking user gamification progress for numerical and boolean achievement types.

- *Input data validation:* Verifying the validation of required parameters and their format before processing.

- *Testing positive and negative scenarios:* Each logic path is covered by tests for both the expected successful outcome and failure scenarios like database unavailability, AI service errors and invalid input data.

In total, 374 unit tests were implemented to verify the Lambda business logic. All 374 tests passed successfully, confirming the stability and high reliability of the serverless backend.

*Alternative Approaches and Rationale*

When designing the QA strategy, alternative approaches were considered, including integration testing with actual AWS resources. However, the decision was made to focus on unit testing with full AWS mocking. This strategy is justified by several factors:
- It ensures predictable and reproducible behavior independent of the state of the cloud infrastructure.
- It provides significantly faster test execution.
- It allows us to test edge cases (DynamoDB unavailability, AI service errors) that are difficult to reproduce in a real environment.

=== Client-side testing approach

To ensure the stability and reliability of the ReFood mobile client, a testing strategy based on the MVVM architecture was implemented.

*Mocking Strategy*

To avoid dependence on real network requests during testing, a system of mock objects was created, for example:
- A MockProductRepository was implemented, which mimics the behavior of the ProductRepository protocol.
- This mock object allows you to simulate asynchronous operations, such as receiving a product.

*Unit Testing*

The main business logic of the application is covered by unit tests using the native XCTest framework. Testing is performed at the ViewModel level. The main areas of testing include:
- *Localization and Fallback Logic*: Verifying the correct display of multilingual content (English and Ukrainian) using a `MockLanguageProvider` and ensuring that missing or incomplete backend data gracefully falls back to default values without causing application crashes.
- *Business Logic and Calculations*: Validating complex algorithms, such as tracking gamification progress for user achievements and determining the healthier product in the comparison module.
- *Asynchronous State Management*: Verifying the correct handling of concurrent tasks, which includes preventing duplicate network requests during barcode searches and ensuring UI loading indicators behave predictably during simulated API delays.
- *Data Validation*: Ensuring strict validation of user inputs before data is processed, such as trimming whitespaces from barcodes, verifying string lengths and correctly parsing decimal numbers in the product creation forms.

In total, 175 unit tests were implemented to verify ViewModels logic. All 175 tests passed successfully, confirming the stability of the main client-side logic.

*Alternative Approaches and Justification*

When designing the QA strategy, alternative approaches were considered, including the use of Behavior-Driven Development frameworks such as Quick and Nimble, as well as libraries for auto-generation of mock objects (for example, Cuckoo or SwiftyMocky). However, it was decided to abandon third-party solutions in favor of the native XCTest framework and the creation of manual mocks. This choice was justified by the desire to minimize the number of external dependencies in the project, which guarantees higher stability, security and perfect compatibility with future updates of the Apple ecosystem.

In addition, testing business logic through the graphical interface using XCUITest (UI Testing) was considered as an alternative. However, given the MVVM architecture, priority was given to unit testing of the ViewModel level. This solution avoided the "unstable tests" problem inherent in UI testing and provided significantly higher test execution speed due to complete isolation of logic from interface rendering and real network requests.

== Performance Optimizations

This section discusses performance problems and their solutions that arose during the development of both the server and client parts of the application.

=== Server-side performance optimization

On the server side, the main focus was on reducing request processing latency, optimizing calls to external services and avoiding overload on the cloud infrastructure.

*Bottleneck of Repeated AI Calls During Product Scanning*

- *Problem:* If AI product analysis were performed with every scan, this would result in two major operational costs—in terms of both time and money—and with a large number of users, these costs would increase proportionally to the number of scans of the same product. Additionally, generative models can produce different responses each time they are requested, which would mean that different users would receive differently worded analyses of the same product.

- *Solution:* AI product analysis is performed exactly once when the product is first saved to the database. The result (`analysis_ua`, `analysis_en`) is stored along with the product and subsequently returned to all users without repeated AI calls. This ensures the consistent conclusion for every user and completely eliminates AI costs during subsequent scans of the same barcode.

*Bottleneck in Long-Running Photo Processing*

- *Problem:* AI analysis of an uploaded image is an asynchronous operation that can take several seconds. Keeping the HTTP connection open for the entire duration of processing is inefficient: it ties up client-side resources and increases the risk of a connection timeout.

- *Solution:* An asynchronous approach based on the Job Status pattern has been implemented. Upon receiving a presigned URL for upload, a task record with the status `PENDING` is created in the database. After the file is uploaded, an S3 event automatically triggers a Lambda function that performs AI validation and updates the task status to `APPROVED` or `REJECTED`. The client, in turn, periodically sends polling requests to a separate `job-status-checker` endpoint (`GET /image-validation`) to check the current processing status. This approach eliminates the need to keep a long-lived connection open.

*Metrics Service Call Bottleneck*

- *Problem:* After each scan or product creation, the user metrics achievement must be updated. Synchronously waiting for a response from `metrics-service` increased the API total response time by the duration of DynamoDB operations that are not critical to the main query result.

- *Solution:* The `metrics-service` call was switched to asynchronous mode (`InvocationType: “Event”`). The function initiates the metric update and immediately returns a response to the client without waiting for the operation to complete. This allowed us to reduce the response time of the main endpoints without losing data.

*Bottleneck of Repeated AI Calls In NewsPipeline*

- *Problem:* The daily news collection pipeline from PubMed could send articles that already existed in the database to the AI service for processing. Each call to the AI service is relatively slow and can be a costly operation, so processing duplicates led to wasted resources.

- *Solution:* A deduplication step was introduced before sending articles to the AI: for each received publication, we verify its existence in the database (`checkNewsExists`). Only new content is sent to the AI service, which significantly reduces the number of calls.

=== Client-side performance optimizations

In the case of the mobile client, the main attention was paid to optimizing the operation of hardware components, reducing the number of redundant network requests and preventing interface freezes when processing large arrays of local data.

*Scanner Bottleneck*

- *Problem:* The constant search for a barcode by the camera heavily loaded the processor and could cause the device to overheat. In addition, if the process is not interrupted after a successful scan, the application inevitably enters an endless cycle of recognizing the same code, blocking further logic.
- *Solution:* The scanner logic was designed in such a way to instantly stop the video capture session (`AVCaptureSession`) and disable frame analysis immediately after the first successful reading. Scanning resumes only after an explicit user action (for example, when closing the product details window or pressing the rescan button).

*Map API Bottleneck*

- *Problem:* Every time the user moves the map, the application could initiate dozens or hundreds of requests to the server to load recycling points. This would overload the network, exhaust API quotas and lead to critical crashes of the graphical interface.
- *Solution:* Camera movement state tracking was implemented. Instead of automatically loading data with each screen shift, the application waits for the complete stop of the map and shows the search button. The request for recycling points in a specific radius is performed only once and at the explicit command of the user, which radically optimized the consumption of resources.

*Search UI Bottleneck*

- *Problem:* On the search screen (`SearchView`), the list of scanned history is reactively updated every time the user enters a new character, change the focus or switch tabs. Deserialization of "heavy" JSON data (productData) for hundreds or thousands of elements in real time with each such update of the interface would lead to a strong drop in performance.
- *Solution:* In `SearchViewModel`, the preliminary filtering strategy was applied. Matched text search and "favorite" status check are performed on lightweight properties of the local model (such as name and brand) before JSON processing begins. The resource-intensive operation JSONDecoder().decode is called only for those elements that have already passed filtering, which allows the search to work instantly regardless of the size of the scanned history.

== Deployment and Configuration Management
=== Server-side deployment

The ReFood app deployment is based on AWS's public global infrastructure, where everything is geographically localized within a single region (`eu-north-1`, Stockholm) to ensure minimal network latency for European and Ukrainian users.

*Automated Deployment via CI/CD*

To automate the deployment of the application server-side components, a separate GitHub Actions pipeline has been set up for each Lambda function. Each workflow triggers automatically when changes are pushed to the `main` branch - but only if the changes affect the directory of the corresponding service. This means that changes in one service do not trigger a redeployment of others, which minimizes the number of unnecessary deployment operations.

Each pipeline consists of four sequential steps: fetching code from the repository, running automated unit tests, installing production dependencies, packaging the function into a ZIP archive and uploading the new code to AWS Lambda via the AWS CLI. This approach ensures a fully automated and reproducible deployment process: any code change merged into the main branch is automatically deployed to the production environment without manual intervention.

#figure(
  image("/resources/img/github-deploy.png", width: 80%),
  caption: [GitHub Actions CI/CD workflows for ReFood serverless microservices],
)

CI/CD Pipeline Features:
- *Path-Based Triggering*: Workflows utilize precise directory filters (paths), ensuring that only modified Lambda services are tested and deployed, optimizing overall build time.
- *Automated Quality Check*: Before any deployment, the pipeline automatically runs appropriate tests via Vitest. If any of the server-side unit tests fail, the workflow terminates immediately.
- *Secure Environment Management*: AWS access credentials are stored as encrypted GitHub Secrets or inside Lambda environment variables and do not appear in text anywhere in the code.

=== Client-side deployment

The practical process of deploying the ReFood mobile client and managing its configurations had a clear sequence of actions, which was performed immediately after the development and testing of the code base was completed. This process consisted of several key stages:

*Release Build*

After completing the active coding phase in Xcode, using a registered Apple Developer account, the project archiving process was initiated. The result of this step was the creation of a ready-to-deploy installation package in `.ipa` format.

*Testing via TestFlight*

The generated .ipa file was exported directly from Xcode and uploaded to the App Store Connect cloud system. To test the application in real conditions, the TestFlight platform was configured. Through it, the build was sent to real iPhones of the development team members, which allowed us to identify and fix minor interface bugs before the official publication.

*App configuration in App Store Connect*

At the final stage, in parallel with testing, the application's product page was prepared for release. In the App Store Connect account, text descriptions and keywords were filled in, real screenshots of the application screens were uploaded and the security section was configured.

== API Documentation

Since the backend is built on independent AWS Lambda functions managed by AWS API Gateway, the client interaction contract is defined at the cloud infrastructure level. To ensure full synchronization between the gateway, the iOS app and the endpoint descriptions, a unified specification was developed and integrated directly into the GitHub repository.

The consolidated route matrix, which reflects interactions with users, products, geodata and media files via the corresponding Lambda handlers, is presented below:

#figure(
  image("/resources/img/api-matrix.png", width: 80%),
  caption: [REST API Routing Matrix for ReFood],
)

Documentation components and implemented standards:
- *API Reference (`API_DOC.md`):* an integrated Markdown specification describing endpoint behavior, HTTP methods, required path parameters, JSON request/response structures and error handling schemes.
- *Distributed REST entry points:* routes are clearly separated by domain (`/product/*` for products, `/users/*` for profiles and gamification, `/map/*` for maps), which reduces the interdependence of services.
- *Flexible client integration:* a direct link to the documentation in the README.md file allows iOS developers to interact with the backend independently and build new features in parallel without delays.

The full text of the API specifications is provided in Appendix AD.