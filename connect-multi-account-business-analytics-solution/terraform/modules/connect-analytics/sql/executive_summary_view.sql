CREATE OR REPLACE VIEW ${database_name}.executive_summary AS
SELECT 
  account_name,
  aws_account_id,
  date_trunc('month', call_date) as month_year,
  COUNT(*) as monthly_calls,
  SUM(call_duration_minutes) as monthly_agent_minutes,
  SUM(total_cost) as monthly_cost,
  AVG(total_cost) as avg_cost_per_call,
  SUM(CASE WHEN disconnect_reason = 'CUSTOMER_DISCONNECT' THEN 1 ELSE 0 END) as customer_disconnects,
  SUM(CASE WHEN disconnect_reason = 'AGENT_DISCONNECT' THEN 1 ELSE 0 END) as agent_disconnects,
  ROUND(
    SUM(CASE WHEN disconnect_reason = 'CUSTOMER_DISCONNECT' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2
  ) as customer_disconnect_rate,
  ROUND(
    SUM(CASE WHEN disconnect_reason = 'AGENT_DISCONNECT' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2
  ) as agent_disconnect_rate
FROM ${database_name}.multi_account_cost_analysis
GROUP BY 
  account_name, 
  aws_account_id, 
  date_trunc('month', call_date)
ORDER BY 
  month_year DESC, 
  monthly_cost DESC;