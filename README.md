Phase II Melanoma Combination Therapy Database (PostgreSQL)

Project Overview
This relational database models a clinical trial tracking targeted combination therapies (BRAF/MEK inhibitors) in patients with metastatic BRAF V600E mutant melanoma. It specifically evaluates how expression levels of **UCHL1** correlate with treatment resistance and tumor volume changes.

Tech Stack & Data Engineering
- Database System: PostgreSQL
- Key Constraints: Strict data integrity using `CHECK` constraints for drug dosing and `FOREIGN KEY` cascading deletes.
- Data Types: Handled high-sensitivity molecular biomarkers using exact `NUMERIC` point scales to prevent data loss.

The Scientific Hypothesis Validated
Using advanced SQL joins and conditional aggregations (`CASE WHEN`), this data structure isolates clinical cohorts based on UCHL1 expression. The queries show that high UCHL1 expression correlates directly with tumor volume progression and elevated S100B serum markers, signaling therapeutic resistance.
