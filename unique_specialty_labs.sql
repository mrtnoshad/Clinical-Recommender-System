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

select op.proc_code, description, count(*)
		from specialtyNewPatientEncounters as specEnc
		  join `starr_datalake2018.order_proc` as op on specEnc.specialtyEncounterId = op.pat_enc_csn_id_coded 
		group by proc_code, description
		order by count(*) desc
    
