--(1) Find all (outpatient) encounter referral orders for specialty (Endocrinology)
	WITH 
	referringEncounters AS
	(
		select op.jc_uid, op.pat_enc_csn_id_coded as referringEncounterId, 
	      enc.appt_when_jittered as referringApptDateTime, op.order_time_jittered as referralOrderDateTime
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
		where proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and ordering_mode = 'Outpatient'
		and EXTRACT(YEAR from order_time_jittered) = 2017
		-- 5675 Records
		-- Sometimes the Referral Order Time is days later than the appointment contact date / appt_when 
		--  (Maybe entered later in follow-up), but usually the same 4730 times
		--  and DATETIME_TRUNC(enc.appt_when_jittered, DAY) = DATETIME_TRUNC(op.order_time_jittered, DAY)
		-- Many of the referring encounters are Telephone, Orders Only, BMT infusions, etc. encounters
		--  Is okay, is still the time of referral order entry, but should use more input context from time before this encounter too
	)

	--(1a) Find all (outpatient) encounters with referral orders for ANY specialty (use as reference baseline for relative risk estimates)

--(2) Find all (New Patient) clinic visits for the referred specialty
	WITH
	specialtyNewPatientEncounters AS
	(
		select enc.jc_uid, enc.pat_enc_csn_id_coded as specialtyEncounterId, enc.appt_when_jittered as specialtyEncounterDateTime
		from `starr_datalake2018.encounter` as enc join `starr_datalake2018.dep_map` as dep on enc.department_id = dep.department_id 
		where dep.specialty_dep_c = '7' -- dep.specialty like 'Endocrin%'
		and visit_type like 'NEW PATIENT%' -- Naturally screens to only 'Office Visit' enc_type 
		-- and appt_type in ('Office Visit','Appointment') -- Otherwise Telephone, Refill, Orders Only, etc.
		and appt_status = 'Completed'
		and extract(YEAR from enc.appt_time_jittered) >= 2017	-- >= So capture follow-up visits in 2018 as well
		-- 4796 records in 2017 (10650 for 2017 and after, largely including 2018)
	)

	(2a) Find all (New Patient) clinic visits for ANY specialty (use as reference baseline for relative risk estimates)

(3) Join to match referral orders to respective (first) patient visits within *6* months of referral

	select *, DATETIME_DIFF(specEnc.specialtyEncDateTime, refEnc.referringEncDateTime, MONTH)
	from referringEncounters as refEnc join specialtyNewPatientEncounters as specEnc using (jc_uid)
	where DATETIME_DIFF(specEnc.specialtyEncDateTime, refEnc.referringEncDateTime, MONTH) BETWEEN 0 AND 5
	-- 2636 referred New Patient visit within 6 months
	-- 2899 referred New Patient visit within 12 months

    - Outer join to count how many with no follow-up visit at all
    - Assess distribution of referral time
(4) Find all (sorted by prevalence)
    - Diagnoses from encounters in (1)
		select dx.icd9, dx.icd10, dx_name, count(*)
		from referringEncounters as refEnc 
		  join `starr_datalake2018.diagnosis_code` as dx on refEnc.referringEncounterId = dx.pat_enc_csn_id_coded 
		group by dx.icd9, dx.icd10, dx_name
		order by count(*) desc
		-- 8240 Distinct diagnosis codes, but long tail dominated by head with 512 Osteoporosis, 487 Thyroid Nodule...
    
    - Order Med	from encounters in (2)
		select medication_id, med_description, count(*)
		from specialtyNewPatientEncounters as specEnc
		  join `starr_datalake2018.order_med` as om on specEnc.specialtyEncounterId = om.pat_enc_csn_id_coded 
		where order_class <> 'Historical Med'
		group by medication_id, med_description
		order by count(*) desc
		-- 761 Distinct medication_id descriptions, but can likely boil down many based on active ingredient

		select pharm_class_name, count(*)
		from specialtyNewPatientEncounters as specEnc
		  join `starr_datalake2018.order_med` as om on specEnc.specialtyEncounterId = om.pat_enc_csn_id_coded 
		where order_class <> 'Historical Med'
		group by pharm_class_name
		order by count(*) desc
		-- 143 Distinct pharm_class_name types prescribed in the specialty visits


		select avg(nDistinctOrderMed) as avgDistinctOrderMed, max(nDistinctOrderMed) as maxDistinctOrderMed
		from
		(
		  select specEnc.specialtyEncounterId, count(distinct om.medication_id) as nDistinctOrderMed
		  from specialtyNewPatientEncounters as specEnc
		    join `starr_datalake2018.order_med` as om on specEnc.specialtyEncounterId = om.pat_enc_csn_id_coded 
		  where order_class <> 'Historical Med'
		  group by specEnc.specialtyEncounterId 
		)
		-- 2.0 average distinct order_meds per specialty new visit, max 13

    - Order Proc from encounters in (2)
		select op.proc_code, description, count(*)
		from specialtyNewPatientEncounters as specEnc
		  join `starr_datalake2018.order_proc` as op on specEnc.specialtyEncounterId = op.pat_enc_csn_id_coded 
		group by proc_code, description
		order by count(*) desc
		-- 954 Distinct proc_code descriptions

		select avg(nDistinctOrderProcs) as avgDistinctOrderProcs, max(nDistinctOrderProcs) as maxDistinctOrderProcs
		from
		(
		  select specEnc.specialtyEncounterId, count(distinct op.proc_code) as nDistinctOrderProcs
		  from specialtyNewPatientEncounters as specEnc
		    join `starr_datalake2018.order_proc` as op on specEnc.specialtyEncounterId = op.pat_enc_csn_id_coded 
		  group by specEnc.specialtyEncounterId 
		)
		-- 5.3 average distinct order_procs per specialty new visit, max 38



(5) Filter (1) by only encouters including a diagnosis for XXX

