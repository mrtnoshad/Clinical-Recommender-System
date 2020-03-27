CREATE OR REPLACE TABLE `Clinical_Collaborative_Filtering.spec_proc_v2` AS
(
WITH
	
  PC AS
  (
  	select op.jc_uid, op.pat_enc_csn_id_coded as PC_enc, 
	      enc.appt_when_jittered as PC_app_datetime, op.order_time_jittered as PC_ref_datetime
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
		where proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and ordering_mode = 'Outpatient'
  ),
  
  SP AS
	(
		select enc.jc_uid, enc.pat_enc_csn_id_coded as SP_enc, enc.appt_when_jittered as SP_app_datetime,
      --DX.dx_name as SP_diagnosis
      PR.proc_id,
      PR.description as proc_name,
      PR.order_time_jittered as proc_order_time,
      authrzing_prov_map_id as prov_id
		from `starr_datalake2018.encounter` as enc 
      join `starr_datalake2018.dep_map` as dep on enc.department_id = dep.department_id     
      --join `starr_datalake2018.diagnosis_code` as DX on (enc.pat_enc_csn_id_coded = DX.pat_enc_csn_id_coded)
      join `starr_datalake2018.order_proc` as PR on (enc.pat_enc_csn_id_coded = PR.pat_enc_csn_id_coded)
		where dep.specialty_dep_c = '7' -- dep.specialty like 'Endocrin%'
    		and visit_type like 'NEW PATIENT%' -- Naturally screens to only 'Office Visit' enc_type 
		-- and appt_type in ('Office Visit','Appointment') -- Otherwise Telephone, Refill, Orders Only, etc.
		and appt_status = 'Completed'
	),
  
Joined AS 
(
  
Select PC.*, SP.* EXCEPT (jc_uid)
  FROM PC JOIN SP USING (jc_uid)
  WHERE SP.SP_app_datetime BETWEEN PC.PC_ref_datetime AND DATETIME_ADD(PC.PC_ref_datetime, INTERVAL 4 MONTH)
  ORDER BY PC.jc_uid 
 ),
 
 PT AS
 (
 SELECT PC_enc, EXTRACT(DATE FROM proc_order_time) as proc_order_date  FROM Joined
 GROUP BY PC_enc, proc_order_date
 ORDER BY PC_enc, proc_order_date 
 ) 

SELECT Joined.* FROM Joined, PT
WHERE EXTRACT(DATE FROM Joined.proc_order_time)= PT.proc_order_date
 )
