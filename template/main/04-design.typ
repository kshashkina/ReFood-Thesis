#import "/local-lib/template-thesis.typ": *
#import "/metadata.typ": *
#pagebreak()
= System Design

== System Architecture and Design Rationale

Based on the results of our marketing research and gap analysis, we identified a number of important user needs that remain unmet by existing solutions on the market. These requirements formed the basis for developing key functional and non-functional requirements for the ReFood app.

Our primary goal was to create a scalable and maintainable solution that would combine the propper food selection and recycling process within a single platform.

The following sections detail how the identified functional and non-functional requirements were translated into specific engineering solutions and influenced the product's architecture and implementation.

=== Mapping Requirements to Architectural Components

*Functional Requirements and Corresponding Architectural Decisions*
- *Scanning and Manual Entry*: The system must allow users to scan barcodes or manually enter them to instantly retrieve all the data about the product (Nutri-Score, Eco-Score, ingredients, allergens, nutrients) and an provide an AI analysis of the fetched product.

    -- Architectural Decision: We utilize a protocol-oriented AVFoundation service for high-performance barcode decoding, coupled with a repository-based API layer to fetch and process product data.

- *Recycling Navigation and Map Integration*: Users must be able to view packaging components, transition to a "How to sort" flow, and locate nearby recycling points filtered by material (e.g., plastic, glass). The map must support routing, "search this area" functionality, and default locations if geolocation is disabled.

    -- Architectural Decision:

- User Dashboard and History Management: The Home screen must display dynamic content (Eco Tip, News, recent scans, current statistics), while the Search screen provides a complete history with filtering (all/favorites) and like/dislike capabilities

    -- Architectural Decision:

- *Seamless Authentication and Data Portability*: Users must be able to log in via Apple ID to securely save their data. If the app is deleted and reinstalled, the user's entire scan history, favorites, and statistics must be fully restored upon login.

    -- Architectural Decision:

- *Gamification & Progress Tracking*: The system must track user interactions, displaying a daily streak, scanned/sorted counts, and an Achievements tab with 8 distinct unlockable milestones.

    -- Architectural Decision:

- *Community Crowdsourcing (Add and Edit)*: If a product is missing or contains incorrect/poor-quality data (e.g., bad photos), the user must be able to submit new information or edits via a form for backend validation.

    -- Architectural Decision:

- *Smart Product Comparison*: The app must support a "Compare Mode" where a user can scan a second product, confirm the comparison, and view a side-by-side UI of nutrients. An AI analysis must determine and explain the "winner."

    -- Architectural Decision:

*Non-Functional Requirements and Corresponding Architectural Decisions*

- *Availability and Offline Data*: Users frequently experience poor cellular network connectivity inside supermarkets. The application must provide continuous access to previously scanned items, favorites, and gamification progress regardless of the current internet connection.

    -- Architectural Decision:

- *Performance and UI Responsiveness*: The mobile application must maintain a highly responsive interface (targeting 60 FPS) and avoid any freezing or UI blocking during heavy API requests, AI processing or data synchronization.

    -- Architectural Decision:

- *Security and Data Privacy*: Personal user data, scan history, and authentication tokens must be strictly isolated, securely transmitted, and protected against unauthorized access.

    -- Architectural Decision:

- *Data Consistency & Integrity*: The system must guarantee that local gamification metrics and cloud data remain perfectly synchronized, especially when a user switches devices or reinstalls the app, without accidental data loss.

    -- Architectural Decision:
