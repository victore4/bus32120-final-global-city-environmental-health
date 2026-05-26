# Global City Environmental Health Risk Analysis

This repository contains the final project for Data Analysis with Python and SQL.

## Project question

Which selected global cities look more concerning from an environmental health perspective when current air quality is combined with long-run heat patterns?

## Target audience

The target audience is an analyst advising relocation teams, employers, or internationally mobile households that want a practical, health-oriented comparison of selected global cities.

## Data sources

1. IQAir AirVisual API: current city-level air quality.
2. Open-Meteo Historical Weather API: daily weather history from 2000 through 2025.
3. City context table: manually curated metadata used for segmentation and feature engineering.

## Files

- `Final_Global_City_Environmental_Health_Analysis.ipynb`: Python notebook with EDA, feature engineering, modeling, and conclusions.
- `Final_Global_City_Environmental_Health_Analysis.pdf`: PDF export of the final notebook.
- `Final_Project_SQL_Queries.sql`: separate SQL file with the required SQL queries.
- `data/current_aq.csv`: cached current AQI data.
- `data/daily_weather.csv`: cached historical weather data.
- `data/global_city_environment.sqlite`: SQLite database created from the cleaned data.

## Methods

The project uses Python, Pandas, Matplotlib, SQLite, linear regression, and Random Forest regression. The analysis includes data quality checks, aggregate EDA tables, visualizations, feature engineering, SQL queries, and model validation.

## Key findings

New Delhi is the clearest high-concern city in this selected sample because it combines very poor current AQI with the highest long-run heat exposure. Los Angeles has meaningful heat exposure despite relatively good current AQI in this snapshot. Tokyo and New York are trend-watch cases because their recent hot-day counts have increased.

The models are useful as structured checks on the EDA, but they should not be treated as production-ready forecasting tools without a larger and more diverse city sample.
