#import "/local-lib/template-thesis.typ": *
#import "/metadata.typ": *
#pagebreak()
= #i18n("conclusion-title", lang:option.lang) <sec:conclusion>

Creating the ReFood app was a culmination of our studies in the Software Engineering and Business Analysis program. This project allowed us to experience the entire software development process - from market research and architecture design to implementation, testing and publication. It's especially valuable that by the time we completed our thesis, ReFood had already been published in the App Store and was beginning to receive first user reviews. This allowed the project to move beyond purely academic work and become a real product that people can use in their lives.

== Project summary

The main goal of this project was to create a mobile application that would act as an intelligent assistant, helping users make more conscious decisions when choosing food products and understand how to properly dispose of packaging after consumption. The project aimed to create a unified platform that would guide users through every stage of the product experience - from selecting a product in the store and deciding whether to purchase it to receiving recommendations for properly sorting its packaging.

The developed solution includes functionality for scanning products, displaying information about their ingredients and providing recommendations for sorting packaging and finding recycling locations. Furthermore, the app supports product comparison, recommendations based on comparison results, a user profile, achievements and statistics.

Thus, the result of our work is a fully functioning mobile product that successfully integrates the food transparency objectives for which the project was created. We have implemented a solution that guides users throughout the entire product experience, from selecting it to proper disposal of the packaging.

== Comparison with the initial objectives

At the beginning of our project, a set of goals was formulated that determined the future direction of the development. Upon completion of the project, we can conclude that these key objectives were successfully achieved.

From a functionality perspective, we were able to implement all the key capabilities planned during the design phase. The application supports barcode scanning, displaying detailed product information, analyzing product ingredients using artificial intelligence, comparing products, providing recommendations for sorting packaging and finding the nearest recycling points.

The technical goals of the project were equally important. During the process, we designed and implemented a serverless architecture based on AWS. The system was integrated with third-party services to retrieve product information, create routes, find recycling points, display scientific articles and publications to users and generate AI analyses. Particular attention was paid to scalability, performance and ease of future support and development of the system.

Thus, we determined that the final implementation meets the original goals and demonstrates the successful transformation of the initial idea into a software product ready for use by real users.

== Encountered difficulties

During the development of ReFood, we encountered several technical and product challenges that required additional research and revisions to certain architectural solutions.

Integrating artificial intelligence was one of the challenges. At early stages of development, different prompts could produce responses with varying levels of detail and formatting, negatively affecting the consistency of the user experience. As a result, several iterations were conducted to refine the response structure, resulting in more predictable results.

Difficulties also arose in implementing geolocation functionality. Initially, solutions based directly on OpenStreetMap data were considered. However, testing revealed that obtaining recycling points and building routes was slower than expected and required additional server-side data processing. As a result, the decision was made to switch to Geoapify, which significantly improved performance and simplified integration with mapping services.

Another important technical challenge was implementing the authorization system. The app needed to support both anonymous use and Apple ID login without losing the user's accumulated history. This required implementing additional logic to link anonymous and authorized accounts, ensuring user data is preserved correctly across different app usage scenarios.

Despite challenges, all key issues were successfully resolved during the development process, providing additional practical experience in mobile development and cloud architecture.

== Future perspectives

Although the current version of ReFood already implements all the core functionality necessary to achieve its stated goals, during development we identified several promising areas for further development.

*In the short term*, the app's development may involve introducing a premium subscription, expanding the achievement and gamification systems and adding a more detailed user nutrition analysis. Specifically, we plan to implement features for calculating calories, proteins, fats and carbohydrates consumed based on scanned food history.

*Medium-term development* of the project involves expanding data sources and increasing the level of localization. One possible area is integration with Ukrainian retail chains to automatically obtain up-to-date product information. Furthermore, expanding the app's language support and developing partnerships with organizations working in the fields of waste recycling and sustainable consumption are also promising.

*Long-term development* is considering launching the app on the Android platform, which will significantly expand the user base without requiring changes to the existing server infrastructure. Another promising area is the creation of a more advanced AI assistant capable of providing personalized recommendations on nutrition and sustainable consumption. Additionally, the development of a B2B direction is being considered, within which manufacturers and partners will be able to obtain analytical data on user preferences and consumer environmental behavior.


== Final Reflection

Working on ReFood was a crucial step in our student journey. It allowed us to experience the full process of creating a product that would be available to users all around the world. During development, we made architectural decisions, solved complex technical problems and designed the user experience, striving to make the application as useful and convenient as possible for future users.

We found it especially valuable that our work resulted in a real product, not just a hypothetical development plan. This project allowed us to view the software development process from the perspective of developing real products that can truly benefit people. We believe that the experience gained while working on ReFood will serve as an important foundation for our future professional development in software engineering.