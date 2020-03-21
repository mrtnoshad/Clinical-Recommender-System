CREATE OR REPLACE TABLE `Clinical_Collaborative_Filtering.pc_lab_results_v2` AS --labs within last 2 months
--SELECT PC_enc , count(*) FROM
(
With PC as
(
  	select op.jc_uid, op.pat_enc_csn_id_coded as PC_enc, 
	      enc.appt_when_jittered as PC_app_datetime, op.order_time_jittered as PC_ref_datetime,
        --LR.lab_name,
        --(case LR.result_flag when 'High' then 1 when 'Low' then -1 else 0 end) as PC_result
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
      --join `starr_datalake2018.lab_result` as LR on op.pat_enc_csn_id_coded = LR.pat_enc_csn_id_coded 
		where op.proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and op.ordering_mode = 'Outpatient'
    and op.proc_code = 'REF31' 

 ),
 
 LR as (
 select rit_uid, pat_enc_csn_id_coded as PC_lab_enc, 
        lab_name,
        (case result_flag when 'High' then 1 when 'Low' then -1 else 0 end) as PC_result,
        taken_time_jittered as lab_time
		from  `starr_datalake2018.lab_result` 
 
 ),
 
 Top_Labs as
 (SELECT lab_name, count(*) as freq
 FROM LR
 WHERE PC_result != 0 -- Only consider abnormal lab results
 GROUP BY lab_name 
 ORDER BY freq DESC
 LIMIT 100) 

 
 SELECT PC.* , LR.lab_name, LR.PC_result
 FROM PC 
 JOIN LR on (LR.rit_uid=PC.jc_uid)
 INNER JOIN Top_Labs ON (Top_Labs.lab_name= LR.lab_name)
  WHERE PC.PC_ref_datetime BETWEEN LR.lab_time AND DATETIME_ADD(LR.lab_time, INTERVAL 2 MONTH)
 )
 --GROUP BY PC_enc
