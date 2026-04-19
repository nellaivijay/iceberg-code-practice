# Getting Started with Apache Iceberg Code Practice

This guide will walk you through setting up your environment and completing your first coding lab.

## Prerequisites

Before you begin, make sure you have:
- Docker or Podman installed
- 16GB RAM minimum (for full environment)
- 40GB disk space available
- Basic knowledge of SQL and data concepts
- Familiarity with command line interface

## Step 1: Clone the Repository

Choose one of these methods:

### Option A: Using Git (Recommended)
```bash
git clone https://github.com/nellaivijay/iceberg-code-practice.git
cd iceberg-code-practice
```

### Option B: Download ZIP
1. Go to https://github.com/nellaivijay/iceberg-code-practice
2. Click the green "Code" button
3. Select "Download ZIP"
4. Extract the files to your computer

## Step 2: Choose Your Setup Method

### Option 1: Kubernetes with k3s (Recommended)

**Pros:**
- Production-like environment
- Better resource isolation
- Full feature set
- Suitable for advanced labs

**Cons:**
- More complex setup
- Higher resource requirements
- Requires k3s installation

#### Install k3s
```bash
curl -sfL https://get.k3s.io | sh -
# Verify installation
kubectl version --client
```

#### Setup the Environment
```bash
# Run setup script
./scripts/setup.sh

# Apply Kubernetes manifests
kubectl apply -f k8s/

# Wait for pods to be ready
kubectl get pods -w
```

#### Verify Setup
```bash
# Check all services are running
kubectl get pods

# Access Spark UI
kubectl port-forward svc/spark-master 8080:8080

# Access Trino UI
kubectl port-forward svc/trino 8081:8080
```

### Option 2: Docker Compose (Lightweight)

**Pros:**
- Quick to set up
- Lower resource requirements
- Easier to troubleshoot
- Good for initial learning

**Cons:**
- Limited resource isolation
- Some advanced features may not work
- Less production-like

#### Start the Environment
```bash
# Start all services
docker-compose up -d

# Check services are running
docker-compose ps

# View logs
docker-compose logs -f
```

#### Verify Setup
```bash
# Access Spark UI
open http://localhost:8080

# Access Trino UI
open http://localhost:8081

# Check Iceberg catalog
docker-compose exec spark bash
```

## Step 3: Load Sample Data

The environment includes a comprehensive sample database for hands-on learning.

### Generate Sample Data
```bash
python3 scripts/generate_sample_data.py
```

This creates:
- 1,000 customer records
- 200 product records
- 5,000 order records
- 10,000 transaction records
- 20,000 web event records

### Load Sample Data into Iceberg
```bash
./scripts/load_sample_data.sh
```

This loads the generated data into Iceberg tables using Spark.

### Verify Sample Data
```bash
# Access Spark shell
docker-compose exec spark bash
spark-sql

# In Spark SQL
SHOW DATABASES;
USE sample_db;
SHOW TABLES;
SELECT COUNT(*) FROM sample_customers;
```

## Step 4: Complete Your First Lab

Let's start with Lab 0: Sample Database Setup

### Lab 0: Sample Database Setup

**Objective**: Explore the sample database and practice basic queries

**Prerequisites**: Environment setup complete, sample data loaded

**Estimated Time**: 30-45 minutes

#### Step 1: Access the Lab
```bash
# Open the lab markdown file
cat labs/lab-00-sample-database.md

# Or open in your preferred editor
```

#### Step 2: Follow the Instructions
The lab will guide you through:
1. Understanding the sample database schema
2. Exploring table relationships
3. Writing queries to answer business questions
4. Understanding data distribution and patterns

#### Step 3: Use the Jupyter Notebook (Optional)
```bash
# Start Jupyter (if using Docker Compose)
docker-compose exec spark jupyter notebook

# Navigate to notebooks/lab-00-sample-database.ipynb
```

#### Step 4: Check Your Work
Compare your results with the solution:
```bash
# View solution notebook
cat solutions/lab-00-sample-database-solution.ipynb
```

## Step 5: Move to Lab 1

After completing Lab 0, proceed to Lab 1: Environment Setup

### Lab 1: Environment Setup
**Objective**: Verify all components and perform your first Iceberg operation

**Estimated Time**: 30-45 minutes

This lab will:
- Verify catalog connectivity
- Test storage access
- Create your first Iceberg table
- Perform basic read/write operations

## Common Setup Issues

### Issue: Docker containers won't start

**Solution:**
```bash
# Check Docker is running
docker ps

# Check available disk space
df -h

# Check available memory
free -h

# Restart Docker
sudo systemctl restart docker
```

### Issue: k3s pods stuck in Pending state

**Solution:**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes

# Check for resource limits
kubectl get nodes -o yaml | grep -A 5 resources
```

### Issue: Out of memory errors

**Solution:**
- Reduce the number of running services
- Increase system RAM or swap space
- Use Docker Compose instead of k3s for lighter footprint
- Adjust memory limits in docker-compose.yaml

### Issue: Storage backend connection errors

**Solution:**
```bash
# Check storage service is running
docker-compose ps objectscale

# Check storage logs
docker-compose logs objectscale

# Verify environment variables
env | grep STORAGE
```

## Tips for Success

### Start with Docker Compose
If you're new to Docker or have limited resources, start with Docker Compose. It's easier to troubleshoot and requires fewer resources.

### Allocate Enough Resources
- Minimum 16GB RAM for full environment
- 8GB RAM may work with reduced services
- At least 40GB disk space for data and logs

### Use the Solution Notebooks
If you get stuck, check the solution notebooks in the `solutions/` folder. They provide complete working examples.

### Take Notes
Document your setup steps and any issues you encounter. This will help you troubleshoot later and contribute improvements.

### Join the Community
- Open GitHub Issues for problems
- Share your solutions and insights
- Contribute improvements to the labs

## Next Steps

After completing Lab 0 and Lab 1:

1. **Lab 2**: Basic Iceberg Operations - Learn core table operations
2. **Lab 3**: Advanced Features - Partitioning, time travel, schema evolution
3. **Lab 4**: Spark Optimizations - Performance tuning
4. **Follow the Learning Path**: See [Learning Path](Learning-Path.md) for recommended order

## Environment URLs (Default)

Once setup is complete, you can access:

- **Spark UI**: http://localhost:8080
- **Spark History Server**: http://localhost:18080
- **Trino UI**: http://localhost:8081
- **Grafana** (if configured): http://localhost:3000
- **MinIO Console** (if using MinIO): http://localhost:9000

## Stopping the Environment

### Docker Compose
```bash
docker-compose down
# Or to remove volumes
docker-compose down -v
```

### Kubernetes
```bash
kubectl delete -f k8s/
# Or delete specific resources
kubectl delete deployment spark-master
```

## Cleaning Up

To completely remove the environment:

```bash
# Docker Compose
docker-compose down -v
docker system prune -a

# Kubernetes
kubectl delete -f k8s/
k3s-uninstall.sh
```

## Need Help?

- Check the [Troubleshooting](Troubleshooting.md) page
- Review [Best Practices](Best-Practices.md)
- Open an issue on GitHub
- Start a discussion in GitHub Discussions

---

**Ready to start learning?** [Begin with Lab 0](https://github.com/nellaivijay/iceberg-code-practice/blob/main/labs/lab-00-sample-database.md) 🚀