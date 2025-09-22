CREATE OR REPLACE VIEW ${database_name}.multi_account_cost_analysis AS
SELECT 
  contact_id,
  aws_account_id,
  CASE 
    %{ for name, config in account_configs ~}
    WHEN aws_account_id = '${config.account_id}' THEN '${name}'
    %{ endfor ~}
    ELSE 'Unknown'
  END as account_name,
  CASE 
    %{ for name, config in account_configs ~}
    WHEN aws_account_id = '${config.account_id}' THEN ${config.cost_per_minute}
    %{ endfor ~}
    ELSE 0.02
  END as cost_per_minute,
  DATE(initiation_timestamp) as call_date,
  channel,
  queue_name,
  agent_username,
  disconnect_reason,
  CASE 
    WHEN disconnect_timestamp IS NOT NULL AND initiation_timestamp IS NOT NULL 
    THEN date_diff('millisecond', initiation_timestamp, disconnect_timestamp) / 60000.0
    ELSE 0
  END as call_duration_minutes,
  CASE 
    WHEN disconnect_timestamp IS NOT NULL AND initiation_timestamp IS NOT NULL 
    THEN (date_diff('millisecond', initiation_timestamp, disconnect_timestamp) / 60000.0) * 
         CASE 
           %{ for name, config in account_configs ~}
           WHEN aws_account_id = '${config.account_id}' THEN ${config.cost_per_minute}
           %{ endfor ~}
           ELSE 0.02
         END
    ELSE 0
  END as total_cost,
  initiation_timestamp,
  disconnect_timestamp
FROM ${database_name}.contact_records
WHERE initiation_timestamp >= current_date - interval '30' day
  AND initiation_timestamp IS NOT NULL;