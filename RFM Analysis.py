#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar 13 12:05:32 2025

@author: avi
"""

## importing libraries and data
from datetime import datetime
import pandas as pd

df = pd.read_csv('/Users/avi/Desktop/Portfolios/Online Retail/RFM.csv')

print(df.head())
print(df.dtypes)

## converting date into the right datatype
df['most_recent_purchase'] = pd.to_datetime(df['most_recent_purchase'])
print(df.dtypes)

## calculating the recency of each customer
reference_date = pd.to_datetime('2024-01-01')
df['Recency'] = (reference_date - df['most_recent_purchase']).dt.days

## creating RFM dataframe
rfm_df = df[['customer_id','Recency', 'orders', 'revenue']].copy()
rfm_df.rename(columns={'orders':'Frequency', 'revenue':'Monetary'}, inplace=True)
print(rfm_df.head())

## scoring recency, frequency, and monetary
rfm_df['RScore'] = pd.cut(rfm_df['Recency'],
                           bins=[0,30,60,90,120,float('inf')],
                           labels=[5,4,3,2,1])
rfm_df['FScore'] = pd.qcut(rfm_df['Frequency'], q=5, labels=[1,2,3,4,5])
rfm_df['MScore'] = pd.qcut(rfm_df['Monetary'], q=5, labels=[1,2,3,4,5])

# creating new df with just RFM scores
rfm_scores = rfm_df[['customer_id','RScore','FScore','MScore']]
print(rfm_scores)

## converting dtypes and removing nulls
print(rfm_scores.dtypes)
rfm_scores[['RScore', 'FScore', 'MScore']] = rfm_scores[['RScore', 'FScore', 'MScore']].apply(pd.to_numeric)
print(rfm_scores.dtypes)

## calculating weighted average
rfm_scores['Weighted_avg'] = (rfm_scores['RScore'] * 0.4 +
                              rfm_scores['FScore'] * 0.3 +
                              rfm_scores['MScore'] * 0.3)
print(rfm_scores.head())

# removing null scores
print(rfm_scores['Weighted_avg'].isna().sum())
rfm_scores = rfm_scores.dropna(subset=['Weighted_avg'])
print(rfm_scores['Weighted_avg'].isna().sum())

## how many customers fall into each category
print(pd.cut(rfm_scores['Weighted_avg'], bins = [0,2.5,3.5,4.5,float('inf')], 
             labels = ['Best', 'Good', 'Okay', 'Poor'],
             right = False).value_counts(sort=False))