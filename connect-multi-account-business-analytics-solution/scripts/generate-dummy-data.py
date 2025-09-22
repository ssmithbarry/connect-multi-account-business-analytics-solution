#!/usr/bin/env python3
"""
Generate dummy Connect contact records for demo purposes
Creates CSV files that can be uploaded to S3 and queried via Athena
"""

import csv
import random
from datetime import datetime, timedelta
import uuid

# Account configurations
ACCOUNTS = {
    '111111111111': {'name': 'Production', 'daily_calls': 500},
    '222222222222': {'name': 'Development', 'daily_calls': 200}, 
    '333333333333': {'name': 'Test', 'daily_calls': 100}
}

def generate_contact_record(account_id, call_date):
    """Generate a single contact record"""
    
    # Random call duration (30 seconds to 20 minutes)
    duration_seconds = random.randint(30, 1200)
    
    # Random start time during business hours
    start_hour = random.randint(8, 17)
    start_minute = random.randint(0, 59)
    start_second = random.randint(0, 59)
    
    initiation_time = call_date.replace(hour=start_hour, minute=start_minute, second=start_second)
    disconnect_time = initiation_time + timedelta(seconds=duration_seconds)
    
    # Convert to Unix timestamps (milliseconds)
    initiation_timestamp = int(initiation_time.timestamp() * 1000)
    disconnect_timestamp = int(disconnect_time.timestamp() * 1000)
    
    return {
        'account_id': account_id,
        'contact_id': str(uuid.uuid4()),
        'initiation_timestamp': initiation_timestamp,
        'disconnect_timestamp': disconnect_timestamp,
        'initiation_method': random.choice(['INBOUND', 'OUTBOUND', 'TRANSFER']),
        'channel': 'VOICE',
        'queue_name': random.choice(['CustomerService', 'TechnicalSupport', 'Sales', 'Billing']),
        'agent_username': f"agent_{random.randint(1, 50):03d}",
        'customer_endpoint_type': 'TELEPHONE_NUMBER'
    }

def generate_dummy_data():
    """Generate dummy data for all accounts over the last 30 days"""
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)
    
    all_records = []
    
    for account_id, config in ACCOUNTS.items():
        print(f"Generating data for {config['name']} account ({account_id})...")
        
        current_date = start_date
        while current_date <= end_date:
            # Generate random number of calls for this day
            daily_calls = random.randint(
                int(config['daily_calls'] * 0.7), 
                int(config['daily_calls'] * 1.3)
            )
            
            for _ in range(daily_calls):
                record = generate_contact_record(account_id, current_date)
                all_records.append(record)
            
            current_date += timedelta(days=1)
    
    # Write to CSV file
    filename = f"dummy_contact_records_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = [
            'account_id', 'contact_id', 'initiation_timestamp', 'disconnect_timestamp',
            'initiation_method', 'channel', 'queue_name', 'agent_username', 'customer_endpoint_type'
        ]
        
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_records)
    
    print(f"Generated {len(all_records)} dummy records in {filename}")
    print(f"Upload this file to S3 and create an external table to query it")
    
    return filename

if __name__ == "__main__":
    generate_dummy_data()