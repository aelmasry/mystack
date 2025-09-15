# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-09-13

### Added
- Complete VPS Docker environment setup
- n8n workflow automation with PostgreSQL and Redis
- Ollama + OpenWebUI for local AI/LLM hosting
- Nginx Proxy Manager for reverse proxy and SSL management
- Portainer CE for Docker container management
- Dozzle for Docker log viewing
- Static website hosting capabilities
- Automated backup system with configurable retention
- UFW firewall configuration
- Automated security updates
- Comprehensive management scripts
- Docker network isolation
- Let's Encrypt SSL certificate automation

### Core Services
- **n8n Stack**: n8n + PostgreSQL + Redis for workflow automation
- **AI Services**: Ollama + OpenWebUI for local LLM hosting
- **Proxy**: Nginx Proxy Manager with HTTPS/SSL automation
- **Monitoring**: Portainer + Dozzle for container management
- **Websites**: Static website hosting with SSL

### Security Features
- UFW firewall with minimal port exposure
- HTTPS everywhere via Let's Encrypt
- Isolated Docker networks
- Automated security updates
- Service-specific authentication

### Management
- One-command server initialization
- Automated service deployment
- Backup and restore functionality
- Health monitoring and status checks
- Log management and cleanup

### Documentation
- Comprehensive README with quick start
- Troubleshooting guides
- Architecture documentation
- Security best practices

### Scripts
- `init-server.sh` - VPS initialization
- `deploy-all.sh` - Service deployment
- `backup.sh` - Data backup
- `restore.sh` - Data restoration
- `status.sh` - Service status check
- Various management utilities

## [Unreleased]

### Planned
- Grafana + Prometheus monitoring stack
- Additional AI model support
- Enhanced backup encryption
- Multi-server deployment support
- Automated SSL certificate renewal monitoring
