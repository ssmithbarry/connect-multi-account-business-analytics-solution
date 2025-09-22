#!/usr/bin/env python3
"""
Pearson Connect Analytics - Demo Data Generator

Creates realistic dummy data for visualization without interfering with Connect Data Lake.
Uses a separate 'demo_contact_records' table alongside the real 'contact_records' table.
"""

import boto3
import json
import random
from datetime import datetime, timedelta
from faker import Faker
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from io import BytesIO

# Configuration
DEMO_CONFIG = {
    'database_name': 'connect_data_lake',
    'demo_table_name': 'demo_contact_records',
    's3_bucket_prefix': 'connect-demo-data',
    'days_of_data': 30,
    'calls_per_day': 150,
    'accounts': {
        'production': {
            'account_id': '111111111111',
            'cost_per_minute': 0.025,
            'agents': ['alice.johnson', 'bob.smith', 'carol.davis', 'david.wilson', 'emma.brown'],
            'queues': ['Sales', 'Support', 'Billing', 'Technical']
        },
        'development': {
            'account_id': '222222222222', 
            'cost_per_minute': 0.020,
            'agents': ['frank.miller', 'grace.taylor', 'henry.clark', 'iris.white'],
            'queues': ['Dev-Support', 'Testing', 'QA']
        },
        'test': {
            'account_id': '333333333333',
            'cost_per_minute': 0.015,
            'agents': ['jack.green', 'kate.adams', 'liam.scott'],
            'queues': ['Test-Queue', 'Demo-Queue']
        }
    }
}

class ConnectDemoDataGenerator:
    def __init__(self):
        self.fake = Faker()
        self.s3 = boto3.client('s3')
        self.athena = boto3.client('athena')
        self.glue = boto3.client('glue')
        
    def generate_contact_record(self, account_name, account_config, call_date):
        """Generate a single realistic contact record"""
        
        # Random call timing
        start_time = call_date + timedelta(
            hours=random.randint(8, 18),
            minutes=random.randint(0, 59),
            seconds=random.randint(0, 59)
        )
        
        # Call duration (30 seconds to 20 minutes)
        duration_seconds = random.randint(30, 1200)
        end_time = start_time + timedelta(seconds=duration_seconds)
        
        # Random selections
        agent = random.choice(account_config['agents'])
        queue = random.choice(account_config['queues'])
        channel = random.choice(['VOICE', 'CHAT', 'TASK'])
        
        # Disconnect reasons with realistic distribution
        disconnect_reasons = [
            ('CUSTOMER_DISCONNECT', 0.6),
            ('AGENT_DISCONNECT', 0.25),
            ('SYSTEM_DISCONNECT', 0.1),
            ('THIRD_PARTY_DISCONNECT', 0.05)
        ]
        disconnect_reason = random.choices(
            [r[0] for r in disconnect_reasons],
            weights=[r[1] for r in disconnect_reasons]
        )[0]
        
        return {
            'contact_id': f"arn:aws:connect:{random.choice(['us-east-1', 'us-west-2'])}:{account_config['account_id']}:instance/{self.fake.uuid4()}/contact/{self.fake.uuid4()}",
            'aws_account_id': account_config['account_id'],
            'initiation_timestamp': start_time.isoformat() + 'Z',
            'disconnect_timestamp': end_time.isoformat() + 'Z',
            'channel': channel,
            'queue_name': queue,
            'agent_username': agent,
            'disconnect_reason': disconnect_reason,
            'initiation_method': random.choice(['INBOUND', 'OUTBOUND', 'TRANSFER', 'CALLBACK']),
            'instance_arn': f"arn:aws:connect:us-east-1:{account_config['account_id']}:instance/{self.fake.uuid4()}"
        }
    
    def generate_demo_data(self):
        """Generate complete demo dataset"""
        print("🎲 Generating demo contact records...")
        
        records = []
        end_date = datetime.now()
        
        for day in range(DEMO_CONFIG['days_of_data']):
            call_date = end_date - timedelta(days=day)
            
            for account_name, account_config in DEMO_CONFIG['accounts'].items():
                # Vary daily call volume (80-120% of target)
                daily_calls = int(DEMO_CONFIG['calls_per_day'] * random.uniform(0.8, 1.2))
                
                for _ in range(daily_calls):
                    record = self.generate_contact_record(account_name, account_config, call_date)
                    records.append(record)
        
        print(f"   Generated {len(records)} contact records across {DEMO_CONFIG['days_of_data']} days")
        return records
    
    def upload_to_s3(self, records):
        """Upload demo data to S3 in Parquet format"""
        print("📤 Uploading demo data to S3...")
        
        # Convert to DataFrame
        df = pd.DataFrame(records)
        
        # Convert timestamps to proper datetime
        df['initiation_timestamp'] = pd.to_datetime(df['initiation_timestamp'])
        df['disconnect_timestamp'] = pd.to_datetime(df['disconnect_timestamp'])
        
        # Create S3 bucket for demo data
        account_id = boto3.client('sts').get_caller_identity()['Account']
        bucket_name = f"{DEMO_CONFIG['s3_bucket_prefix']}-{account_id}"
        
        try:
            self.s3.create_bucket(Bucket=bucket_name)
            print(f"   Created S3 bucket: {bucket_name}")
        except self.s3.exceptions.BucketAlreadyOwnedByYou:
            print(f"   Using existing S3 bucket: {bucket_name}")
        
        # Convert to Parquet and upload
        table = pa.Table.from_pandas(df)
        parquet_buffer = BytesIO()
        pq.write_table(table, parquet_buffer)
        
        s3_key = f"demo-data/contact_records/demo_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.parquet"
        
        self.s3.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=parquet_buffer.getvalue(),
            ContentType='application/octet-stream'
        )
        
        print(f"   Uploaded to s3://{bucket_name}/{s3_key}")
        return bucket_name, s3_key
    
    def create_demo_table(self, bucket_name):
        """Create Glue table for demo data"""
        print("🗃️  Creating demo table in Glue catalog...")
        
        try:
            self.glue.create_table(
                DatabaseName=DEMO_CONFIG['database_name'],
                TableInput={
                    'Name': DEMO_CONFIG['demo_table_name'],
                    'Description': 'Demo contact records for visualization (does not interfere with real Connect data)',
                    'StorageDescriptor': {
                        'Columns': [
                            {'Name': 'contact_id', 'Type': 'string'},
                            {'Name': 'aws_account_id', 'Type': 'string'},
                            {'Name': 'initiation_timestamp', 'Type': 'timestamp'},
                            {'Name': 'disconnect_timestamp', 'Type': 'timestamp'},
                            {'Name': 'channel', 'Type': 'string'},
                            {'Name': 'queue_name', 'Type': 'string'},
                            {'Name': 'agent_username', 'Type': 'string'},
                            {'Name': 'disconnect_reason', 'Type': 'string'},
                            {'Name': 'initiation_method', 'Type': 'string'},
                            {'Name': 'instance_arn', 'Type': 'string'}
                        ],
                        'Location': f's3://{bucket_name}/demo-data/contact_records/',
                        'InputFormat': 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat',
                        'OutputFormat': 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat',
                        'SerdeInfo': {
                            'SerializationLibrary': 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
                        }
                    },
                    'TableType': 'EXTERNAL_TABLE'
                }
            )
            print(f"   Created table: {DEMO_CONFIG['database_name']}.{DEMO_CONFIG['demo_table_name']}")
        except self.glue.exceptions.AlreadyExistsException:
            print(f"   Table already exists: {DEMO_CONFIG['database_name']}.{DEMO_CONFIG['demo_table_name']}")
    
    def create_demo_views(self):
        """Create Athena views for demo data"""
        print("📊 Creating demo-specific Athena views...")
        
        # Demo cost analysis view
        demo_cost_view = f"""
        CREATE OR REPLACE VIEW {DEMO_CONFIG['database_name']}.demo_cost_analysis AS
        SELECT 
          contact_id,
          aws_account_id,
          CASE 
            WHEN aws_account_id = '111111111111' THEN 'production'
            WHEN aws_account_id = '222222222222' THEN 'development'
            WHEN aws_account_id = '333333333333' THEN 'test'
            ELSE 'unknown'
          END as account_name,
          CASE 
            WHEN aws_account_id = '111111111111' THEN 0.025
            WHEN aws_account_id = '222222222222' THEN 0.020
            WHEN aws_account_id = '333333333333' THEN 0.015
            ELSE 0.02
          END as cost_per_minute,
          DATE(initiation_timestamp) as call_date,
          channel,
          queue_name,
          agent_username,
          disconnect_reason,
          date_diff('millisecond', initiation_timestamp, disconnect_timestamp) / 60000.0 as call_duration_minutes,
          (date_diff('millisecond', initiation_timestamp, disconnect_timestamp) / 60000.0) * 
          CASE 
            WHEN aws_account_id = '111111111111' THEN 0.025
            WHEN aws_account_id = '222222222222' THEN 0.020
            WHEN aws_account_id = '333333333333' THEN 0.015
            ELSE 0.02
          END as total_cost,
          initiation_timestamp,
          disconnect_timestamp
        FROM {DEMO_CONFIG['database_name']}.{DEMO_CONFIG['demo_table_name']}
        WHERE initiation_timestamp >= current_date - interval '30' day
        """
        
        self.run_athena_query(demo_cost_view, "Creating demo cost analysis view")
        
        # Demo executive summary view
        demo_exec_view = f"""
        CREATE OR REPLACE VIEW {DEMO_CONFIG['database_name']}.demo_executive_summary AS
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
          ROUND(SUM(CASE WHEN disconnect_reason = 'CUSTOMER_DISCONNECT' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as customer_disconnect_rate,
          ROUND(SUM(CASE WHEN disconnect_reason = 'AGENT_DISCONNECT' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as agent_disconnect_rate
        FROM {DEMO_CONFIG['database_name']}.demo_cost_analysis
        GROUP BY account_name, aws_account_id, date_trunc('month', call_date)
        ORDER BY month_year DESC, monthly_cost DESC
        """
        
        self.run_athena_query(demo_exec_view, "Creating demo executive summary view")
    
    def run_athena_query(self, query, description):
        """Execute Athena query"""
        try:
            response = self.athena.start_query_execution(
                QueryString=query,
                ResultConfiguration={
                    'OutputLocation': f's3://aws-athena-query-results-{boto3.client("sts").get_caller_identity()["Account"]}-{boto3.Session().region_name}/'
                }
            )
            print(f"   ✅ {description}")
        except Exception as e:
            print(f"   ⚠️  {description} - {str(e)}")
    
    def generate_and_deploy(self):
        """Main method to generate and deploy demo data"""
        print("🚀 Pearson Connect Analytics - Demo Data Generator")
        print("=" * 55)
        
        # Generate data
        records = self.generate_demo_data()
        
        # Upload to S3
        bucket_name, s3_key = self.upload_to_s3(records)
        
        # Create table
        self.create_demo_table(bucket_name)
        
        # Create views
        self.create_demo_views()
        
        print("\n✅ Demo data generation complete!")
        print(f"📊 Generated {len(records)} contact records")
        print(f"🗃️  Table: {DEMO_CONFIG['database_name']}.{DEMO_CONFIG['demo_table_name']}")
        print(f"📈 Views: demo_cost_analysis, demo_executive_summary")
        
        print("\n🎯 Next Steps:")
        print("1. Update your Terraform QuickSight dataset to use 'demo_contact_records' table")
        print("2. Or create a new dataset pointing to the demo views")
        print("3. Refresh QuickSight datasets to see the demo data")
        print("4. The demo data won't interfere with real Connect Data Lake")

if __name__ == "__main__":
    try:
        generator = ConnectDemoDataGenerator()
        generator.generate_and_deploy()
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        print("Make sure you have AWS credentials configured and required permissions.")