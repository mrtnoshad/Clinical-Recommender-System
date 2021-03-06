CREATE OR REPLACE TABLE `Clinical_Collaborative_Filtering.pc_proc`  AS 
(
WITH
	
  PC AS
  (
  	select op.jc_uid, op.pat_enc_csn_id_coded as PC_enc, 
	      enc.appt_when_jittered as PC_app_datetime, op.order_time_jittered as PC_ref_datetime,
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
      join `starr_datalake2018.diagnosis_code` as DX on (enc.pat_enc_csn_id_coded = DX.pat_enc_csn_id_coded)
		where proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and ordering_mode = 'Outpatient'
  ),
  
  PC_OP AS
  (
  	select pat_enc_csn_id_coded as PC_enc, 
	    order_type,
      proc_id,
      description as proc_name,
      order_time_jittered as proc_order_time,
		from `starr_datalake2018.order_proc`  
    WHERE ordering_mode = 'Outpatient'
  ),
  
  SP AS
	(
		select enc.jc_uid, enc.pat_enc_csn_id_coded as SP_enc, enc.appt_when_jittered as SP_app_datetime
		from `starr_datalake2018.encounter` as enc join `starr_datalake2018.dep_map` as dep on enc.department_id = dep.department_id    
    --join `starr_datalake2018.diagnosis_code` as DX on (enc.pat_enc_csn_id_coded = DX.pat_enc_csn_id_coded)
		where dep.specialty_dep_c = '7' -- dep.specialty like 'Endocrin%'
    		and visit_type like 'NEW PATIENT%' -- Naturally screens to only 'Office Visit' enc_type 
		-- and appt_type in ('Office Visit','Appointment') -- Otherwise Telephone, Refill, Orders Only, etc.
		and appt_status = 'Completed'
	),
  
  Joined AS
  (
  SELECT PC.*, SP.* EXCEPT (jc_uid)
  FROM PC JOIN SP USING (jc_uid)
  WHERE SP.SP_app_datetime BETWEEN PC.PC_ref_datetime AND DATETIME_ADD(PC.PC_ref_datetime, INTERVAL 4 MONTH)
  ORDER BY PC.jc_uid 
  )
  SELECT Joined.*, PC_OP.* EXCEPT (PC_enc)
  FROM Joined 
  INNER Join PC_OP On (PC_OP.PC_enc = Joined.PC_enc)
  ORDER BY PC_enc
)

