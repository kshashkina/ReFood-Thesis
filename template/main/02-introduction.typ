#import "@preview/hei-synd-thesis:0.1.1": *
#import "/metadata.typ": *

#pagebreak()
= Introduction

In this era of rapid digital transformation, consumers face a challenge: while technology makes it easier to access information, the process of choosing products in the supermarket that truly align with the principles of a healthy lifestyle and environmental responsibility remains unsystematized. As global food production continues to grow, misleading marketing tactics and complex ingredient lists are obscuring the transparency of product information. Consumers spend too much time decoding the small print on labels and ambiguous symbols indicating waste disposal methods. Despite advances in generative artificial intelligence, general chatbots remain too broad and require lengthy text queries to provide accurate information. This calls for an intelligent, integrated personal assistant that can instantly interpret product data and provide immediate, practical recommendations on both nutrition and sustainable waste management.

Unlike existing similar apps, which typically prioritize only one isolated function (such as purely counting a product's calories or providing general reference information about packaging), ReFood addresses the lack of a comprehensive platform that combines in-depth nutritional analysis with powerful geolocation and AI features available in both English and Ukrainian languages. The app combines elements of an interactive scanner with the AI analysis of product ingredients and the convenience of mapping services, allowing users to identify products by barcode, view ingredient lists translated into plain language without marketing jargon, identify the type of packaging material and plan optimal routes to the nearest recycling collection points. Additionally, the app provides users with news and articles on healthy eating and environment.

This paper describes the journey of two software engineering students who, over an intensive three-month development period, transformed a conceptual solution into a fully functional mobile application ready for production deployment on the Apple App Store. The development process included detailed research of the FoodTech market, competitor analysis, the design of architectural solutions and the implementation of a scalable cloud system using best software engineering practices.

== Project Objectives
The primary objectives of this capstone project are:

1. To develop a fully functional iOS mobile app that facilitates the analysis of food ingredients and simplifies the waste sorting process.
2. To implement an intelligent ingredient translation system that provides instant, AI-powered analysis of composition and identifies hidden components.
3. To build reliable geolocation features that enable users to find the nearest recycling collection and processing centers, with routing capabilities.
4. To integrate with open product databases and implement a quick barcode scanning module to obtain comprehensive product metadata.
5. To build a data enrichment logic that allows users to manually add missing products and/or update outdated information, thereby expanding the database.
6. To implement a news feed with articles on healthy eating and environment.
7. To build a scalable architecture capable of supporting growth in both users and processed data.
8. To deploy a backend infrastructure using the AWS cloud and complete the deployment pipeline for the application's publication on the Apple App Store.

These goals guided our development process throughout the project lifecycle, from initial research to implementation and deployment.

== Relevance and Significance
This project holds significance in several dimensions:

*Technical Relevance:* The development of ReFood demonstrates the application of best software engineering methods in the creation of a mobile application with a wide range of features. The project illustrates the practical implementation of a serverless microservices architecture based on AWS Lambda, comprehensive integration with diverse third-party APIs and cloud-based artificial intelligence services, as well as the development of a flexible and adaptive user interface using the SwiftUI framework.

*Market relevance:* Current data reveals a steep divide between consumer intentions and actions: while up to 79% of consumers prefer sustainable packaging, more than half misinterpret recycling labels, causing severe batch contamination at recycling centers. Furthermore, global applications lack localization for the Ukrainian market, failing to index local brands or address regional specificities like the absence of official Nutri-Score standards. ReFood addresses this market void by delivering real-time, localized data and an intuitive interface.

*Academic relevance:* This capstone project integrates knowledge from various courses in the software engineering and business analysis curriculum, including mobile development, software architecture, database design, user experience design and market research. It demonstrates our ability to integrate theoretical concepts to solve practical, real-world problems.

== Methodology
Our approach to developing *ReFood* followed a structured methodology combining thorough research with agile development practices:

*Discovery Phase:* We conducted market research on FoodTech and eco-friendly digital solutions, analyzed competitors' platforms, identified market opportunities and defined the key requirements for the future product.

*Iterative Development:* The project was implemented using the Agile methodology in the form of sequential sprints, each with specific goals and defined deliverables:

*Sprint 1:* Interface design and basic scanning flow.
The main goal of this phase was to finalize the UX/UI design and create an interactive, clickable prototype of the app. During this phase, we implemented the splash screen with user onboarding logic, basic functionality for scanning barcodes, displaying the product page and showing initial information about its recycling.

*Sprint 2:* Integration of the recycling map and database enrichment tools.
This phase focused on expanding interactive capabilities. We developed a page for comparing multiple products and implemented the logic for users to create and edit products. In addition, we integrated an interactive map of waste sorting points with custom markers, geolocation support and a filtering system by material type. That allows us to link product scan results directly to the nearest recycling points.

*Sprint 3:* Users profile, advanced analytics, interactive features and finalization.
The final sprint resulted in the creation of a full-scale map with detailed information about collection points and route planning to them. We implemented a user profile with secure authentication via Apple ID, a scan history and an achievement system. The product creation functionality was expanded to allow users to upload photos. We also fully localized the app and integrated an analytics event tracking system using Amplitude Tracking to monitor user behavior.

*Technology Stack:* We carefully selected a technology stack based on project requirements, the team's experience and industry best practices. The frontend was implemented as a mobile app in Swift using the SwiftUI framework, while the backend uses cloud-based Lambda functions built on Node.js (v24). AWS provides the microservices infrastructure and cloud storage. We selected specific services to optimize request processing speed, scalability and minimize system maintenance costs.

== Structure of this paper
This thesis is structured to provide both a comprehensive technical reference and an engaging narrative of the development process:

*Domain Research and Analysis* (Chapter 3) examines the current FoodTech market based on a thorough analysis of competitors, global market research and the identification of functional gaps that justify the need for our comprehensive solution.

*System Design and Architecture* (Chapter 4) details the complete design of our product, including software architecture decisions, the selection and rationale for the technology stack and considerations regarding user experience (UI/UX) design.

*ReFood Implementation Process* (Chapter 5) describes the intensive three-month development process, documenting the goals of each sprint, technical challenges, results and retrospective findings.

*Validation and Testing* (Chapter 6) shows how we verified that our iOS mobile app met all initial business and technical requirements.

*Conclusions and Future Perspectives* (Chapter 7) contains reflections on the project's final achievements, lessons learned during the engineering cycle and potential directions for future expansion of the app's functionality.
