CREATE OR REPLACE TABLE `Clinical_Collaborative_Filtering.pc_lab_results` AS
(
  	select op.jc_uid, op.pat_enc_csn_id_coded as PC_enc, 
	      enc.appt_when_jittered as PC_app_datetime, op.order_time_jittered as PC_ref_datetime,
        (case LR.result_flag when 'High' then 1 when 'Low' then -1 else 0 end) as PC_result
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
      join `starr_datalake2018.lab_result` as LR on op.pat_enc_csn_id_coded = LR.pat_enc_csn_id_coded 
		where op.proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and op.ordering_mode = 'Outpatient'

 )
