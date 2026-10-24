"""
Step 2: Data Cleaning
Project: Oral Health and Chronic Disease Across U.S. Counties
Input:  data/places_county_raw.csv   (CDC PLACES County Data, 2025 release)
Output: data/places_county_clean.csv
"""

import pandas as pd

# ------------------------------------------------------------------
# 1. LOAD the raw data
# ------------------------------------------------------------------
df = pd.read_csv("data/places_county_raw.csv")
print(f"Raw data: {df.shape[0]} counties, {df.shape[1]} columns")

# ------------------------------------------------------------------
# 2. SUBSET: keep only the columns we need, and give them readable names
#    We use age-adjusted rates (_AdjPrev) so counties with older
#    populations can be compared fairly with younger ones.
# ------------------------------------------------------------------
columns = {
    "StateAbbr":          "state",
    "StateDesc":          "state_name",
    "CountyName":         "county",
    "CountyFIPS":         "fips",
    "TotalPopulation":    "population",
    "DENTAL_AdjPrev":     "dental_visit_pct",      # adults who visited a dentist in past year
    "TEETHLOST_AdjPrev":  "teeth_lost_pct",        # adults 65+ who lost all teeth
    "DIABETES_AdjPrev":   "diabetes_pct",          # adults with diagnosed diabetes
    "CHD_AdjPrev":        "heart_disease_pct",     # adults with coronary heart disease
    "CSMOKING_AdjPrev":   "smoking_pct",           # current smokers
    "OBESITY_AdjPrev":    "obesity_pct",           # adults with obesity
    "ACCESS2_AdjPrev":    "uninsured_pct",         # adults 18-64 without health insurance
}
df = df[list(columns.keys())].rename(columns=columns)

# ------------------------------------------------------------------
# 3. FIX DATA TYPES
#    Population is stored as text like "14,369" -> remove commas, make it a number.
#    FIPS is a 5-digit county code; Tableau needs it as text with leading
#    zeros (e.g. 1001 -> "01001") to draw the county map correctly.
# ------------------------------------------------------------------
df["population"] = df["population"].astype(str).str.replace(",", "").astype(int)
df["fips"] = df["fips"].astype(str).str.zfill(5)

# ------------------------------------------------------------------
# 4. HANDLE MISSING VALUES
#    Kentucky and Pennsylvania have no 2023 measures in this release
#    (diabetes, heart disease, smoking, etc. are blank), so we exclude them.
# ------------------------------------------------------------------
missing = df[df["diabetes_pct"].isna()]
print(f"\nCounties with missing measures: {len(missing)}")
print(missing["state"].value_counts().to_string())
df = df.dropna()

# ------------------------------------------------------------------
# 5. DATA QUALITY CHECK: clinical plausibility
#    Nationally, most counties report 50-70% of adults visiting a dentist.
#    Every Mississippi county reports only 5-13%, which is not plausible
#    and points to a data issue for that state, so we exclude it.
# ------------------------------------------------------------------
ms = df[df["state"] == "MS"]
print(f"\nMississippi dental visit rates: {ms['dental_visit_pct'].min()}% to "
      f"{ms['dental_visit_pct'].max()}% (rest of U.S. median: "
      f"{df[df['state'] != 'MS']['dental_visit_pct'].median()}%)")
df = df[df["state"] != "MS"]
print(f"Excluded {len(ms)} Mississippi counties as implausible")

# ------------------------------------------------------------------
# 6. FEATURE ENGINEERING: group counties into Low / Medium / High
#    dental visit levels (each group has about one third of counties).
# ------------------------------------------------------------------
df["dental_group"] = pd.qcut(df["dental_visit_pct"], q=3,
                             labels=["Low", "Medium", "High"])

# ------------------------------------------------------------------
# 7. QUICK SUMMARY, then EXPORT
# ------------------------------------------------------------------
print(f"\nClean data: {df.shape[0]} counties, {df.shape[1]} columns")
print("\nAverage diabetes and heart disease by dental visit group:")
print(df.groupby("dental_group", observed=True)[["diabetes_pct", "heart_disease_pct"]]
        .mean().round(1).to_string())

df.to_csv("data/places_county_clean.csv", index=False)
print("\nSaved: data/places_county_clean.csv")
