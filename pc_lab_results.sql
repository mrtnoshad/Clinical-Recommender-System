
CREATE OR REPLACE TABLE `Clinical_Collaborative_Filtering.pc_lab_results` AS
(
With PC as
(
  	select op.jc_uid, op.pat_enc_csn_id_coded as PC_enc, 
	      enc.appt_when_jittered as PC_app_datetime, op.order_time_jittered as PC_ref_datetime,
        LR.lab_name,
        (case LR.result_flag when 'High' then 1 when 'Low' then -1 else 0 end) as PC_result
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
      join `starr_datalake2018.lab_result` as LR on op.pat_enc_csn_id_coded = LR.pat_enc_csn_id_coded 
		where op.proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and op.ordering_mode = 'Outpatient'

 ),
 
 Top_Labs as
 (SELECT lab_name, count(*) as freq
 FROM PC
 WHERE PC_result != 0 -- Only consider abnormal lab results
 GROUP BY lab_name 
 ORDER BY freq DESC
 LIMIT 100) -- includes more than 97% of the labs
 
 SELECT PC.* 
 FROM PC INNER JOIN Top_Labs USING (lab_name)
 )
 --SELECT * FROM Top_Labs 
