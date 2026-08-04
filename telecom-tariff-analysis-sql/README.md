# Telecom Tariff Analysis — SQL

## Project Overview

This project analyzes customer activity and monthly spending across the Smart and Ultra tariff plans.

The analysis focuses on monthly calls, internet traffic and SMS usage, identifies customers whose spending exceeds the monthly tariff fee, and compares spending patterns between the two tariff plans.

The goal is to support decisions about potential tariff updates and targeted offers for highly active customers.

## SQL Analysis

[View SQL code](telecom_tariff_analysis.sql)

## Data

The database contains five tables in the `telecom` schema:

- `users`
- `calls`
- `internet`
- `messages`
- `tariffs`

The dataset was provided as part of an educational project. The original data and course materials are not included in this repository.


## What I Did

- Checked customer data for missing values and verified `user_id` uniqueness.
- Checked call data for missing values, duration range and zero-duration calls.
- Aggregated calls, internet traffic and SMS by customer and calendar month.
- Built a customer-month dataset combining all three types of activity.
- Calculated usage above tariff limits and total monthly customer spending.
- Compared the number of active customers and average monthly spending between the Smart and Ultra tariffs.
- Compared customers with spending above the monthly tariff fee, including average monthly spending and average overpayment.


## Tools

- PostgreSQL
- SQL
- CTEs
- JOINs
- UNION
- CASE
- COALESCE
- Temporary views


## Results

### Active customers by tariff

| tariff | active_users | avg_monthly_cost |
|---|---:|---:|
| smart | 328 | 1206.10 |
| ultra | 134 | 2056.65 |


### Active customers with spending above the monthly tariff fee

| tariff | over_limit_users | avg_monthly_cost | avg_overpayment |
|---|---:|---:|---:|
| smart | 318 | 1433.42 | 883.42 |
| ultra | 40 | 2731.79 | 781.79 |


## Key Findings

- Smart had more active customers than Ultra: 328 versus 134.
- Ultra had higher average monthly spending: 2056.65 compared with 1206.10 for Smart.
- 318 Smart customers and 40 Ultra customers had at least one month with spending above the monthly tariff fee.
- In months with overage, Ultra had higher average monthly spending, while Smart had a higher average overpayment above the tariff fee.


## Business Recommendation

The Smart tariff may be worth reviewing: 318 out of 328 active Smart customers had at least one month with spending above the monthly tariff fee.

This suggests an opportunity to evaluate the included service limits and consider targeted upgrades or additional packages for highly active Smart customers.

Further decisions about tariff changes would require additional information such as profitability, customer retention and usage patterns over time.
