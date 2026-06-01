#import "/local-lib/template-thesis.typ": *
#import "/metadata.typ": *

#pagebreak()
= Research
== Domain Overview

Today's eating habits harm both human health and the environment. Eating many processed foods leads to obesity and other related health problems @benthem2024. Industrial food production also contributes to biodiversity loss, water shortages, climate change, and increasing amounts of packaging waste @benthem2024. Plastic recycling rates remain low, ranging from 4% to 32% depending on the region. Many consumers struggle with proper waste sorting, and more than half of them do not correctly understand recycling labels. Among those who are unsure, approximately 42% dispose of packaging incorrectly, contaminating recyclable materials, while 22% do not recycle at all @scott2023.

Despite the declaration of "green" and healthy values, actual consumer habits often do not correspond to them. Research shows that people want to have a healthy and sustainable diet, but face difficulties in choosing the right products. The reasons are lack of knowledge, small print on labels, marketing gimmicks, limited time and budget. For example, only 42% of consumers regularly buy "healthy" and sustainable products, although 79% express a desire for environmentally friendly packaging. The main barriers are high price, skepticism about marketing promises and lack of transparency about the composition and origin of products @foodminds2024.

A movement for "open food data" has emerged, allowing consumers to learn the truth about products. Users want to understand exactly what they are eating and how it affects their health and the planet. This has created a demand for applications that "digitize" information from labels and make it understandable. Such services satisfy a deep demand for transparency in society: they close the gap between consumers' perceptions of "healthy" and the actual contents of a product. There is also a growing trend towards conscious consumption - people are ready to give preference to products without harmful additives, organic, in environmentally friendly packaging, etc., if they have reliable information

To help consumers act responsibly, smartphones are entering the scene. They have become "personal advisors" during shopping: they allow you to instantly obtain product information by scanning a barcode or QR code. Thus, even in a supermarket, a person can find out the composition, calorie content, allergens or ecological rating of a product in seconds, without having to decipher small print and complex chemical names @basli2025

To sum up, the development of technology opens up opportunities for conscious food choices. Global challenges (diabetes and obesity epidemics, plastic crisis) are driving the demand for tools that help people make healthier and more environmentally friendly choices every day. Solutions that provide transparent food information and recommendations in real time are becoming increasingly relevant.
== Analysis of Existing Solutions

There are already several solutions on the market that partially cover the mentioned needs. Let's consider the main players and their characteristics:

=== Open Food Facts

Open Food Facts (OFF) is a non-profit open platform known as the “Wikipedia of food”. It has been around since 2012 and contains data on over 3 million food products worldwide. OFF allows you to scan product barcodes and receive detailed information about their impact on health and the environment. In particular, the application shows Nutri-Score (nutritional quality) and NOVA (processing level) ratings so that the user can quickly assess the nutritional value and the level of ultra-processing of the product.

Uniquely, OFF also integrates environmental indicators: it calculates the Eco-Score (eco-complex rating), which takes into account the carbon footprint, the type of packaging and its processing instructions, the presence of eco-certificates, the origin of the ingredients, etc. That is, the user immediately sees how useful the product is for him and how “green” it is for the planet. OFF is an open source and open data project: the information is populated by a community of volunteers, and manufacturers can also add their products under an open data license. This approach ensures brand independence and API availability for third-party developers

*Strengths:*

- Worldwide coverage
- Detailed product information
- Scientific ratings (Nutri-Score, NOVA)
- Transparent and non-profit project
- Open-source and open-data approach
- Available on multiple platforms
- Supports multiple languages

*Disadvantages:*

- Depends on community-contributed data
- Some local products may be missing
- Less attractive UX/UI compared to commercial competitors
- Does not provide direct recommendations or clear judgments
- Requires users to interpret the information themselves

#figure(
  image("/resources/img/open_food_facts_ios.jpg", width: 15%),
  caption: [Open Food Facts IOS interface.]
)

=== Yuka

Yuka is one of the most popular mobile product scanners, launched in France (2017) and currently has over 80 million users worldwide. Yuka scans both food and cosmetics, "decoding" their composition and assessing their impact on health on a simple scale. Each product is assigned a score of 0 - 100 points and a color indicator that reflects the degree of risk. The Yuka rating formula is built as follows: 60% of the score depends on nutritional value, 30% on the presence of harmful additives, and 10% on organic quality.

Yuka's interface is very user-friendly: after scanning, you can see a short verdict and a list of reasons. The application also offers healthier alternatives: if a product has received a low score, Yuka will show similar products with a better rating. For cosmetics, Yuka highlights dangerous ingredients and also gives a safety rating. It is important that the project declares 100% independence. That means that Yuka does not show advertising and does not cooperate with manufacturers, so brands cannot influence the ratings or buy promotions. Monetization is carried out through a premium subscription and the release of its own products, like a recipe book @yuka2025

*Advantages*

- Simple and easy-to-understand product ratings
- Clear recommendations for consumers
- Supports healthier food choices
- Significant time savings during shopping
- Independent and advertisement-free platform
- Covers both food products and cosmetics
- User-friendly interface

*Disadvantages*

- Oversimplified evaluation methodology
- Product scores may not accurately reflect overall health benefits
- Limited consideration of individual dietary needs
- Strong reliance on Nutri-Score and additive penalties
- Minimal focus on environmental impact
- No dedicated eco-score or recycling recommendations
- Limited coverage of local products
- More complete database for Europe and North America
- No official Ukrainian language support

#figure(
  image("/resources/img/yuka.png", width: 15%),
  caption: [Yuka IOS interface.]
)

=== Fooducate

Fooducate is one of the first mobile apps in this area (launched in 2010 in the US). It was initially positioned as a personal nutritionist on your phone. Fooducate allows you to scan products and get a letter grade from A (best) to D or F (worst) - similar to school grades. The algorithm mainly takes into account nutritional content: the ratio of calories, sugar, fats, proteins, etc. For example, fried potatoes get a "C" for high calories and low protein, while an apple gets an "A" as a fortified low-calorie product. If a product gets a bad rating, Fooducate offers alternatives - other products in the same category with a higher rating. Many users noted that this feature helped them decide what to buy instead of a harmful option, right when going to the store. Unlike Yuka, Fooducate has an advanced calorie and physical activity tracker. The user can keep a food diary, set weight goals, track calories, and BV. The application provides tips, recipes, and supports the community - there are forums where participants share progress. Thus, Fooducate is focused on long-term improvement of eating habits and weight loss @chaudhry2019

*Advantages*

- Combines food scanning and health-tracking features
- Supports healthier eating habits and diet management
- Personalized recommendations based on user preferences
- Large community and educational nutrition content
- User-friendly interface and fast scanning

*Disadvantages*

- Focused mainly on the US market
- Limited support for local products and languages
- Product ratings may oversimplify nutritional value
- No environmental impact or recycling information
- Some advanced features require a paid subscription

#figure(
  image("/resources/img/fooducate.png", width: 30%),
  caption: [Fooducate IOS interface.]
)

=== Junker

Junker is a specialized ecological application from Italy that solves the problem of "Where to throw away the packaging?” Its slogan is “virtual assistant for sorting waste”. Junker scans the barcode of a product and recognizes all the parts of the packaging it consists of and the materials of these parts. Then the application clearly instructs which container each part should be disposed of in according to local recycling rules. Junker's strong point is its integration with municipalities: the application uses geolocation to provide instructions specifically for the community where the user is located (since sorting rules may differ by region). It also reminds about the days of collection of certain fractions via push notifications. Junker's database contains ~1.7 million products, covering most of the Italian market. If the product is missing, the user can take a photo - and the AI algorithms will recognize the packaging @southey2020.

*Advantages*

- Provides clear recycling and waste-sorting guidance
- Reduces consumer confusion about packaging disposal
- Supports environmentally responsible behavior
- Large and accurate recycling database
- Includes additional features such as waste collection schedules
- Community-driven data contribution

*Disadvantages*

- Focused only on recycling and waste management
- Does not provide food, nutrition, or health information
- Requires additional apps for complete product awareness
- Limited support for regions outside Italy

#figure(
  image("/resources/img/junker.png", width: 40%),
  caption: [Junker IOS interface.]
)

=== Comparative Analysis

#figure(
  table(
    columns: (2.3fr, 0.7fr, 0.7fr, 0.9fr, 0.8fr, 0.9fr),
    inset: 5pt,

    table.header(
      [*Feature*],
      [*OFF*],
      [*Yuka*],
      [*Fooducate*],
      [*Junker*],
      [*ReFood*],
    ),

    [Food Scanning], [✓], [✓], [✓], [✗], [✓],
    [Waste Scanning], [△], [✗], [✗], [✓], [✓],
    [Health Analysis], [✓], [✓], [✓], [✗], [✓],
    [Environmental Analysis], [✓], [△], [✗], [✓], [✓],
    [AI Explanations], [✗], [✗], [✗], [✗], [✓],
    [Ukrainian Localization], [△], [✗], [✗], [△], [✓],
    [Recycling Guidance], [△], [✗], [✗], [✓], [✓],
  ),
  caption: [Comparison of existing solutions and the proposed ReFood feature set.]
) <tab:solutions-comparison>

#text(size: 8pt)[
*Legend:* ✓ = supported; △ = partially supported or limited; ✗ = not supported.
]

As shown in @tab:solutions-comparison, all the solutions analyzed in Market Research focus on one specific goal. Open Food Facts mainly focuses on providing information about the product, while also containing additional information on how to properly sort the packaging from this product. Yuka and Fooducate mainly provide information exclusively about how a product affects health and how it is a good choice for the consumer. At the same time, Junker provides information exclusively on how to properly sort waste and dispose of packaging.

Thus, we see the problem in the fact that at the moment there is no single solution that would combine all the necessary functions and accompany the user on the entire path - from buying a product in a store to its proper disposal and sorting.

== Gap Analysis

After conducting a review, we can identify needs that open up opportunities for a new ReFood product:

=== Gap 1: Lack of Combined Health and Environmental Assessment

None of the existing services provides a comprehensive assessment of both the impact on health and the impact on the environment at the same time. Consumers have to choose: either an application about the composition and calories, or separately about waste recycling. Even Yuka only partially takes into account environmental friendliness (organic), and Junker does not show anything about food quality at all. Therefore, ReFood has the potential to become an integrated solution that combines both perspectives.
=== Gap 2: Lack of Localization for Ukrainian Consumers

Global applications do not always work well with Ukrainian products: absence in the database, no translation, irrelevance of some ratings (for example, Nutri-Score is not yet officially used on packaging in Ukraine @castle2025). There is a demand for a solution adapted to the local market. ReFood can use OpenFoodFacts data and its own content to focus on products from Ukrainian stores, including local brands.

=== Gap 3: Limited Personalization and AI-Based Recommendations

Existing apps mostly provide static information or assessments based on a fixed formula. However, different users have different needs: allergy sufferers need to filter out certain ingredients, athletes need to see proteins and calories, and eco-activists need to minimize plastic. Some apps (OFF, Fooducate) allow for some customization, but there is no flexible tool that would explain the ingredients specifically for the user's needs. Modern technologies like GPT allow you to do exactly that - generate explanations or recommendations based on ingredients. None of the analyzed solutions provide AI explanations as a core feature. Therefore, ReFood has a chance to implement an intelligent assistant.

=== Gap 4: Absence of Integrated Recycling Guidance

Even when the packaging says it is recyclable, it may be unclear to the consumer where to take this container. Junker solves this through local instructions, but there is no single solution globally. An open map based on OSM data shows that there are actually hundreds of thousands of recycling collection points around the world @wastefreemap2025. However, most people do not know about them. By implementing the map in ReFood, you can give the user a final hint about where to take the container. Thus, ReFood will close the cycle: from choosing a product to proper disposal.

== Chapter Conclusion

Conducted market research and gap analysis demonstrate that currently existing solutions cover only one consumer need at a time - either health care or environmental care. None of the analyzed solutions combines all these aspects in one application.

As a result, users have to switch between several applications to get complete information about the product: starting with the right choice on the store shelf and ending with how to properly dispose of the packaging without harming the environment. This gap creates an excellent opportunity for the development of ReFood - a smart assistant in the pocket that will accompany the user at every stage of the product's life cycle.
