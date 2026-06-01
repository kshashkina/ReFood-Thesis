#import "/local-lib/template-thesis.typ": *
#import "/metadata.typ": *
#pagebreak()
#heading(numbering:none)[#i18n("abstract-title", lang:option.lang)] <sec:abstract>

Although there are countless mobile solutions in the fields of modern digital health and environmental sustainability, the market lacks a comprehensive tool that combines instant analysis of a product's nutritional value with clear instructions on how to recycle its packaging. This capstone project documents the entire design and development process of *ReFood* - an iOS mobile application that fills this fundamental gap. The product allows users to scan product barcodes to obtain clear information about their ingredients, nutritional value, and an AI-generated assessment, as well as data on packaging materials and the nearest collection and recycling points. This promotes a culture of conscious consumption and simplifies the waste sorting process for every user.

Drawing inspiration from existing systems like Open Food Facts, Yuka and Junker, we identified an opportunity to create a comprehensive system amid the global trend toward a healthy lifestyle and people's desire to control the quality of their diet. Our initial concept arose from the observation that manufacturers often hide critical ingredients (such as sugar under various names) behind complex wording, marketing tactics or fine print. Unlike traditional online searches or waiting for responses from AI chatbots, ReFood provides instant interpretation of product characteristics without unnecessary scientific jargon. Accordingly, this project aimed to develop a functional mobile application that includes: (1) a barcode scanning system with instant product recognition, (2) a module for detailed analysis and "translation" of ingredient lists into a form understandable to the consumer, (3) an interactive flowchart for the proper disposal and sorting of different types of packaging, (4) a data enrichment module that allows users to add new products to the database, (5) a scalable microservices architecture capable of supporting high query processing speeds and (6) the deployment of a modern cloud infrastructure based on AWS services.

To achieve these goals, we conducted a discovery of the FoodTech market and an analysis of competitive solutions to validate the concept and identify functional gaps. The system was developed using the Agile methodology, structured around consecutive three-month sprints. We implemented a service-oriented serverless architecture, consisting of the following core cloud modules: User Handler for user authentication and profile management; Product Handler & AI Service for barcode scanning, AI analysis and translation; Map Service for geolocating processing points; News Service for news in the field of nutrition and products; Metrics Service for collecting user metrics. Technical implementation of the backend: a Lambda function on the Node.js (v24) platform using NoSQL DynamoDB and an S3 bucket to optimize data storage. The frontend was implemented as an iOS app in Swift using the declarative SwiftUI framework, which allowed for the implementation of modern UI/UX design principles and adaptive animation.

As a result, the project successfully created a production-ready mobile application with full functionality that meets all defined business requirements and quality criteria, and prepared for deployment to the official Apple App Store. Ultimately, the implementation demonstrates the successful application of modern software development practices, creating an attractive alternative to existing food monitoring methods and laying a solid foundation for further expansion of the application's functionality.

#v(2em)
#if doc.at("keywords", default:none) != none {[

  _*#i18n("keywords", lang: option.lang)*_:

  #enumerating-items(
    items: doc.keywords,
    italic: true
  )
]}
