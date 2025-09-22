-- Connect Data Lake Native Queries
-- These queries work with Amazon Connect's built-in Data Lake tables
-- Use these after setting up cross-account data sharing

-- 1. Basic multi-account contact records view
CREATE OR REPLACE VIEW multi_account_contacts AS
SELECT 
  account_id,
  CASE 
    WHEN account_id = '111111111111' THEN 'Production'
    WHEN account_id = '222222222222' THEN 'Development' 
    WHEN account_id = '333333333333' THEN 'Test'
    ELSE 'Unknown'
  END as account_name,
  contact_id,
  instance_arn,
  initiation_timestamp,
  disconnect_timestamp,
  initiation_method,
  channel,
  queue_name,
  agent_username
FROM amazon_connect.contact_records
WHERE disconnect_timestamp IS NOT NULL;

-- 2. Cost per call analysis with account-specific pricing
CREATE OR REPLACE VIEW cost_per_call_analysis AS
SELECT 
  account_id,
  account_name,
  contact_id,
  instance_arn,
  initiation_timestamp,
  disconnect_timestamp,
  -- Calculate duration in minutes
  (CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0 as duration_minutes,
  -- Account-specific rates per minute
  CASE 
    WHEN account_id = '111111111111' THEN 0.025  -- Production: $0.025/min
    WHEN account_id = '222222222222' THEN 0.020  -- Development: $0.020/min
    WHEN account_id = '333333333333' THEN 0.015  -- Test: $0.015/min
    ELSE 0.025
  END as rate_per_minute,
  -- Calculate cost per call
  ((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) * 
  CASE 
    WHEN account_id = '111111111111' THEN 0.025
    WHEN account_id = '222222222222' THEN 0.020
    WHEN account_id = '333333333333' THEN 0.015
    ELSE 0.025
  END as cost_per_call,
  queue_name,
  agent_username,
  channel
FROM multi_account_contacts;

-- 3. Daily cost summary by account
CREATE OR REPLACE VIEW daily_cost_summary AS
SELECT 
  account_id,
  account_name,
  DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000)) as call_date,
  COUNT(*) as total_calls,
  COUNT(DISTINCT agent_username) as active_agents,
  SUM((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) as total_minutes,
  SUM(cost_per_call) as total_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  AVG((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) as avg_duration_minutes
FROM cost_per_call_analysis
GROUP BY 
  account_id, 
  account_name, 
  DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))
ORDER BY call_date DESC, account_id;

-- 4. Executive summary - monthly rollup
CREATE OR REPLACE VIEW executive_monthly_summary AS
SELECT 
  account_id,
  account_name,
  DATE_TRUNC('month', DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as month_year,
  COUNT(*) as total_calls,
  COUNT(DISTINCT agent_username) as unique_agents,
  COUNT(DISTINCT queue_name) as active_queues,
  SUM(cost_per_call) as monthly_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  SUM((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) as total_minutes
FROM cost_per_call_analysis
GROUP BY 
  account_id, 
  account_name, 
  DATE_TRUNC('month', DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000)))
ORDER BY month_year DESC, account_id;

-- 5. Agent performance across accounts
CREATE OR REPLACE VIEW agent_performance_multi_account AS
SELECT 
  account_id,
  account_name,
  agent_username,
  COUNT(*) as total_contacts,
  AVG((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) as avg_interaction_time,
  SUM(cost_per_call) as total_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  COUNT(DISTINCT queue_name) as queues_handled,
  MIN(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as first_contact_date,
  MAX(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as last_contact_date
FROM cost_per_call_analysis
GROUP BY account_id, account_name, agent_username
HAVING COUNT(*) >= 5  -- Only agents with 5+ contacts
ORDER BY total_contacts DESC;

-- 6. Queue performance by account
CREATE OR REPLACE VIEW queue_performance_multi_account AS
SELECT 
  account_id,
  account_name,
  queue_name,
  COUNT(*) as total_contacts,
  COUNT(DISTINCT agent_username) as agents_assigned,
  AVG((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) as avg_handle_time,
  SUM(cost_per_call) as queue_total_cost,
  AVG(cost_per_call) as avg_cost_per_contact
FROM cost_per_call_analysis
GROUP BY account_id, account_name, queue_name
ORDER BY total_contacts DESC;

-- 7. Hourly volume analysis
CREATE OR REPLACE VIEW hourly_volume_analysis AS
SELECT 
  account_id,
  account_name,
  EXTRACT(hour FROM from_unixtime(CAST(initiation_timestamp AS bigint) / 1000)) as call_hour,
  DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000)) as call_date,
  COUNT(*) as contact_count,
  AVG((CAST(disconnect_timestamp AS bigint) - CAST(initiation_timestamp AS bigint)) / 1000.0 / 60.0) as avg_duration,
  SUM(cost_per_call) as hourly_cost
FROM cost_per_call_analysis
GROUP BY 
  account_id, 
  account_name, 
  EXTRACT(hour FROM from_unixtime(CAST(initiation_timestamp AS bigint) / 1000)),
  DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))
ORDER BY call_date DESC, call_hour;

-- 8. Cross-account comparison summary
CREATE OR REPLACE VIEW cross_account_comparison AS
SELECT 
  'All Accounts' as comparison_type,
  COUNT(*) as total_calls,
  COUNT(DISTINCT account_id) as active_accounts,
  COUNT(DISTINCT agent_username) as total_agents,
  SUM(cost_per_call) as total_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  MIN(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as earliest_call,
  MAX(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as latest_call
FROM cost_per_call_analysis

UNION ALL

SELECT 
  account_name as comparison_type,
  COUNT(*) as total_calls,
  1 as active_accounts,
  COUNT(DISTINCT agent_username) as total_agents,
  SUM(cost_per_call) as total_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  MIN(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as earliest_call,
  MAX(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as latest_call
FROM cost_per_call_analysis
GROUP BY account_name, account_id
ORDER BY comparison_type;

-- Sample queries for testing and validation

-- Test 1: Verify multi-account data
SELECT account_id, account_name, COUNT(*) as record_count
FROM multi_account_contacts 
GROUP BY account_id, account_name;

-- Test 2: Check cost calculations
SELECT 
  account_name,
  COUNT(*) as calls,
  ROUND(AVG(cost_per_call), 4) as avg_cost,
  ROUND(SUM(cost_per_call), 2) as total_cost
FROM cost_per_call_analysis 
GROUP BY account_name;

-- Test 3: Validate date ranges
SELECT 
  MIN(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as earliest_date,
  MAX(DATE(from_unixtime(CAST(initiation_timestamp AS bigint) / 1000))) as latest_date,
  COUNT(*) as total_records
FROM multi_account_contacts;