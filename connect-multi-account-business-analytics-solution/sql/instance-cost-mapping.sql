-- Instance Cost Mapping for Multi-Instance Pricing

-- Cost per instance/account view
CREATE OR REPLACE VIEW instance_cost_summary AS
SELECT
  connect_instance,
  billing_account,
  DATE(initiation_timestamp) as cost_date,
  COUNT(DISTINCT contact_id) as total_calls,
  SUM(cost_per_call) as daily_instance_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  -- Cost breakdown by channel
  SUM(CASE WHEN channel = 'VOICE' THEN cost_per_call ELSE 0 END) as voice_cost,
  SUM(CASE WHEN channel = 'CHAT' THEN cost_per_call ELSE 0 END) as chat_cost,
  -- Usage metrics
  SUM(total_duration_min) as total_minutes,
  AVG(total_duration_min) as avg_call_duration
FROM contact_record_operational
GROUP BY connect_instance, billing_account, DATE(initiation_timestamp);

-- Multi-account cost rollup
CREATE OR REPLACE VIEW multi_account_cost_rollup AS
SELECT
  billing_account,
  cost_date,
  COUNT(DISTINCT connect_instance) as active_instances,
  SUM(daily_instance_cost) as account_daily_cost,
  SUM(total_calls) as account_total_calls,
  AVG(avg_cost_per_call) as account_avg_cost_per_call,
  SUM(voice_cost) as account_voice_cost,
  SUM(chat_cost) as account_chat_cost
FROM instance_cost_summary
GROUP BY billing_account, cost_date;