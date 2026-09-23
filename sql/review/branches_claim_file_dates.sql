-- RUN 2026-09-23, database 235, SELECT only. L9 A28. Latest three monthly file labels, counts and loss dates. Returned 3 aggregate rows.
-- Expected: metadata and file dates, with no prespecified numeric result.
SELECT claims_file,count() AS snapshot_rows,uniqExact(claim_id) AS claims,min(loss_date) AS first_loss,max(loss_date) AS last_loss FROM dbt.claims_smga GROUP BY claims_file ORDER BY toDate(concat(splitByChar('-',claims_file)[2],'-',leftPad(splitByChar('-',claims_file)[1],2,'0'),'-01')) DESC LIMIT 3;

