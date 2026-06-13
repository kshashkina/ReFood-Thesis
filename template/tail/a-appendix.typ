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
