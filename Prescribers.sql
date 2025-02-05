-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
-- Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS max_total_claims
FROM prescription
GROUP BY npi
ORDER BY max_total_claims DESC
limit 1;

-- Answer:The highest total number of claims is npi:1881634483 with 99707 claims. 


-- 1b. Repeat the above, but this time report the nppes_provider_first_name, 
-- nppes_provider_last_org_name, specialty_description, and the total number of claims.

WITH max_prescriber AS 
    (SELECT npi, SUM(total_claim_count) AS total_claims
    FROM prescription
    GROUP BY npi
    ORDER BY total_claims DESC
	limit 1)
SELECT prescriber.nppes_provider_first_name, 
       prescriber.nppes_provider_last_org_name, 
       prescriber.specialty_description, 
       max_prescriber.total_claims
FROM prescriber 
	INNER JOIN max_prescriber 
	ON prescriber.npi = max_prescriber.npi;

-- Answer: The provider with the highest amount of claims is Bruce Pendley 
-- whose speciality is Family Practice, with 99707 claims.  


-- 2.a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT prescriber.specialty_description, SUM(total_claim_count) AS total_prescrptions_per_specialty
FROM prescription
	INNER JOIN prescriber
	ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY total_prescrptions_per_specialty DESC;

-- Answer:Family Practice had the most prescritions with 9752347.  


-- 2.b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, drug.opioid_drug_flag, SUM(total_claim_count)AS total_prescriptions
FROM prescription
	INNER JOIN prescriber
	ON prescriber.npi = prescription.npi
	INNER JOIN drug 
	ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag like 'Y'
GROUP by specialty_description, drug.opioid_drug_flag  
ORDER by total_prescriptions DESC;

-- Answer: Nurse Practicioner had the most prescriptions for opioids with 900845.  


-- 2.c. Challenge Question: Are there any specialties that appear in the prescriber 
-- table that have no associated prescriptions in the prescription table?

(SELECT specialty_description, COUNT(drug_name) AS presciption_count
FROM prescriber
LEFT join prescription
	USING (npi)
group by specialty_description)
EXCEPT
(SELECT specialty_description, COUNT(drug_name)
from prescriber
LEFT JOIN prescription
	using (npi)
WHERE drug_name IS NOT NULL 
GROUP BY specialty_description);

-- Answer: There are 15 specialties with no associated prescriptions in the prescription table. 


-- 2.d. Difficult Bonus: Do not attempt until you have solved all other problems! 
-- For each specialty, report the percentage of total claims by that specialty which 
-- are for opioids. Which specialties have a high percentage of opioids?

SELECT prescriber.specialty_description,
 	   ROUND(100.0 * SUM(CASE WHEN drug.opioid_drug_flag = 'Y'
    THEN prescription.total_claim_count
    ELSE 0 END)
	/SUM(prescription.total_claim_count), 2) AS opioid_percentage_per_specialty
FROM prescriber 
	INNER JOIN prescription 
	USING (npi)
	INNER JOIN drug 
	USING (drug_name) 
GROUP BY prescriber.specialty_description
ORDER BY opioid_percentage_per_specialty DESC;

-- Answer: The highest specialty is Case Manager/Care Coordinator with 72%,
-- the second highest is Orthopedic Surgery with 67% and the we have 
-- Interventional Pain Management with 58%. 


-- 3.a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS Highest_total_drug_cost
from prescription
INNER JOIN drug
		ON prescription.drug_name = drug.drug_name
GROUP BY generic_name 
ORDER BY highest_total_drug_cost DESC;

-- Answer: The drug with the highest total drug cost is 
-- Insulin Glargine with a total cost of 104264066.35


-- 3.b. Which drug (generic_name) has the hightest total cost per day? 
-- Bonus: Round your cost per day column to 2 decimal places.
-- Google ROUND to see how this works.

SELECT generic_name, ROUND (SUM(prescription.total_drug_cost) / SUM(total_day_supply), 2) AS drug_cost_per_day
FROM prescription
INNER JOIN drug
		on prescription.drug_name = drug.drug_name
GROUP BY generic_name
ORDER BY drug_cost_per_day DESC;

-- Answer: The drug with the highest total cost per day is C1 Esterase Inhibitor 
-- with a 3495.22 cost per day. 


-- 4.a. For each drug in the drug table, return the drug name and 
-- then a column named 'drug_type' which says 'opioid' for drugs which
-- have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which 
-- have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
-- Hint: You may want to use a CASE expression for this. 

SELECT drug_name,
       CASE 
           WHEN opioid_drug_flag = 'Y' THEN 'opioid'
           WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
           else 'neither'
       END AS drug_type
FROM drug;

-- Answer: See table. 


-- 4.b. Building off of the query you wrote for part a, 
-- determine whether more was spent (total_drug_cost) 
-- on opioids or on antibiotics.
-- Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_type, SUM(prescription.total_drug_cost)::MONEY AS total_cost_per_drug_type
FROM
	(SELECT drug_name,
       		CASE 
           		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
           		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
           		ELSE 'neither'
       		END AS drug_type
	FROM drug) type_of_drug
INNER JOIN prescription 
		ON type_of_drug.drug_name = prescription.drug_name 
WHERE drug_type IN ('opioid', 'antibiotic')
GROUP BY drug_type 
ORDER by total_cost_per_drug_type DESC;

-- Answer: More was spent on Opioids. 


-- -- 5.a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information 
-- for all states, not just Tennessee.

SELECT COUNT(cbsa.cbsa) AS cbsas_in_tennessee
from cbsa
INNER JOIN fips_county
        ON cbsa.fipscounty = fips_county.fipscounty
WHERE fips_county.state = 'TN';

-- Answer: We have 42 CBSAs in Tennessee. 


-- -- 5.b. Which cbsa has the largest combined population? Which has the smallest?
-- Report the CBSA name and total population.

select cbsa.cbsaname, SUM(population) AS total_population_per_cbsa 
from population
INNER JOIN cbsa
		ON cbsa.fipscounty = population.fipscounty
group by cbsa.cbsaname
order by total_population_per_cbsa DESC;

-- Answer: The CBSA with the largest combined population is Nashville-Davidson-Murfreesboro-Franklin
-- and the CBSA with the smallest total population is Morrison. 


-- -- 5.c. What is the largest (in terms of population) county which is not included in a CBSA? 
-- Report the county name and population.

SELECT county, population.population
FROM fips_county
inner join population
        ON fips_county.fipscounty = population.fipscounty
left JOIN cbsa
        ON fips_county.fipscounty = cbsa.fipscounty
WHERE cbsa.fipscounty is null 
ORDER BY population.population desc;

-- Answer: The most populated county that is not included in a CBSA
-- is Sevier with 95523 habitants. 


-- -- 6.a. Find all rows in the prescription table where total_claims is at least 3000. 
-- Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count 
FROM prescription
WHERE total_claim_count >= 3000;

-- Answer: We have 9 drugs with a total claim count over 3000. See table for details. 


-- -- 6.b. For each instance that you found in part a, add a column that indicates
-- whether the drug is an opioid.

SELECT prescription.drug_name, prescription.total_claim_count,
       CASE 
           WHEN drug.opioid_drug_flag = 'Y' THEN 'Yes'
           else 'No'
       END AS is_drug_an_opioid
FROM prescription 
INNER JOIN drug 
        on prescription.drug_name = drug.drug_name
WHERE prescription.total_claim_count >= 3000;

-- Answer: We have 9 drugs with a total claim count over 3000, 
-- 2 of them are an opioid. See table for details

-- -- 6.c. Add another column to you answer from the previous part which gives the prescriber 
-- first and last name associated with each row.

SELECT prescription.drug_name, prescription.total_claim_count, 
		CASE 
			when drug.opioid_drug_flag = 'Y' then 'opioid'
			else 'not opioid'
		end AS opioid_condition,
		prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name
FROM prescription
Inner join drug 
        using (drug_name)
INNER JOIN prescriber
		using (npi)
WHERE prescription.total_claim_count>= 3000;

-- Answer: We have 9 drugs with a total claim count over 3000, 
-- 2 of them are an opioid. We can also see that David Coffey is the 
-- champion of prescribing opiods. See table for details.

-- -- The goal of this exercise is to generate a full list of all pain management specialists 
-- in Nashville and the number of claims they had for each opioid. 
-- Hint: The results from all 3 parts will have 637 rows.

-- -- 7.a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
-- where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prescriber.npi, drug.drug_name
from prescriber 
CROSS JOIN drug 
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
and drug.opioid_drug_flag = 'Y';

-- Answer: See table for details. 

-- -- 7.b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations,
-- whether or not the prescriber had any claims. You should report the npi, the drug name,
-- and the number of claims (total_claim_count).

SELECT prescriber.npi, drug.drug_name, COALESCE(SUM(prescription.total_claim_count), 0) AS total_claims_per_prescriber
FROM prescriber 
JOIN prescription 
using (npi)
JOIN drug 
using (drug_name)
GROUP BY prescriber.npi, drug.drug_name
ORDER BY total_claims_per_prescriber DESC;

-- Answer: See table for details. 


-- -- 7.c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
-- Hint - Google the COALESCE function.
-- Answer: Same as 7.b.


