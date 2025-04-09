# Telco Customer Churn Analysis
## Introduction
Customer churn poses a major challenge for subscription-based companies. Retaining existing customers is often more cost-effective than acquiring new ones, making churn prediction a valuable business strategy. This project leverages machine learning to identify customers likely to cancel their telecom service, and offers data-driven recommendations to reduce churn rates.

## How to Use This Repository
- [**Github Pages**](https://ajaanek.github.io/Telco-Customer-Churn-Analysis/): The Kaggle Notebook is available in the deployed Github Page
- [**Kaggle Notebook**](https://www.kaggle.com/code/ajaanekanagasabai/telco-customer-churn-analysis): The project’s complete data analysis, including SQL and Python code for data cleaning and transformation, is available in the Kaggle Notebook. The ipynb file is also available in the repository.
The SQL queries and initial exploratory analysis is available in the SQL folder of the repository.

## Project Overview
This project uses classification models to predict customer churn and uncover the key drivers behind attrition. The primary goal is not only to achieve strong predictive performance but also to understand what factors contribute to churn, allowing for actionable insights that can guide business decisions.

To do this, the project includes both data exploration (in SQL and Python) and model interpretability techniques (e.g., feature importance, SHAP values) to identify the most influential features driving churn.

## Technical Skills Demonstrated
- Efficiently managed and preprocessed raw customer churn data in SQL Server Management Studio (SSMS). Tasks included handling missing values, standardizing inconsistent entries, and preparing the dataset for analysis and modeling.
- Python (Pandas, Matplotlib, Seaborn, Scikit-learn, XGBoost, SHAP):
  - Performed exploratory data analysis (EDA) using Pandas and created visualizations (bar charts, scatter plots, etc) to uncover relationships between churn and customer attributes.
  - Built and optimized multiple machine learning models including Logistic Regression, Random Forest, K-Nearest Neighbors (KNN), and XGBoost using Scikit-learn and GridSearchCV.
  - Evaluated models using metrics like accuracy, precision, recall, and F1 score, and compared them using a summary table.
  - Used XGBoost’s feature importance and SHAP values to interpret model predictions and explain which features had the most influence on churn.
- Analytical Thinking:
  - Investigated potential churn drivers through both SQL queries and Python-based analysis.
  - Identified key behavioral and service-related patterns affecting customer retention (e.g., the impact of contract type and tenure on churn rates).
- Translated technical findings into actionable business recommendations that could guide telecom companies in reducing churn.

## Data Source
The dataset used in this project is the Telco Customer Churn Dataset available on Kaggle. It includes information about telecom customers such as:
- Demographics (e.g., gender, senior citizen status)
- Account information (e.g., tenure, monthly charges, contract type)
- Services used (e.g., internet, streaming, tech support)
- Churn label (whether or not the customer left)

## Project Workflow
1. Data Cleaning & Exploration (SQL & Python)
  - Cleaned the raw dataset in SQL Server Management Studio (SSMS): removed duplicates, handled null values, and standardized formats.
  - Performed exploratory data analysis (EDA) in both SQL and Python to investigate trends and relationships between features and churn (e.g., churn by contract type, tenure, and payment method). These steps helped generate early hypotheses about which customer attributes may be influencing churn.
2. Model Development (Python)
  - Built and tuned classification models: Logistic Regression, Random Forest, K-Nearest Neighbors (KNN), and XGBoost.
  - Evaluated models using metrics such as Accuracy, Precision, Recall, and F1 Score.
  - Selected XGBoost as the best-performing model due to its strong balance of precision and recall.
3. Model Interpretability & Insights
  - Used feature importance and SHAP value analysis to understand how each feature influences the prediction outcome.
  - Visualized how individual factors like contract type and tenure contribute to higher churn probabilities.
  - These interpretability steps helped support business recommendations with transparent reasoning.

## Key Insights
- Contract Type (e.g., month-to-month contracts) and Tenure (shorter duration) are the most important predictors of churn.
- Customers using fiber optic internet and electronic check payments tend to have a higher churn rate.
- Customers with value-added services like online security and tech support are less likely to leave.
- Targeting customers early in their lifecycle with promotions or support could reduce early churn.

## Conclusion
Machine learning models, particularly XGBoost proved to be highly effective in predicting customer churn. More importantly, the combination of exploratory data analysis and model interpretability revealed clear signals for business action:
- Promote longer-term contracts or loyalty programs to reduce churn.
- Focus retention efforts on fiber optic users and those using electronic check payments.
- Invest in value-added services like tech support, which may improve customer satisfaction and retention.

This project shows how combining SQL, Python, and machine learning can solve real-world business problems by delivering not just predictions, but meaningful recommendations.
