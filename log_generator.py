#!/usr/bin/env python3

import json
import socket
import time
import random
from datetime import datetime


LOGSTASH_HOST = 'localhost'
LOGSTASH_PORT = 5000


LOG_LEVELS = ['INFO', 'WARNING', 'ERROR', 'DEBUG', 'CRITICAL']
APPLICATIONS = ['web-api', 'auth-service', 'payment-processor', 'user-service', 'notification-service']
LOG_MESSAGES = {
    'INFO': [
        'User login successful',
        'Database connection established',
        'API request processed successfully',
        'Cache hit for user data',
        'Email notification sent',
        'File upload completed',
        'Session created',
        'Configuration reloaded',
        'Background job completed',
        'Health check passed'
    ],
    'WARNING': [
        'High memory usage detected',
        'API response time exceeded threshold',
        'Cache miss - fetching from database',
        'Rate limit approaching',
        'Database connection pool running low',
        'Deprecated API endpoint called',
        'SSL certificate expires soon',
        'Disk space below 20%',
        'Slow query detected',
        'Retry attempt for failed operation'
    ],
    'ERROR': [
        'Failed to connect to database',
        'Authentication failed',
        'Payment processing failed',
        'API request timeout',
        'File upload failed',
        'Invalid input validation',
        'External service unavailable',
        'Session expired',
        'Permission denied',
        'Data serialization error'
    ],
    'DEBUG': [
        'Entering function: processUserRequest',
        'Query execution time: 45ms',
        'Cache key generated',
        'Request headers parsed',
        'Middleware chain executed',
        'Database query prepared',
        'Response serialized',
        'Session data retrieved',
        'Configuration value loaded',
        'Event published to queue'
    ],
    'CRITICAL': [
        'Database server unreachable',
        'System out of memory',
        'Critical security vulnerability detected',
        'Data corruption detected',
        'Cluster node failure',
        'Emergency shutdown initiated',
        'Multiple service failures',
        'Unhandled exception in core module',
        'Authentication system failure',
        'Data center network failure'
    ]
}

ERROR_CODES = ['E001', 'E002', 'E003', 'E404', 'E500', 'E503', 'E401', 'E403']
HTTP_METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
ENDPOINTS = ['/api/users', '/api/orders', '/api/products', '/api/auth/login', '/api/payments']


def send_log(sock, log_entry):

    try:
        log_json = json.dumps(log_entry) + '\n'
        sock.sendall(log_json.encode('utf-8'))
        

        color_map = {
            'INFO': '\033[92m',      # Green
            'WARNING': '\033[93m',   # Yellow
            'ERROR': '\033[91m',     # Red
            'DEBUG': '\033[94m',     # Blue
            'CRITICAL': '\033[95m'   # Magenta
        }
        color = color_map.get(log_entry['level'], '\033[0m')
        reset = '\033[0m'
        
        print(f"{color}[{log_entry['timestamp']}] {log_entry['level']:8} | {log_entry['application']:20} | {log_entry['message']}{reset}")
        
    except Exception as e:
        print(f"Error sending log: {e}")


def generate_log_entry(counter):

    level = random.choices(
        LOG_LEVELS,
        weights=[50, 20, 15, 10, 5],
        k=1
    )[0]
    
    application = random.choice(APPLICATIONS)
    message = random.choice(LOG_MESSAGES[level])
    
    log_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'level': level,
        'message': message,
        'application': application,
        'environment': 'production',
        'host': socket.gethostname(),
        'request_id': f'req-{counter:08d}',
        'user_id': random.randint(1000, 9999),
        'response_time_ms': random.randint(10, 500)
    }
    

    if application in ['web-api', 'auth-service']:
        log_entry['http_method'] = random.choice(HTTP_METHODS)
        log_entry['endpoint'] = random.choice(ENDPOINTS)
        log_entry['status_code'] = 200 if level == 'INFO' else random.choice([400, 401, 403, 404, 500, 503])
    

    if level in ['ERROR', 'CRITICAL']:
        log_entry['error_code'] = random.choice(ERROR_CODES)
        log_entry['stack_trace'] = f"at module.function (file.py:{random.randint(10, 999)})"
    

    if application == 'payment-processor':
        log_entry['transaction_id'] = f'txn-{random.randint(100000, 999999)}'
        log_entry['amount'] = round(random.uniform(10.0, 1000.0), 2)
    
    return log_entry


def main():

    print("=" * 80)
    print(" Log Generator for Elasticsearch Stack")
    print("=" * 80)
    print(f"Target: {LOGSTASH_HOST}:{LOGSTASH_PORT}")
    print("Press Ctrl+C to stop\n")
    
    counter = 0
    
    while True:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.connect((LOGSTASH_HOST, LOGSTASH_PORT))
                print(f" Connected to Logstash at {LOGSTASH_HOST}:{LOGSTASH_PORT}\n")
                
                while True:
                    log_entry = generate_log_entry(counter)
                    send_log(sock, log_entry)
                    counter += 1
                    

                    delay = random.choices(
                        [1, 2, 3, 5],
                        weights=[50, 30, 15, 5],
                        k=1
                    )[0]
                    time.sleep(delay)
                    
        except ConnectionRefusedError:
            print(f"\n Connection refused. Is Logstash running at {LOGSTASH_HOST}:{LOGSTASH_PORT}?")
            print("Retrying in 5 seconds...")
            time.sleep(5)
        except KeyboardInterrupt:
            print("\n\n Stopping log generator...")
            print(f"Total logs sent: {counter}")
            break
        except Exception as e:
            print(f"\n Error: {e}")
            print("Retrying in 5 seconds...")
            time.sleep(5)


if __name__ == '__main__':
    main()
