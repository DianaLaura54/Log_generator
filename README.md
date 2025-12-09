# Grafana + Elasticsearch Logging Stack

A complete logging and monitoring solution that collects, processes, stores, and visualizes application logs in real-time.

## What It Does

This project provides a full logging stack that helps you monitor your applications. It collects logs from your apps, processes them through Logstash, stores them in Elasticsearch, and visualizes everything in beautiful Grafana dashboards. Think of it as having X-ray vision into your applications to see what's happening in real-time.

## Technologies

The stack is built with **Elasticsearch 8.11.0** for storing and searching logs, **Logstash 8.11.0** for processing incoming log data, and **Grafana (latest)** for creating dashboards and visualizations. Everything runs in Docker containers orchestrated by Docker Compose. The log generator is written in Python, configuration is done in YAML, and dashboards are defined in JSON.

## Quick Start

Start the stack with `docker-compose up -d` and wait 60 seconds for all services to initialize. Open Grafana at http://localhost:3000 (login: admin/admin123), import the sample dashboard from `sample-dashboard.json`, and run `python log_generator.py` to see live logs flowing through the system.
