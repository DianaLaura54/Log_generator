.PHONY: help start stop restart logs status clean logs-all


COLOR_RESET=\033[0m
COLOR_BOLD=\033[1m
COLOR_GREEN=\033[32m
COLOR_YELLOW=\033[33m
COLOR_BLUE=\033[34m
COLOR_RED=\033[31m

help:
	@echo ""
	@echo "$(COLOR_BOLD)Grafana + Elasticsearch Stack Management$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Available commands:$(COLOR_RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_BLUE)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ""

start:
	@echo "$(COLOR_GREEN)Starting Grafana + Elasticsearch stack...$(COLOR_RESET)"
	@docker-compose up -d
	@echo ""
	@echo "$(COLOR_YELLOW)Waiting for services to be ready...$(COLOR_RESET)"
	@sleep 5
	@echo ""
	@$(MAKE) status
	@echo ""
	@echo "$(COLOR_GREEN) Stack is running!$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)Access Points:$(COLOR_RESET)"
	@echo "   Grafana:        http://localhost:3000 (admin/admin123)"
	@echo "   Elasticsearch:  http://localhost:9200"
	@echo "  Logstash:       tcp://localhost:5000"
	@echo "   Sample App:     http://localhost:8080"
	@echo ""

stop:
	@echo "$(COLOR_YELLOW)Stopping all services...$(COLOR_RESET)"
	@docker-compose stop
	@echo "$(COLOR_GREEN) Services stopped$(COLOR_RESET)"

restart:
	@echo "$(COLOR_YELLOW)Restarting all services...$(COLOR_RESET)"
	@docker-compose restart
	@sleep 5
	@$(MAKE) status

down:
	@echo "$(COLOR_YELLOW)Stopping and removing containers...$(COLOR_RESET)"
	@docker-compose down
	@echo "$(COLOR_GREEN) Containers removed$(COLOR_RESET)"

clean:
	@echo "$(COLOR_RED)  WARNING: This will delete all data!$(COLOR_RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "$(COLOR_GREEN) All data cleaned up$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Cancelled$(COLOR_RESET)"; \
	fi

status:
	@echo "$(COLOR_BOLD)Service Status:$(COLOR_RESET)"
	@docker-compose ps
	@echo ""
	@echo "$(COLOR_BOLD)Health Checks:$(COLOR_RESET)"
	@printf "  Elasticsearch: "
	@if curl -sf http://localhost:9200/_cluster/health > /dev/null 2>&1; then \
		echo "$(COLOR_GREEN) Healthy$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED) Unhealthy$(COLOR_RESET)"; \
	fi
	@printf "  Grafana:       "
	@if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then \
		echo "$(COLOR_GREEN) Healthy$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED) Unhealthy$(COLOR_RESET)"; \
	fi
	@printf "  Logstash:      "
	@if nc -z localhost 5000 2>/dev/null; then \
		echo "$(COLOR_GREEN) Listening$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_RED) Not listening$(COLOR_RESET)"; \
	fi

logs:
	@docker-compose logs -f

logs-all:
	@docker-compose logs

logs-es:
	@docker-compose logs -f elasticsearch

logs-logstash:
	@docker-compose logs -f logstash

logs-grafana:
	@docker-compose logs -f grafana

generate-logs:
	@echo "$(COLOR_GREEN)Starting log generator...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Press Ctrl+C to stop$(COLOR_RESET)"
	@echo ""
	@python3 log_generator.py

test-log:
	@echo '{"message":"Test log from Makefile","level":"INFO","application":"makefile-test","timestamp":"'$$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' | nc localhost 5000
	@echo "$(COLOR_GREEN) Test log sent!$(COLOR_RESET)"

indices:
	@echo "$(COLOR_BOLD)Elasticsearch Indices:$(COLOR_RESET)"
	@curl -s http://localhost:9200/_cat/indices?v

count-logs:
	@echo "$(COLOR_BOLD)Log Count by Level:$(COLOR_RESET)"
	@curl -s -X GET "http://localhost:9200/logstash-*/_search?pretty" \
		-H 'Content-Type: application/json' \
		-d '{"size": 0, "aggs": {"by_level": {"terms": {"field": "level.keyword", "size": 10}}}}' \
		| grep -A 30 '"aggregations"' || echo "No data yet"

query-logs:
	@echo "$(COLOR_BOLD)Recent Logs (last 5):$(COLOR_RESET)"
	@curl -s -X GET "http://localhost:9200/logstash-*/_search?pretty" \
		-H 'Content-Type: application/json' \
		-d '{"query": {"match_all": {}}, "size": 5, "sort": [{"@timestamp": {"order": "desc"}}]}' \
		| grep -A 50 '"hits"' || echo "No data yet"

search-errors:
	@echo "$(COLOR_BOLD)Recent ERROR Logs:$(COLOR_RESET)"
	@curl -s -X GET "http://localhost:9200/logstash-*/_search?pretty" \
		-H 'Content-Type: application/json' \
		-d '{"query": {"match": {"level": "ERROR"}}, "size": 5, "sort": [{"@timestamp": {"order": "desc"}}]}' \
		| grep -A 50 '"hits"' || echo "No errors found"

cluster-health:
	@echo "$(COLOR_BOLD)Elasticsearch Cluster Health:$(COLOR_RESET)"
	@curl -s http://localhost:9200/_cluster/health?pretty

stats:
	@echo "$(COLOR_BOLD)Elasticsearch Node Stats:$(COLOR_RESET)"
	@curl -s http://localhost:9200/_stats?pretty | head -50

dashboard-info:
	@echo ""
	@echo "$(COLOR_BOLD) Dashboard Import Instructions:$(COLOR_RESET)"
	@echo ""
	@echo "1. Open Grafana: $(COLOR_BLUE)http://localhost:3000$(COLOR_RESET)"
	@echo "2. Login with: $(COLOR_GREEN)admin / admin123$(COLOR_RESET)"
	@echo "3. Go to: $(COLOR_YELLOW)Dashboards → Import$(COLOR_RESET)"
	@echo "4. Upload file: $(COLOR_YELLOW)sample-dashboard.json$(COLOR_RESET)"
	@echo "5. Select datasource: $(COLOR_YELLOW)Elasticsearch$(COLOR_RESET)"
	@echo "6. Click $(COLOR_GREEN)Import$(COLOR_RESET)"
	@echo ""

open-grafana:
	@echo "$(COLOR_GREEN)Opening Grafana...$(COLOR_RESET)"
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:3000; \
	elif command -v open > /dev/null; then \
		open http://localhost:3000; \
	else \
		echo "Please open: http://localhost:3000"; \
	fi

backup:
	@echo "$(COLOR_YELLOW)Creating backup...$(COLOR_RESET)"
	@docker-compose exec -T elasticsearch \
		curl -X PUT "localhost:9200/_snapshot/backup" \
		-H 'Content-Type: application/json' \
		-d '{"type":"fs","settings":{"location":"/usr/share/elasticsearch/backup"}}'
	@echo "$(COLOR_GREEN) Backup configured$(COLOR_RESET)"

ps:
	@docker-compose ps

top:
	@docker stats --no-stream

shell-es:
	@docker-compose exec elasticsearch bash

shell-logstash:
	@docker-compose exec logstash bash

shell-grafana:
	@docker-compose exec grafana bash

install:
	@$(MAKE) start

update:
	@echo "$(COLOR_YELLOW)Pulling latest images...$(COLOR_RESET)"
	@docker-compose pull
	@echo "$(COLOR_GREEN) Images updated$(COLOR_RESET)"

rebuild:
	@echo "$(COLOR_YELLOW)Rebuilding services...$(COLOR_RESET)"
	@docker-compose up -d --build
	@echo "$(COLOR_GREEN)Services rebuilt$(COLOR_RESET)"

prune:
	@echo "$(COLOR_RED)️  This will remove unused Docker resources$(COLOR_RESET)"
	@docker system prune -f
	@echo "$(COLOR_GREEN) Docker system pruned$(COLOR_RESET)"


.DEFAULT_GOAL := help
