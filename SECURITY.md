# Security Policy

## Supported Versions

This is a practice environment for learning Apache Iceberg. Security updates are provided on a best-effort basis.

## Reporting a Vulnerability

If you discover a security vulnerability in this repository, please report it responsibly.

### How to Report

**Do NOT open a public issue** for security vulnerabilities.

Instead, please use one of these methods:
- Open a private security advisory via GitHub's Security Advisory feature
- Send an email using the GitHub security contact form

Your report should include:
- A description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Any suggested mitigation or fix (if available)

### What to Expect

- You will receive an acknowledgment of your report within 48 hours
- We will investigate the vulnerability and determine the severity
- We will work on a fix and coordinate disclosure with you
- We will aim to patch the vulnerability within a reasonable timeframe
- We will credit you for the discovery (unless you wish to remain anonymous)

## Security Best Practices for This Environment

### Development Environment

This is a **practice/learning environment** with simplified security configurations:

- Default credentials are used for convenience
- Authentication is disabled on some services
- Services are exposed on localhost for easy access
- No encryption for internal communications

### Production Deployment Considerations

If you adapt this environment for production use, you MUST:

1. **Change all default credentials**
   - MinIO/ObjectScale credentials
   - MySQL root password
   - Polaris catalog authentication
   - Spark History Server credentials

2. **Enable authentication**
   - Enable Polaris authentication
   - Configure proper IAM policies
   - Use secrets management (Kubernetes Secrets, AWS Secrets Manager, etc.)

3. **Network security**
   - Use network policies in Kubernetes
   - Implement TLS/SSL for all endpoints
   - Restrict access to sensitive services
   - Use VPNs or private networks for internal communication

4. **Data encryption**
   - Enable encryption at rest for storage
   - Enable encryption in transit (TLS)
   - Use encrypted volumes

5. **Monitoring and logging**
   - Enable audit logging
   - Monitor for suspicious activity
   - Implement log aggregation
   - Set up alerts for security events

### Current Security Limitations

This practice environment has the following known security limitations:

- **Hardcoded default credentials** in `.env.example` (for documentation purposes only)
- **No authentication** on Polaris catalog (disabled for learning convenience)
- **No TLS/SSL** encryption for service communication
- **Open ports** on localhost without access controls
- **No secrets management** integration
- **No security scanning** in CI/CD pipeline

### Environment Variables

Never commit actual credentials to the repository. Use environment variables:

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your actual credentials
# .env is listed in .gitignore and will not be committed
```

### Kubernetes Secrets

For Kubernetes deployments, use proper secrets management:

```bash
# Create secrets from environment variables
kubectl create secret generic iceberg-storage-secrets \
  --from-literal=storage-access-key=$STORAGE_ACCESS_KEY \
  --from-literal=storage-secret-key=$STORAGE_SECRET_KEY \
  --namespace=iceberg

# Or use a secrets manager like:
# - Kubernetes External Secrets Operator
# - AWS Secrets Manager
# - HashiCorp Vault
```

## Dependency Security

This project uses the following major dependencies:

- Apache Spark (OSS)
- Apache Iceberg (OSS)
- Apache Polaris (Incubating)
- Apache Kafka
- MySQL Community Server
- MinIO/ObjectScale

Keep these dependencies updated to benefit from security patches.

## Security Scanning

We recommend running security scans on your environment:

```bash
# Scan Docker images for vulnerabilities
docker scan apache/polaris:0.7.0-incubating
docker scan apache/spark:3.5.0
docker scan mysql:8.0

# Scan Python dependencies
pip install safety
safety check

# Scan Kubernetes manifests
kubectl apply --dry-run=client -f k8s/
```

## License and Disclaimer

This project is licensed under the Apache License 2.0. See LICENSE file for details.

**Disclaimer**: This is an independent educational resource for learning Apache Iceberg and data lakehouse concepts. It is not affiliated with, endorsed by, or sponsored by Apache Iceberg or any vendor. The maintainers are not responsible for any security issues that may arise from using this environment in production without proper security hardening.

## Additional Resources

- [Apache Iceberg Security](https://iceberg.apache.org/security/)
- [Apache Spark Security](https://spark.apache.org/security.html)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/security-overview/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Top 10](https://owasp.org/www-project-docker-top-ten/)

---

Thank you for helping keep this project secure!
