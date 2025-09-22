-- Operational Dashboard Queries for Pearson Connect Analytics

-- 1. Contact Records View (Full Schema)
CREATE OR REPLACE VIEW contact_record_operational AS
SELECT
  instance_id,
  aws_account_id,
  contact_id,
  initial_contact_id,
  channel,
  initiation_method,
  date_parse(CAST(initiation_timestamp AS varchar), '%Y-%m-%d %H:%i:%s.%f UTC') initiation_timestamp,
  date_parse(CAST(disconnect_timestamp AS varchar), '%Y-%m-%d %H:%i:%s.%f UTC') disconnect_timestamp,
  disconnect_reason,
  queue_duration_ms,
  queue_name,
  queue_id,
  agent_connection_attempts,
  date_parse(CAST(agent_connected_to_agent_timestamp AS varchar), '%Y-%m-%d %H:%i:%s.%f UTC') agent_connected_to_agent_timestamp,
  agent_interaction_duration_ms,
  agent_customer_hold_duration_ms,
  agent_number_of_holds,
  agent_after_contact_work_duration_ms,
  agent_username,
  agent_id,
  agent_routing_profile_name,
  customer_endpoint_address,
  system_endpoint_address,
  recording_status,
  -- Calculated fields
  ((CAST(queue_duration_ms AS decimal(20, 6)) / 1000) / 60) queue_duration_min,
  ((CAST(agent_interaction_duration_ms AS decimal(20, 6)) / 1000) / 60) agent_interaction_duration_min,
  ((CAST(agent_after_contact_work_duration_ms AS decimal(20, 6)) / 1000) / 60) agent_after_contact_work_duration_min,
  date_diff('millisecond', initiation_timestamp, disconnect_timestamp) total_duration_ms,
  ((CAST(date_diff('millisecond', initiation_timestamp, disconnect_timestamp) AS decimal(20, 6)) / 1000) / 60) total_duration_min,
  -- Instance-specific cost calculation
  ((CAST(date_diff('millisecond', initiation_timestamp, disconnect_timestamp) AS decimal(20, 6)) / 1000) / 60) * 
  CASE 
    WHEN instance_id LIKE '%prod%' THEN 0.022  -- Production instance rate
    WHEN instance_id LIKE '%dev%' THEN 0.015   -- Development instance rate
    WHEN aws_account_id = '111111111111' THEN 0.020  -- Account-specific rate
    WHEN aws_account_id = '222222222222' THEN 0.018  -- Account-specific rate
    ELSE 0.018  -- Default rate
  END AS cost_per_call,
  -- Add instance metadata for cost tracking
  instance_id as connect_instance,
  aws_account_id as billing_account
FROM contact_record;

-- 2. Agent Performance Metrics
CREATE OR REPLACE VIEW agent_performance_metrics AS
SELECT
  agent_username,
  aws_account_id,
  COUNT(DISTINCT contact_id) as total_contacts,
  AVG(agent_interaction_duration_min) as avg_interaction_time,
  AVG(agent_after_contact_work_duration_min) as avg_after_work_time,
  AVG(agent_number_of_holds) as avg_holds_per_call,
  AVG(total_duration_min) as avg_total_duration,
  SUM(cost_per_call) as total_cost,
  AVG(cost_per_call) as avg_cost_per_call
FROM contact_record_operational
WHERE agent_username IS NOT NULL
GROUP BY agent_username, aws_account_id;

-- 3. Queue Performance Analysis
CREATE OR REPLACE VIEW queue_performance_metrics AS
SELECT
  queue_name,
  aws_account_id,
  COUNT(DISTINCT contact_id) as total_contacts,
  AVG(queue_duration_min) as avg_queue_time,
  AVG(total_duration_min) as avg_total_duration,
  COUNT(CASE WHEN disconnect_reason = 'CUSTOMER_DISCONNECT' THEN 1 END) as customer_disconnects,
  COUNT(CASE WHEN disconnect_reason = 'AGENT_DISCONNECT' THEN 1 END) as agent_disconnects,
  SUM(cost_per_call) as total_queue_cost,
  AVG(cost_per_call) as avg_cost_per_call
FROM contact_record_operational
WHERE queue_name IS NOT NULL
GROUP BY queue_name, aws_account_id;

-- 4. Multi-Account Executive Summary
CREATE OR REPLACE VIEW executive_summary AS
SELECT
  aws_account_id,
  DATE(initiation_timestamp) as call_date,
  COUNT(DISTINCT contact_id) as total_contacts,
  COUNT(DISTINCT agent_username) as active_agents,
  COUNT(DISTINCT queue_name) as active_queues,
  AVG(total_duration_min) as avg_call_duration,
  AVG(queue_duration_min) as avg_queue_time,
  SUM(cost_per_call) as daily_cost,
  AVG(cost_per_call) as avg_cost_per_call,
  -- Channel breakdown
  COUNT(CASE WHEN channel = 'VOICE' THEN 1 END) as voice_calls,
  COUNT(CASE WHEN channel = 'CHAT' THEN 1 END) as chat_contacts
FROM contact_record_operational
GROUP BY aws_account_id, DATE(initiation_timestamp);

-- 5. Real-time Operational Dashboard
CREATE OR REPLACE VIEW operational_dashboard AS
SELECT
  -- Time dimensions
  DATE(initiation_timestamp) as call_date,
  HOUR(initiation_timestamp) as call_hour,
  -- Account and service breakdown
  aws_account_id,
  channel,
  queue_name,
  agent_username,
  -- Volume metrics
  COUNT(DISTINCT contact_id) as contact_count,
  -- Performance metrics
  AVG(total_duration_min) as avg_duration,
  AVG(queue_duration_min) as avg_queue_time,
  AVG(agent_interaction_duration_min) as avg_talk_time,
  -- Cost metrics
  SUM(cost_per_call) as total_cost,
  AVG(cost_per_call) as avg_cost,
  -- Quality metrics
  COUNT(CASE WHEN disconnect_reason = 'CUSTOMER_DISCONNECT' THEN 1 END) as customer_hangups,
  AVG(agent_number_of_holds) as avg_holds
FROM contact_record_operational
WHERE initiation_timestamp >= current_date - interval '7' day
GROUP BY 
  DATE(initiation_timestamp),
  HOUR(initiation_timestamp),
  aws_account_id,
  channel,
  queue_name,
  agent_username;

-- 6. Contact Lens Sentiment Analysis (if available)
CREATE OR REPLACE VIEW sentiment_analysis AS
SELECT
  cr.aws_account_id,
  cr.contact_id,
  cr.agent_username,
  cr.queue_name,
  DATE(cr.initiation_timestamp) as call_date,
  cl.sentiment_overall_score_customer,
  cl.sentiment_overall_score_agent,
  cl.total_conversation_duration_ms / 60000.0 as conversation_duration_min,
  cr.cost_per_call
FROM contact_record_operational cr
LEFT JOIN contact_lens_conversational_analytics cl
  ON cr.contact_id = cl.contact_id
WHERE cl.sentiment_overall_score_customer IS NOT NULL;