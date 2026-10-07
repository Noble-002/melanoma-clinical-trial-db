-- =========================================================================
-- PROJECT 1: PHASE II MELANOMA CLINICAL TRIAL DATABASE (PostgreSQL)
-- Focus: Evaluating UCHL1 Expression & BRAF/MEK Inhibitor Resistance
-- =========================================================================


-- 1. SCHEMA DESIGN: Create interconnected relational tables with strict constraints

-- Table A: Patients (Demographics, core mutations, and thesis target UCHL1)
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    age INT NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    braf_status VARCHAR(20) DEFAULT 'BRAF V600E',
    uchl1_baseline_expression NUMERIC(5,2) NOT NULL, -- Fold-change (1.00 = Normal, >3.00 = High Overexpression)
    enrollment_date DATE DEFAULT CURRENT_DATE
);

-- Table B: Biomarkers (Melanoma-specific serum markers to track disease burden)
CREATE TABLE biomarkers (
    biomarker_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    test_date DATE NOT NULL,
    s100b_level_ug_l NUMERIC(6,3),    -- Serum S100B (Normal < 0.100 ug/L)
    ldh_level_u_l NUMERIC(5,1)        -- Lactate Dehydrogenase (Normal < 250 U/L)
);

-- Table C: Trials Log (Dosing records for Combination Therapy and phenotypic response)
CREATE TABLE trials_log (
    log_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    braf_inhibitor_dose_mg INT CHECK (braf_inhibitor_dose_mg IN (0, 75, 150)), -- Dabrafenib standard doses
    mek_inhibitor_dose_mg NUMERIC(3,1) CHECK (mek_inhibitor_dose_mg IN (0.0, 1.0, 2.0)), -- Trametinib standard doses
    tumor_volume_cm3 NUMERIC(5,2) NOT NULL,
    tumor_shrinkage_percentage NUMERIC(4,1) DEFAULT 0.0
);


-- 2. DATA POPULATION: Inject scientifically realistic clinical trial mock data

-- Insert clinical trial patient cohorts
INSERT INTO patients (age, gender, braf_status, uchl1_baseline_expression, enrollment_date) VALUES
(45, 'Female', 'BRAF V600E', 1.10, '2026-03-01'), -- Pt 1: Normal UCHL1 control
(52, 'Male',   'BRAF V600E', 5.40, '2026-03-01'), -- Pt 2: High UCHL1 Overexpression
(61, 'Female', 'BRAF V600E', 0.95, '2026-03-05'), -- Pt 3: Normal UCHL1 control
(38, 'Female', 'BRAF V600E', 1.40, '2026-03-10'), -- Pt 4: Low/Normal UCHL1
(67, 'Male',   'BRAF V600E', 6.20, '2026-03-12'); -- Pt 5: High UCHL1 Overexpression

-- Insert longitudinal biomarker results (Baseline vs Month 1 Follow-up)
INSERT INTO biomarkers (patient_id, test_date, s100b_level_ug_l, ldh_level_u_l) VALUES
(1, '2026-03-01', 0.520, 340.0), -- Pt 1 Baseline
(1, '2026-04-01', 0.075, 210.0), -- Pt 1 Month 1: S100B normalized (<0.100)
(2, '2026-03-01', 0.890, 480.0), -- Pt 2 Baseline
(2, '2026-04-01', 1.120, 520.0), -- Pt 2 Month 1: Biomarkers climbed (Resistant)
(3, '2026-03-05', 0.410, 290.0), -- Pt 3 Baseline
(3, '2026-04-05', 0.082, 195.0), -- Pt 3 Month 1: Favorable response
(5, '2026-03-12', 1.350, 610.0), -- Pt 5 Baseline
(5, '2026-04-12', 1.480, 650.0); -- Pt 5 Month 1: Biomarkers climbed (Resistant)

-- Insert treatment responses tracking standard full combination doses
INSERT INTO trials_log (patient_id, visit_date, braf_inhibitor_dose_mg, mek_inhibitor_dose_mg, tumor_volume_cm3, tumor_shrinkage_percentage) VALUES
(1, '2026-03-01', 150, 2.0, 15.40, 0.0),
(1, '2026-04-01', 150, 2.0, 4.20,  72.7),  -- Normal UCHL1: Massive tumor shrinkage
(2, '2026-03-01', 150, 2.0, 28.90, 0.0),
(2, '2026-04-01', 150, 2.0, 30.10, -4.1),  -- High UCHL1: Tumor grew (Resistance profile)
(3, '2026-03-05', 150, 2.0, 11.20, 0.0),
(3, '2026-04-05', 150, 2.0, 3.10,  72.3),  -- Normal UCHL1: Massive tumor shrinkage
(5, '2026-03-12', 150, 2.0, 22.40, 0.0),
(5, '2026-04-12', 150, 2.0, 24.10, -7.5);  -- High UCHL1: Tumor grew (Resistance profile)


-- 3. ANALYTICAL PORTFOLIO QUERY: The Thesis Validation Insight
-- Aggregates data into clinical cohorts based on your thesis marker (UCHL1 expression)
SELECT 
    CASE 
        WHEN p.uchl1_baseline_expression > 3.0 THEN 'High UCHL1 Overexpression (>3x)'
        ELSE 'Normal/Low UCHL1 Expression'
    END AS uchl1_cohort,
    COUNT(DISTINCT p.patient_id) AS total_patients,
    ROUND(AVG(tl.tumor_shrinkage_percentage), 2) AS avg_tumor_shrinkage_pct,
    ROUND(AVG(b.s100b_level_ug_l), 3) AS avg_follow_up_s100b
FROM patients p
INNER JOIN trials_log tl ON p.patient_id = tl.patient_id
INNER JOIN biomarkers b ON p.patient_id = b.patient_id
WHERE tl.tumor_shrinkage_percentage <> 0.0 -- Isolate post-treatment metrics
  AND b.test_date = tl.visit_date
GROUP BY 
    CASE 
        WHEN p.uchl1_baseline_expression > 3.0 THEN 'High UCHL1 Overexpression (>3x)'
        ELSE 'Normal/Low UCHL1 Expression'
    END;
