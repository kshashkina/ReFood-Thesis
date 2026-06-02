#import "@preview/hei-synd-thesis:0.1.1": *
#import "/metadata.typ": *

#pagebreak()
= Implementation

== Development Methodology and Team Organization

=== Agile Development Approach
The ReFood development followed the Agile methodology, organized into three sprints, each lasting one month. Given the small team size, we chose Agile over the formal Scrum approach, which in allowed us to quickly adapt to changes in the project and implement the feedback received into the app.

Sprint Organization

- Each sprint began with planning and prioritizing tasks for the following month using the RICE framework.
- During the sprint, we held meetings every two days to determine whether we were on track and to identify potential issues and areas where additional support was needed.
- At the end of each sprint, we received feedback from our supervisor and conducted a retrospective analysis of the previous sprint.

#figure(
  image("/resources/img/rice.png", width: 80%),
  caption: [Sprint 2 feature prioritization using the RICE framework.]
)

*Team Responsibilities Distribution:*
- *Yaroslava Mala:* Responsible for the entire serverless backend architecture, AWS cloud engineering and API integrations. This included developing all AWS Lambda microservices, configuring NoSQL DynamoDB database, managing Amazon S3 bucket triggers and storage layout parameters, API gateway logic and executing third-party API integrations (Open Food Facts endpoints, Geoapify, PubMed and AI model).
- *Kateryna Shashkina:* Responsible for the entire iOS mobile client application and user experience layer. This included implementing the responsive iOS frontend using Swift and the declarative SwiftUI framework, designing interface components, managing layout views and setting up the complete client-side event tracking architecture via Amplitude Tracking to log, monitor and evaluate production analytics and user behavior patterns.

=== Iterative Design

Before implementing the final version of ReFood, several architectural and product decisions were validated through iterative prototyping.

*Architecture Validation*
- An early version of the application was developed following Clean Architecture principles to validate the separation between the user interface, business logic, and data layer.

*Database Design Validation*
- Different entity relationships, data models and storage approaches were tested to determine which product information should be stored locally and which data should remain cloud-based.

*AI Service Evaluation*
- Multiple AI providers and prompting strategies were tested to evaluate response quality, consistency and cost efficiency. Different prompt structures were compared in order to achieve stable and predictable product explanations across multiple requests.

*Recycling Infrastructure Research*
- Different providers of recycling location data were evaluated and compared based on data quality, coverage and integration complexity. The selected solution demonstrated the best balance between performance and geographic coverage.

*User Interface and Responsive Layout Prototyping*
- We created several design prototypes before the final one was selected. Main attention was given to responsive layouts and usability across different devices of different sizes.

*Local Data Storage Validation*
- SwiftData prototypes were developed to validate local storage performance. This approach was ultimately adopted to ensure that frequently accessed information, such as scan history, could be loaded instantly without requiring a network request.

This iterative prototyping processes significantly reduced risks and allowed us be sure about or key architectural decisions before development began.

== Architectural Patterns and Coding Standards
Since the project has a distributed client-server architecture, architectural patterns and coding standards were adapted to the specifics of the server (Backend) and mobile (iOS Frontend) parts of the system.

=== Server-side architecture and patterns

#todo
*Яся тут твій текст*

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
This section presents the key Lambda function implementations that form the core of the ReFood backend. Each subsection highlights a critical component, its flow and the architectural decisions that bring business value.

=== User Handler: Implementation of User Services and Authentication

The ReFood app implements a hybrid identity model designed to maximize user retention. Users can launch and use the app completely anonymously, with their scan history and settings tracked instantly. At any time, the user can choose to upgrade to a fully authenticated account via Apple Sign-In without losing any accumulated data.

*Architectural Identity Lifecycle Flows:*
- Anonymous Session Onboarding: App Launch #sym.arrow AWS Amplify (Cognito Identity Pool) #sym.arrow POST /users/register #sym.arrow AWS Lambda (registerUser) #sym.arrow _the session is established using physical deviceId and AWS IAM temporary credentials attached to the identityId._
- Authenticated Account Linking Upgrade: Apple OAuth Sign-In #sym.arrow AWS Cognito User Pool Validation #sym.arrow JWT token (cognitoSub within claims) #sym.arrow POST /users/register/link-account #sym.arrow AWS Lambda (registerLinkAccount).

In this way, when a user deletes the app and reinstalls it their anonymous data reappears because it is tied to deviceId. When a user signs in with Apple on any other IOS device - their full history and favorites are restored via cognitoSub.

*Anonymous Registration Implementation*

The following code snippet processes initial device checks, updates outdated identityId tokens and guarantees database entity uniqueness using DynamoDB conditional checks:

```javascript
export const registerUser = async (event) => {
    let body;
    try {
      body = JSON.parse(event.body || "{}");
    } catch {
      return response(400, { error: "Invalid JSON body" });
    }

    const validation = validateRegisterRequest(body);
    if (!validation.valid) {
      return response(400, {
        error: "Validation failed",
        details: validation.errors
      });
    }

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
    } catch (error) {
      console.error("Error:", error);
      return response(500, {
        error: "Failed to register user"
      });
    }
  };
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

export const registerLinkAccount = async (event) => {
    // extract cognitoSub from verified JWT claims (set by API Gateway auth)
    const claims = event.requestContext?.authorizer?.claims || event.requestContext?.authorizer?.jwt?.claims;
    const cognitoSub = claims?.sub;

    if (!cognitoSub) {
        return response(401, { error: "Missing or invalid authorization token" });
    }

    let body;
    try {
        body = JSON.parse(event.body || "{}");
    } catch {
        return response(400, { error: "Invalid JSON body" });
    }

    const { deviceId } = body;
    if (!deviceId || typeof deviceId !== 'string') {
        return response(400, { error: "Missing or invalid deviceId" });
    }

    const email = claims.email || null;
    const givenName = claims.given_name || null;

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
    } catch (error) {
      console.error("Error:", error);
      return response(500, {
          error: "Failed to link account"
      });
    }
  };
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

When a user scans a barcode, the system must: retrieve product information, translate it into Ukrainian and English, and analyze the product's nutritional value using our AI Service. In addition, the system builds its own product database by collecting information from the Open Food Facts (OFF) API and enhancing it with translations generated by AI. This allows for a reduction in the number of external API calls in the future and shorter response times for repeat scans.

*Product Query and Fallback Cache Execution*

The getProduct handler manages cache queries, coordinates external data access and maps localized response:

```javascript
  export async function getProduct(event) {
    const barcodeRaw = event.pathParameters?.barcode;
    const barcode = normalizeBarcode(barcodeRaw);

    if (!barcode) {
      return response(400, { error: "Invalid barcode format" });
    }

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

    return response(200, {
      source: "openfoodfacts",
      product: toProductResponse(product)
    });
}
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

#underline[Asynchronous Event-Driven Media Analysis]: User submitted product images cannot be trusted or served immediately. The system decouples this workflow via an asynchronous event-driven pattern using AWS S3, Lambda AIService and AWS EventBridge.

*Image Verification Lifecycle Flow:*

Step 1: The iOS client requests a pre-signed URL and uploads the packaging image directly to a restricted transient directory (/temp/) within the AWS S3 bucket.

Step 2: The successful S3 image upload automatically emits an ObjectCreated state change event.

Step 3: AWS EventBridge intercepts this event and safely routes it to trigger an asynchronous background validation function.

Step 4: The background function passes the S3 image URI to the AIService using multimodal vision analysis to confirm if the file is a real product packaging image (checking for inappropriate content, blurring or mismatching data).

Step 5: The evaluation output is written to the UploadJobs table. Upon approval, the image is moved to the permanent production folder, updating the record status. If rejected, the job documents specific error details for client tracking.

```javascript
  export async function validateImage(event) {
    const results = [];

    for (const record of event.Records) {
        const s3Key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
        const filename = s3Key.split("/").pop();
        const imageId = filename.split(".").slice(0, -1).join(".");

        console.log(`S3 notification received: s3Key=${s3Key}, imageId=${imageId}`);
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
    }

    return { processed: results.length, results };
}
```

*Benefits:*

- *Own product database:* Each OFF lookup is saved locally - subsequent scans are instant with no external API call.
- *Multilingual support:* AI translates product data to Ukrainian and English regardless of the original product language.
- *AI health analysis:* Users receive an immediate analysis of hidden sugars and harmful additives.
- *Safety gate:* User-submitted products must pass AI validation before entering the database.

=== Map Service: Geoinformation System and Routing

The Map Service provides recycling ponts search capabilities and navigation route generation for user. Both features integrate directly with the Geoapify API.

#underline[Geographic Data Storage and Licensing Compliance]: Under the Geoapify API license agreement, caching or persistently storing geographic coordinate points, spatial indexes and routing details in a local database is explicitly prohibited. The ReFood architecture strictly enforces this compliance by treating responses as transient data: they are fetched on-demand, processed, transformed in memory and immediately transmitted to the client. Additionaly, this architectural design eliminates geospatial table maintenance and reduces DynamoDB storage requirements.

*Route Request Handler*

The following snippet represents the handler routing parameters, making external requests and returning simplified geometry coordinates:

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

The following snippet showcases one of metric logic's implementation - the increment of scanned product :

```javascript
export const incrementScanned = async (userId, { hour, isWeekend }) => {
  const now = new Date().toISOString();

  // just incrementation for metric
  let updateExpr = "ADD scannedCount :inc SET lastUpdated = :now";
  const exprAttrValues = { ":inc": 1, ":now": now };

  // check if scanning match any other achivements goals
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
};
```

=== News Service: Research and Nutritional Education Materials

The News Service provides research studies and nutritional education materials to the application's daily dashboard. The service architecture separates into a scheduled background research aggregation pipeline via PubMed APIs query and AWS EventBridge scheduler.

*Automated Data Collection Process:*
- Scheduled update cycle: AWS EventBridge (daily scheduled rule) #sym.arrow AWS Lambda (fetchNews).
- External data retrieval: Query to the external NCBI PubMed HTTP API.
- Processing cycle: Analysis of internal parameters using `fast-xml-parser` #sym.arrow Filtering existing records using a quick search by primary key in local NoSQL tables.
- Data Processing: Executing an internal lambda #sym.arrow AWS Lambda (AIService: “process_research” action).
- AI translation and simplification: AI runs automatic summarization algorithms, removing complex terms and creating clear, structured arrays and translate information both Ukrainian and English languages.
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
