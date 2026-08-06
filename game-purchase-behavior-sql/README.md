# Game Purchase Behavior Analysis — SQL

## Project Overview

This project analyzes player purchasing behavior in an online fantasy game.

Players can use premium in-game currency to purchase epic items. The `payer` attribute indicates whether a player has purchased premium currency with real money, while the `events` table contains in-game item purchases made using that currency.

The analysis focuses on payer share, purchase amounts, differences between payers and non-payers, item popularity, character races and purchase frequency.

The goal is to identify patterns in player purchasing behavior and areas that may require further investigation or experimentation.

## SQL Analysis

[View SQL code](game_purchase_behavior.sql)

## Data

The analysis uses tables from the `fantasy` schema containing:

- player data;
- in-game purchase transactions;
- character races;
- game items.

The dataset was provided as part of an educational project. The original data and course materials are not included in this repository.

## What I Did

- Checked player and transaction data for missing values and verified player ID uniqueness.
- Calculated the overall payer share and compared payer share across character races.
- Analyzed the distribution of in-game purchase amounts using mean, median and standard deviation.
- Identified and investigated zero-value transactions.
- Compared purchase behavior between payers and non-payers.
- Calculated item purchase share and buyer share to identify the most and least popular items.
- Built player-level purchase metrics and compared purchasing behavior across character races.
- Segmented active buyers by purchase frequency using `NTILE()`.

## Tools

- PostgreSQL
- SQL
- CTEs
- JOINs
- CASE
- COALESCE
- Conditional aggregation
- Window functions

## Results

### Overall purchase statistics

| metric | value |
|---|---:|
| total purchases | 1,307,678 |
| total premium currency spent | 686,615,040 |
| average purchase amount | 525.69 |
| median purchase amount | 74.86 |
| zero-value purchases | 907 |

### Payer vs non-payer purchase behavior

| player_type | buyers | avg_purchases_per_buyer | avg_total_currency_spent_per_buyer |
|---|---:|---:|---:|
| Payer | 2,444 | 82 | 55,468 |
| Non-payer | 11,348 | 98 | 48,588 |

## Key Findings

- Approximately **18% of registered players** had purchased premium currency with real money.
- Payer share was relatively similar across character races, at approximately **17–19%**.
- Purchase amounts were strongly right-skewed: the average purchase amount was **525.69**, compared with a median of **74.86** premium currency units.
- **907 zero-value transactions** were identified. All were associated with the same item, and most were concentrated within one player account, indicating an anomaly that requires further investigation.
- After excluding zero-value transactions, **13,792 players** made at least one in-game purchase.
- Payers made fewer purchases per buyer on average (**82 vs 98**), but spent more premium currency per buyer overall (**55,468 vs 48,588**).
- Purchase activity was highly concentrated: two items accounted for almost **98% of non-zero purchases**, while **68 items** were purchased fewer than 10 times.
- Purchase behavior also varied across character races and purchase-frequency segments, suggesting potential differences in player behavior that could be explored further.

## Business Recommendation

The concentration of purchase activity around a small number of items should be investigated further. Pricing, promotion or item-placement experiments could be tested for both highly popular and rarely purchased items, while monitoring their impact on purchase behavior and player retention.

Zero-value transactions should be investigated as a data-quality or transaction-processing issue before they are included in purchase-related metrics.

Player segments based on payer status, character race and purchase frequency can be used to design targeted experiments. However, changes to game balance, premium-currency mechanics or pricing would require additional data on real-money revenue, retention and player behavior over time.
