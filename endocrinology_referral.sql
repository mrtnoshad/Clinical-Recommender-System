
		select op.jc_uid, op.pat_enc_csn_id_coded as referringEncounterId, 
	      enc.appt_when_jittered as referringApptDateTime, op.order_time_jittered as referralOrderDateTime
		from `starr_datalake2018.order_proc` as op 
		  join `starr_datalake2018.encounter` as enc on op.pat_enc_csn_id_coded = enc.pat_enc_csn_id_coded 
		where proc_code = 'REF31' -- REFERRAL TO ENDOCRINE CLINIC (internal)
		and ordering_mode = 'Outpatient'
		and EXTRACT(YEAR from order_time_jittered) = 2017
    Limit 50
		-- 5675 Records
		-- Sometimes the Referral Order Time is days later than the appointment contact date / appt_when 
		--  (Maybe entered later in follow-up), but usually the same 4730 times
		--  and DATETIME_TRUNC(enc.appt_when_jittered, DAY) = DATETIME_TRUNC(op.order_time_jittered, DAY)
		-- Many of the referring encounters are Telephone, Orders Only, BMT infusions, etc. encounters
		--  Is okay, is still the time of referral order entry, but should use more input context from time before this encounter too

