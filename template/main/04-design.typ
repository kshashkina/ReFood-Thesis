#import "/local-lib/template-thesis.typ": *
#import "/metadata.typ": *
#pagebreak()
= System Design

== System Architecture and Design Rationale

Based on the results of our marketing research and gap analysis, we identified a number of important user needs that remain unmet by existing solutions on the market. These requirements formed the basis for developing key functional and non-functional requirements for the ReFood app.

Our primary goal was to create a scalable and maintainable solution that would combine the proper food selection and recycling process within a single platform.

The following sections detail how the identified functional and non-functional requirements were translated into specific engineering solutions and influenced the product's architecture and implementation.

=== Mapping Requirements to Architectural Components

*Functional Requirements and Corresponding Architectural Decisions*
- *Scanning and Manual Entry*: The system must allow users to scan barcodes or manually enter them to instantly retrieve all the data about the product (Nutri-Score, Eco-Score, ingredients, allergens, nutrients) and provide an AI analysis of the fetched product.

  -- Architectural Decision: We utilize a protocol-oriented AVFoundation service for high-performance barcode decoding, coupled with a repository-based API layer to fetch and process product data.

- *Recycling Navigation and Map Integration*: Users must be able to view packaging components, transition to a "How to sort" flow and locate nearby recycling points filtered by material (e.g., plastic, glass). The map must support routing, "search this area" functionality and default locations if geolocation is disabled.

  -- Architectural Decision: We integrated Apple's MapKit framework on the frontend to manage client-side rendering, visualization grouping and searches outside a specific area. The backend delegates computing workloads onto the transient `MapService` Lambda, which interacts with Geoapify APIs on demand to compute real-time routing structures without introducing local data storage overhead and to comply with API usage rules.

- *User Dashboard and History Management*: The Home screen must display dynamic content (Eco Tip, News, recent scans, current statistics), while the Search screen provides a complete history with filtering (all/favorites) and like/dislike capabilities

  -- Architectural design: The server-side handles content generation asynchronously by scheduling daily Amazon EventBridge events that fill the `News` table in DynamoDB. Scanned products are stored in a separate `Scans` table and are recorded with every product search. The `ProductsFavorites` table is filled separately when the like button is clicked on the client. In this way, we divide the tables into separate logical components that are independent and easy to modify and scale.

- *Seamless Authentication and Data Portability*: Users must be able to log in via Apple ID to securely save their data. If the app is deleted and reinstalled, the user's entire scan history, favorites and statistics must be fully restored upon login.

  -- Architectural Decision: We implemented a dual-identity model using the AWS Cognito Identity Pool for temporary anonymous device tracking and the AWS Cognito User Pool for authentication via Apple ID. The backend service uses a merge logic to combine the device associated history (anonymous user) with the persistent Apple credentials (registered user) without data loss.

- *Gamification & Progress Tracking*: The system must track user interactions, displaying a daily streak, scanned/sorted counts and an Achievements tab with 8 distinct unlockable milestones.

  -- Architectural Decision: User metric updates are processed in an asynchronous way that managed by a dedicated Lambda function - `MetricsService` to avoid blocking core user interactions. This service analyzes incoming action signals, calculates and updates data in the `UserMetrics` table and evaluates achievements based on a static configuration of achievements.

- *Community Crowdsourcing (Add and Edit)*: If a product is missing or contains incorrect/poor-quality data (e.g., bad photos), the user must be able to submit new information or edits via a form for backend validation.

  -- Architectural Decision: We implemented an AI validation process that runs when a user fills out a form, using `AIService` to check for suspicious, unusual or invalid entered data. Attached images are transferred to a temporary S3 bucket, which publishes `ObjectCreated` triggers to EventBridge, which invokes the AI before the records are moved to the public bucket. Thus, the AI result for the provided image is stored for 24 hours in `UploadJobs` and are pinged by the client until a REJECT or APPROVED status is received.

- *Smart Product Comparison*: The app must support a "Compare Mode" where a user can scan a second product, confirm the comparison and view a side-by-side UI of nutrients. An AI analysis must determine and explain the "winner."

  -- Architectural Decision: The comparison mechanism uses `AIService`, which sends comparison requests via Vertex AI (Gemini LLM), compares the features of two products and returns the comparison results to the client.

*Non-Functional Requirements and Corresponding Architectural Decisions*

- *Availability and Offline Data*: Users frequently experience poor cellular network connectivity inside supermarkets. The application must provide continuous access to previously scanned items, favorites and gamification progress regardless of the current internet connection.

  -- Architectural Decision: To ensure uninterrupted access to data, an “Offline-First” approach has been implemented using the native SwiftData framework. All scanned products and interaction history are immediately stored in the device's local database using `@Model` macros. The user interface is subscribed to local data via the `@Query` macro. This means that the app always reads data from the phone's memory (which works instantly and without an internet connection), so the user can always view their scan history even in “airplane mode”.

- *Performance and UI Responsiveness*: The mobile application must maintain a highly responsive interface (targeting 60 FPS) and avoid any freezing or UI blocking during heavy API requests, AI processing or data synchronization.

  -- Architectural Decision: To prevent the interface from freezing while loading images or waiting for a response from the backend, several architectural decisions were made. All network requests, JSON parsing and image processing are implemented using the async/await mechanism. This allows “heavy” tasks to be executed in background threads, completely freeing up the UI thread. The `@MainActor` attribute is used for ViewModel classes. This ensures that any state change (e.g. displaying a loading indicator) that affects the UI is safely executed exclusively on the main thread, preventing crashes and animation stuttering.

- *Security and Data Privacy*: Personal user data, scan history and authentication tokens must be strictly isolated, securely transmitted and protected against unauthorized access.

  -- Architectural Decision: All data transmission from the client to the server is secured using the HTTPS protocol at the AWS API Gateway level, which validates short lived Cognito authentication tokens. DynamoDB tables and S3 buckets are controlled by detailed access policies through the appropriate IAM policies to restrict data access and mitigate the risk of data leaks.

== C4 Context Diagram

The system context diagram illustrates the ReFood app's position at the highest level of abstraction and its interaction with the external environment - users and third-party integration services (APIs). The diagram highlights key external entities that interact with the system, including users who scan products, view recycling information and manage their profiles, as well as third-party services such as product API, geolocation API, scientific research API and AI-based data processing API. This contextual overview provides a clear understanding of the system's scope of application and its interaction with external entities.

#figure(
  image("/resources/img/c4-context-diagram.png", width: 80%),
  caption: [System Context Diagram - ReFood App Ecosystem],
)

*Justification for the selection of external integrations and analysis of alternatives*

To ensure the application's business functionality we conducted an analysis of available solutions and selected the following external systems:

- *Open Food Facts API*
  - *Selected option:* The Open Food Facts (OFF) API - a global open crowdsourced database for barcode recognition, retrieving Nutri-Score and Eco-Score ratings, product ingredients and detailed packaging information. This is how we populate our database, ensuring we have the latest product data and integrating both local and outsourced sources.
  - *Alternatives:* Commercial product catalogs (Barcode Lookup API, Go-UPC API) or building a custom database from scratch by parsing online supermarket data.
  - *Comparison:* Commercial alternatives have strict limits on free queries (mostly paid commercial plans) and a small database of Ukrainian local brands. Building our own database from scratch at the start of the project would have resulted in a persistent `404 Not Found` error for 95% of products. In contrast, the Open Food Facts API is completely free, supports millions of products from around the world (including the Ukrainian market) and allows us to use the “Cache-Aside” architectural pattern. If a product isn't in our DynamoDB database - we fetch it from OFF, localize it using AI and store it locally in the database, thus expanding our own product catalog.

- *Geoapify API*
  - *Selected option:* Integration of the Geoapify API to enable real-time search for map points, filtering them by material type and the creation of walking, cycling or driving routes.
  - *Alternatives:* Direct fetching and parsing of raw geodata from OpenStreetMap (OSM) or deploying a custom server based on OSRM (Open Source Routing Machine).
  - *Comparison:* Direct data extraction from OSM would have required writing complex, rather heavy queries on the Lambda side, which led to significant response delays and user interface freezes. Initially, we tried using direct fetching, but this held our system back in development. It also complicated the logic for storing and building routes, which led to increased product maintenance (which we cannot afford at the MVP stage). Therefore, working with geodata directly forced us to rethink our approach to constantly updating coordinates and our limited AWS cloud budget. Instead, we found a suitable alternative that we are currently using - the Geoapify service. It provides a ready-to-use, fast fetch (response < 200ms), handles coordinate validation and builds accurate route graphs. Thus, at this stage of product development, we can provide users with a convenient, fast interface that displays processing points and routes to them.

    #underline[Geographic Data Storage and Licensing Compliance]: Under the Geoapify API license agreement, caching or persistently storing geographic coordinate points, spatial indexes and routing details in a local database is explicitly prohibited. The ReFood architecture strictly enforces this compliance by treating responses as transient data: they are fetched on-demand, processed, transformed in memory and immediately transmitted to the client. Additionally, this architectural design eliminates geospatial table maintenance and reduces DynamoDB storage requirements.

- *Gemini LLM API*
  - *Selected option:*  Using Gemini models via the API to translate complex ingredients into understandable language, detect hidden sugars, compare two products and protect the system against prompt injection and inappropriate content when users add products.
  - *Alternatives:* OpenAI services (GPT-4o) or our own LLM.
  - *Comparison:* OpenAI (GPT) has a higher token cost, which is critical for us given the limited budget for our diploma project. Deploying our own LLM model would require constantly running server resources and thus, the maintenance cost would exceed several hundred dollars per month. The Gemini service provided the best free request limit for development, high-speed generation of structured JSON response, processing of both text and images and excellent performance with the Ukrainian language.

- *NCBI PubMed API*
  - *Selected option:* Integration with the official API of the U.S. National Center for Biotechnology Information for the daily automatic collection of the latest medical and nutritional articles.
  - *Alternatives:* Manually populating the dashboard with articles from the internet.
  - *Comparison:* Manual data entry contradicts the principles of software engineering automation. Additionally, unverified data obtained from the internet or AI chatbots would significantly undermine trust in the application. In contrast, the PubMed API provides a standardized, validated and strictly structured XML data format. This allowed us to implement a fully autonomous service: a Lambda function retrieves pure scientific facts once a day (at night), passes them to AI to filter out complex medical terminology and displays verified information to the user in the feed without any human intervention. We also provide a direct link to the article, which increases user trust.

- *Amplitude Tracking*
  - *Selected option:* Amplitude, a platform for collecting customer metrics and behavioral events in real time.
  - *Alternatives:* A custom analytics table in DynamoDB or Firebase Analytics integration.
  - *Comparison:* Firebase Analytics is geared toward general marketing and the Google ecosystem, which makes it difficult to build custom conversion funnels for SwiftUI interfaces. Recording every user click in a custom DynamoDB table would place a massive financial burden on the database due to the high frequency of write operations. Amplitude provides a ready to use SDK for iOS that bundles events for free, sends them in the background without taxing the device's CPU and gives us dashboards for UX analysis without having to write visualization code.

== C4 Container Diagram

The container diagram details ReFood's high-level architecture, dividing the system into logical functional blocks that are deployed independently. This level of architectural design reflects the division of responsibilities among the mobile client, the serverless cloud infrastructure and data storage systems and defines the technical protocols for their interaction.

#figure(
  image("/resources/img/c4-container-diagram.png", width: 80%),
  caption: [System Container Diagram - ReFood App Ecosystem],
)

*Rationale for choosing a cloud infrastructure and analysis of technical trade-offs*

The serverless computing pattern formed the basis of the architectural choice for the ReFood backend platform. The main goal of this solution is to ensure linear scaling of the system in line with user request intensity, completely eliminate financial costs for maintaining infrastructure during the periods of low activity (we pay only for actual usage) and minimize operational overhead.

- *AWS API Gateway*
  - *Selected option:* REST HTTP gateway that serves as the single entry point for the mobile app, providing CORS validation, token authorization and request routing.
  - *Benefits:* AWS API Gateway integrates with the rest of the AWS services, automatically scales to handle millions of requests and charges only for calls actually processed.

- *AWS Lambda*
  - *Selected option:* A serverless code execution environment (Node.js v24) in the form of isolated microservices that are triggered in response to events from API Gateway, EventBridge or a direct invocation Lambda.
  - *Alternatives:* Traditional monolithic or containerized architecture running on AWS EC2.
  - *Comparison and benefits:* Classic servers run 24/7, which means a constant cost for computing power, even when no one is using the application (for example, during periods of lowest demand - at night). Using AWS Lambda allowed us to break down the logic into atomic, independent functions (`UserHandler`, `ProductHandler` and others.). This ensures fault isolation (if the news service goes down, the scanning continues to work) and automatic horizontal scaling of each function separately.

- *AWS DynamoDB*
  - *Selected option:*  A fully managed key-value NoSQL database (DynamoDB) that delivers consistent response times of a few milliseconds at any scale.
  - *Alternatives:* Relational databases such as PostgreSQL or MySQL.
  - *Comparison and benefits:* Relational databases have limited horizontal scaling capabilities and require complex replication and connection pooling mechanisms. Product data in ReFood (ingredients, allergens, nutrients and other fields) has a flexible JSON structure from Open Food Facts, which fits perfectly into NoSQL database without the need to write heavy schema migrations. Since we use composite keys and global secondary indexes, DynamoDB allows us to instantly retrieve product and user profile data. Therefore, it showed us high read speeds at a fixed cost.

- *AWS S3 Bucket and AWS EventBridge*
  - *Selected option:*  Cloud object storage (S3) for uploading photos of packages that integrated with EventBridge to manage asynchronous events.
  - *Alternatives:* Storing images as Blob arrays directly in the database or synchronously processing uploaded photos via API Gateway.
  - *Comparison and benefits:* Storing binary files in the database would quickly exhaust its limits and slow down indexing. Synchronous image verification via AI during an HTTP request would force the user to wait for a response for more than 5-10 seconds, which would ruin the UX and lead to an API Gateway timeout. The combination of S3 and EventBridge allowed us to implement an asynchronous pattern. The user uploads a photo directly to the S3 bucket via a presigned URL -> the bucket generates an `ObjectCreated` event -> EventBridge instantly intercepts it and triggers a background Lambda function for AI verification. The user receives a response based on the JobStatus (the AI response, which we store separately).

- *AWS Cognito*
  - *Selected option:*  An authentication service (Cognito) that provides Identity Pools for securely managing temporary IAM roles for anonymous devices and User Pools for verifying Sign-In with Apple tokens.
  - *Alternatives:* Building a custom JWT-based authentication service, storing hashed passwords in a database and manually refreshing session tokens.
  - *Comparison and benefits:* A custom security implementation carries critical risks of data leaks and requires significant effort to meet Apple ID security standards. AWS Cognito handles cryptographic verification of Apple signatures, token lifecycle management and account isolation. This allows the application to recognize access rights for both temporary anonymous device sessions and JWT tokens for authorized users.

== C4 Component Diagram

The component diagram illustrates the highest level of detail in ReFood's serverless backend. This level of architectural description shows how the overall business logic is broken down into atomic, independent Lambda functions (considered microservices) and how they interact with other system components, including database tables and integration APIs.

#figure(
  image("/resources/img/c4-component-diagram.png", width: 80%),
  caption: [System Component Diagram - ReFood App Ecosystem],
)

*Functional description of system components and the logic of their interaction*

ReFood's backend architecture is built on the Single Responsibility Principle and context isolation, where each microservice is represented by a separate Lambda function that has access only to the resources that it needs:

- *UserHandler*
  - *Purpose and relationships:* Handles initial anonymous device registration, updates session ID and manages logic for linking anonymous data to a permanent account when switching to an Apple ID. Has direct access to the `Users` table for storing profiles. This component also interacts with `MetricsService` to display user achievement statistics.

- *ProductHandler*
  - *Purpose and relationships:* Implements the logic for processing barcode scans and manual searches. It follows the “Cache-Aside” pattern: first checks for the code in the local `Products` table -> in case of a cache miss, it makes a request to the Open Food Facts API -> initiates an internal synchronous call to `AIService` for translation and analysis -> writes the final result back to `Products`. It implements product comparison through AI analysis of each product. It also handles the addition of a new product by a user input, passes it to `AIService` for processing and, based on the result, either saves or prevents the saving of the new product. In addition, the component logs every scan in the `Scans` table and manages product likes and dislikes via the `ProductsFavorites` table.

- *MapService*
  - *Purpose and Interactions:* Processes client requests to search for waste sorting points and build routes. It validates the user's coordinates and dynamically retrieves data from the `Geoapify API`.

- *NewsService*
  - *Purpose and relationships:* A separate component that does not depend on direct user requests for generating news. It runs once a day on a schedule via the `AWS EventBridge Scheduler`. The service makes a request to the `NCBI PubMed API`, parses data and filters out duplicates already stored in our database. The cleaned data is sent for processing to `AIService` and the obtained results are recorded in `News` table.

- *AIService*
  - *Purpose and connections:* An isolated component with no direct connection to the API Gateway. It acts as an internal proxy for interacting with the `Gemini LLM API`. Three lambdas call it synchronously: `ProductHandler` (for translating and analyzing product descriptions, as well as validating user text input), `NewsService` (for simplifying articles) and `S3Service` (for visually checking images uploaded by users).

- *S3Service and JobStatusService (Checker)*
  - *Purpose and relationships:* Manage the lifecycle of photos that users upload when adding new products. When a client uploads a file, `S3 Bucket` generates an `ObjectCreated` event which `AWS EventBridge` forwards to `S3Service`. This function registers a new job in the `UploadJobs` table and triggers an analysis in `AIService` to check the photo. The result is recorded in `UploadJobs`. The `JobStatusChecker` component receives requests from the mobile app, allowing the iOS client to poll for the readiness status and approve the product addition.

- *MetricsService*
  - *Purpose and relationships:* Collects analytics events from other lambdas (such as successful scans or routes showing) and updates counters, daily streaks and user eco-achievement statuses in the `UserMetrics` table.

== User Interface and User Experience Design

#figure(
  image("/resources/img/ux-full.png", width: 100%),
  caption: [ReFood User Experience Map (High-resolution version is available via link: https://www.figma.com/board/tF6A8DLTiIZo3QgSJ2lvjb/UX-Map---ReFood?node-id=0-1&t=Y786ryQ2tMFZZRBG-1],
)

To ensure a consistent and intuitive user experience, a complete UX flow map was designed before implementation. The map illustrates all primary navigation paths available within the application, including onboarding, product scanning, product analysis, recycling guidance, map navigation and user profile management.

=== Navigation Structure

==== Onboarding Flow

#figure(
  image("/resources/img/ux-onb.png", width: 80%),
  caption: [UX Map - Onboarding Flow]
)

On both the first and subsequent launches of the app, the user is greeted with a *Splash Screen* featuring a beautiful animation of our logo and product name. If the user reinstalls the app on the same device, we retrieve all their information and start an animation asking them to wait a bit while their data is returned to the app.

After the user has passed the splash screen and if this is their first launch of the app, we display an *Onboarding Screen* that describes our most important features: scanning products, understanding their ingredients and properly sorting their packaging.

Finally, after the user has seen all three onboarding screens, we transfer them to the *Main Screen*, which displays a variety of information.

On the Main Screen, we display the number of scanned and sorted products, a daily tip from our team, news from PubMed and a list of recently scanned products, limited to the last five. Also, in the recently scanned products section, there's a *"See all"* button that takes the user to a screen of all scanned products. The user can also access the *Product Details Screen* from the recent scans section by tapping on the product card. When a user first launches the app, the scanned and sorted product counters will be zero and the list of recently scanned products will be empty, with text prompting users to scan their first product.

==== Main Screens

#figure(
  image("/resources/img/ux-main-screens.png", width: 35%),
  caption: [UX Map - Main Screens Flow]
)

After the user reaches the main screen, they gain access to all primary areas of the application through the bottom navigation bar. The main navigation consists of four core sections: *Search*, *Map*, *Scanner* and *Profile*.

==== Search Screen

#figure(
  image("/resources/img/ux-search.png", width: 45%),
  caption: [UX Map - Search Screen Flow]
)

When a user navigates to the *Search Screen*, they see a list of all previously scanned products. From this screen, users can access the *Product Details Screen* by tapping a product card, like or dislike products and switch between viewing all scanned products or only their favorite items using the toggle.

The screen also provides a search function that lets users find products in their scan history by product name or brand. For better usability, products can be quickly removed by swiping a product card to the left.

All empty states are supported by dedicated UX placeholders that clearly communicate the current situation to the user. These states include the absence of scanned products, the absence of favorite products and cases where a search query returns no results.

==== Scanning Flow and Product Adding Flow

#figure(
  image("/resources/img/ux-scan-1.png", width: 80%),
  caption: [UX Map - Scanning Flow and Product Adding Flow]
)

After the user first opens the *Product Scanning Flow*, they are presented with a system modal window requesting camera access and explaining why the app requires it. If the user denies access, we present them with our modal window, asking them to go to settings to grant camera access and continue using the scanning flow.

When the app gains access to the camera, we open the *Scanner Screen*. On this screen, the user can start scanning by simply pointing the phone's camera at the product barcode, tap the *"Scan"* button if automatic scanning hasn't started, turn on the flashlight and proceed to the *Manual Input Screen*. On the Manual Input Screen, the user enters the product barcode and taps the "Find Product" button to start the search.

After the user either starts scanning by pointing the camera at the barcode or by entering the barcode on the manual input screen, a modal window for loading the product opens. If the product search reveals that the product was not found in the database, the loading modal window changes to a modal window stating that the product was not found. At this point, the user can either scan another product or add the product to our database.

If the user decides to add the product to our database, we open the *Product Adding Screen*, where the user must add a product photo and enter basic product information.

==== Product Screen

#figure(
  image("/resources/img/ux-scan-2.png", width: 80%),
  caption: [UX Map - Product Screen Flow]
)

If the product scan is successful, the user is presented with a *Product Preview Screen*, which confirms whether the product found is indeed the one they wanted to retrieve from the database. At this point, the user can either return to the scanner screen and scan another product or confirm that the product found is correct.

After confirming, the user is transferred to the *Product Details Screen*. This screen displays full product information, including ingredients, categories, calories and other nutritional facts, as well as a detailed AI analysis of the product and a description of its packaging. Additionally, a *"Share"* button is located at the top of the screen, allowing the user to share the product found.

From the product details screen, the user can navigate to three main user flows: *Product Edit Flow*, *Comparison Flow* and *Sorting Flow*.

If the user believes any product information is incorrect or incomplete, they can click the *Pencil Icon* at the top of the screen. This action takes the user to the *Product Edit Flow*, where they can edit or supplement the product information.

If the user wants to compare a product with another, they can tap the comparison button located at the bottom of the screen. This reopens the *Scanner Screen*, allowing the user to scan a second product. After successfully finding the second product, the app displays the *Product Preview Screen* again and then, upon confirmation, takes the user to the *Comparison Screen*. On this screen, products are compared by Nutri-Score, Eco-Score and nutrients. Additionally, the user can run an AI analysis and receive a recommendation on which product is the preferable choice.

The last scenario available from the product details screen is related to packaging sorting. In the packaging information section, there is a *"How to Sort"* button. Tapping it takes the user to the *Recycling Screen*. This screen displays more detailed information about the product packaging, the materials it is made from and instructions on how to prepare it for recycling. Below the description of all packaging components is a "Find Recycling Point" button, which takes the user to the Map Flow.

==== Map Flow

#figure(
  image("/resources/img/ux-map.png", width: 80%),
  caption: [UX Map - Map Flow]
)

When a user opens *Map Flow* for the first time, the app displays a system modal window requesting access to the device's geolocation. If the user denies access, the app displays its own modal window explaining that geolocation access is required to create routes to recycling centers.

If geolocation access is unavailable, the map opens using a preset default location (in our case, Kyiv). If the user has granted geolocation access, the camera automatically centers on their current location. An additional button on the screen allows the camera to return to the user's current location at any time. Tapping this button again activates follow mode, in which the map automatically rotates based on the user's direction of travel.

The map displays available recycling centers. If the user moves the map to another area, they can use the *"Search in this Area"* button to load recycling centers for the selected zone.

Tapping on any recycling point opens an information window displaying the name of the point, its address, a list of accepted materials and buttons for building a route by foot, by bike or by car.

After building a route, the user is shown travel time and total route distance. Two additional buttons are also available on this screen. The *"Sorted"* button notifies the app that the product has been successfully sorted, incrementing the counter of sorted products and updating user statistics. The *"Close"* button closes the route information and returns the user to the map.

All missing data states are accompanied by special UX placeholders. These are used when no recycling points are found in the selected area or when building a route is impossible for some reason.

==== Profile Flow

#figure(
  image("/resources/img/ux-profile.png", width: 80%),
  caption: [UX Map - Profile Flow]
)

When the user first navigates to the *Profile Screen*, an information bar appears at the top of the screen prompting them to register with an Apple ID. Its main purpose is to inform the user that registration will preserve all accumulated data, even if the app is deleted and reinstalled. After successful authorization, the bar's text changes to inform the user that registration has been successful and all data is now secure.

On the profile screen, the user also sees their basic statistics, some of which are also displayed on the app's main screen. Additionally, the current streak - the number of consecutive days the user has returned to the app - is displayed here.

Below the statistics block are three main sections the user can navigate to: *Achievements Screen*, *Settings Screen* and *Help Screen*.

The *Achievements Screen* displays the user's current progress across all available achievements, along with detailed information about each one. If an achievement has not yet been earned, the user is shown the requirements for unlocking it. After earning an achievement, the corresponding card is highlighted in green and the date it was earned is also displayed.

The *Settings Screen* allows the user to manage the app's basic settings. This includes app permission settings (camera and location), the ability to change the interface language, access additional legal information, including the Terms of Use and Privacy Policy and the ability to delete an account if the user is logged in with an Apple ID.

The final section is the *Help Screen*. Here, the user can find answers to frequently asked questions. If the information provided doesn't answer their question, they can contact the app's support team.

=== User Interface Design Principles

The ReFood user interface was designed with a focus on simplicity and minimizing the number of actions required to complete key user tasks.

*Minimal Interaction Principle*

- The most frequently used functions, such as barcode scanning, product comparison and finding recycling centers are accessible to the user in one or two actions.

*Progressive Disclosure*

- Detailed information is displayed only when the user actually needs it. For example, detailed packaging recycling instructions, descriptions of individual packaging components and route information are available only after the appropriate user action.

*Consistent and Predictable Interface*

- A consistent navigation structure and visual style are used throughout the app. Similar actions utilize the same controls, buttons and interaction patterns, allowing users to quickly master the interface and comfortably navigate between screens.

*Localization Support*

- The interface was designed from the ground up to support multiple languages. All key navigation elements, user messages and app content are available in both Ukrainian and English, making the app more accessible to the target audience.

== Deployment Topology and Infrastructure Resilience

The ReFood platform runs on Amazon Web Services in the *eu-north-1 (Stockholm) region*. To simplify infrastructure management and reduce operational overhead, the platform uses a serverless architecture. This approach eliminates the need to maintain dedicated servers while still providing the flexibility to scale when needed.

The mobile application communicates with the backend through a *REST API* hosted on *AWS API Gateway*. Whenever users perform actions in the application, the client sends HTTPS requests to the API, which then forwards them to the appropriate AWS Lambda functions for processing. On iOS, the application handles network communication through URLSession together with the AWS Amplify API Plugin.

The platform stores its main application data in Amazon DynamoDB. This database offers high scalability and automatically replicates data across multiple availability zones, which helps maintain availability and reliability. For image storage, the platform uses Amazon S3. The service provides durable object storage and keeps redundant copies of uploaded files to protect against data loss.

The serverless design removes the need for a dedicated load balancer. AWS API Gateway and AWS Lambda automatically distribute incoming requests and scale resources according to demand. As a result, the platform can handle changes in workload without requiring additional infrastructure management.

The platform also uses *Amazon EventBridge* to support asynchronous event processing. By decoupling long-running operations from the main request flow, EventBridge helps maintain application responsiveness and improves overall system reliability.

To secure access to cloud resources, the platform relies on *AWS Identity and Access Management*. IAM policies follow the principle of least privilege, ensuring that each service and component can access only the resources required for its operation.

=== Logging and Monitoring

*Server-side*

To ensure system transparency and simplify the debugging process, a centralized log collection system based on the Amazon CloudWatch Logs service has been implemented. Each AWS Lambda microservice function is integrated with a separate log group to which system events, stack traces and results are automatically sent in real time.

Monitoring of the ReFood infrastructure’s performance, productivity and availability is implemented using the interactive AWS CloudWatch Dashboards control panel. The custom dashboard aggregates technical and system metrics from various cloud services into a single interface for continuous analysis of the platform’s status.

#figure(
  image("/resources/img/cloudwatch-dashboard.png", width: 80%),
  caption: [AWS CloudWatch Dashboard monitoring dashboard for the ReFood system]
)

The main components of the monitoring system are:
- *Duration & Latency Profiles*: tracking the average and maximum execution time of Lambda functions and the total API Gateway latency to monitor interface performance.
- *Error Tracking*: error counters for immediate response to business logic failures.
- *Resource Utilization*: monitoring of database resource consumption of all tables which allows for optimization of infrastructure costs.

*Client-side*

The ReFood iOS application implements client-side error monitoring using the *Sentry* platform. A centralized logging mechanism was introduced through the `AppLogger` abstraction and the `NetworkRunner` wrapper, which automatically capture unexpected runtime exceptions and network-related failures occurring on the mobile client.

All API requests are executed through the NetworkRunner component. If an operation fails, the error is automatically forwarded to Sentry before being propagated to the application layer. So, this approach ensures that production issues can be investigated even when they cannot be reproduced locally on the test devices.

#figure(
  image("/resources/img/sentry.png", width: 80%),
  caption: [Example of Client-Side Error Captured by Sentry]
)

=== Maintainability

Maintainability was a key architectural consideration throughout the development of ReFood. The backend follows a microservice-based architecture, where each service is responsible for a single business domain and can be modified independently from the rest of the system. On the client side, the application is implemented using MVVM combined with Clean Architecture principles, providing a clear separation between presentation, business logic and data management layers. This approach simplifies testing, improves code readability and supports future feature development with minimal impact on existing functionality.

== Technology Stack Summary

#figure(
  table(
    columns: (1.2fr, 1.2fr, 2.3fr, 2.3fr),
    inset: 7pt,
    align: (left, left, left, left),
    stroke: 0.5pt + rgb("dddddd"),
    fill: (x, y) => if y == 0 { rgb("f5f5f5") } else { none },
    [*Component*], [*Technology*], [*Justification*], [*Trade-offs*],

    [Frontend], [Swift / SwiftUI], [Native iOS compilation], [Platform exclusivity (iOS only)],

    [Backend], [Node.js v24], [Team expertise, performance], [Not for complex calculations],

    [Serverless Infrastructure],
    [AWS Lambda],
    [No cost for downtime, easy linear scaling],
    [“Cold start” effect, time limit on function execution],

    [API Routing],
    [AWS API Gateway],
    [Managed HTTPS proxy, built-in JWT and CORS validation],
    [Cloud provider dependency],

    [Authentication],
    [AWS Cognito],
    [Built-in support for Apple ID and anonymous device sessions],
    [Complex data migration in future],

    [Database],
    [AWS DynamoDB],
    [Fast response, flexible NoSQL schema],
    [No JOIN queries, requires early index planning (GSI)],

    [File storage],
    [AWS S3 Bucket],
    [Low storage cost, ObjectCreated event generation],
    [Requires implementation of presigned URL logic on the client],

    [Product Data],
    [Open Food Facts API],
    [Free access, millions of products, support for the Ukrainian market],
    [Unreliable quality of crowdsourced data],

    [Generative AI],
    [Gemini LLM API],
    [Generous developer free tiers, low maintenance costs],
    [Vendor dependency, unstable latency under load],

    [Geodata],
    [Geoapify API],
    [Fast route calculation, large data volume],
    [Need for constant monitoring of free request quotas],

    [Research Data],
    [NCBI PubMed API],
    [Authoritative medical database, standardized catalog],
    [Results returned in outdated XML format],

    [Analytics],
    [Amplitude SDK],
    [Client-side event batching, built-in funnels],
    [Paid premium plans for complex tracking systems],
  ),
  caption: [Technology Stack Justification],
)
