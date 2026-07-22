# AWS Serverless Cloud Resume & Automated CI/CD Pipeline

[![Frontend Deployment](https://github.com/Nitinkurva/cloud-resume/actions/workflows/frontend.yaml/badge.svg)](https://github.com/Nitinkurva/cloud-resume/actions/workflows/frontend.yaml)
[![Backend Deployment](https://github.com/Nitinkurva/cloud-resume/actions/workflows/backend.yaml/badge.svg)](https://github.com/Nitinkurva/cloud-resume/actions/workflows/backend.yaml)

> A serverless micro-service portfolio hosted on AWS, fully provisioned via Infrastructure as Code (Terraform) and deployed with decoupled GitHub Actions CI/CD pipelines incorporating automated Python unit testing.

🌐 **Live Website:** [https://nitincloud.co.uk](https://nitincloud.co.uk)

![Live Website Preview](assets/website-preview.png)  

📝 **Architecture Write-Up:** [Link to my future blog post]

---

## 📐 Architecture Overview

    [ User Browser ] ───(DNS Query)───► [ Route 53 (DNS) ]
           │                                  │
           │                                  ▼ (Alias Record)
           ├──────────────────────────► [ CloudFront (CDN) ] ◄─── (SSL Cert) ─── [ ACM ]
           │                                  │
           │                                  ▼ (OAC / Origin Access Control)
           │                            [ S3 Bucket ] (Static Assets: HTML/CSS/JS)
           │
           ▼ (JavaScript fetch request)
    [ HTTP API Gateway ] (Low-latency REST/HTTP Proxy)
           │
           ▼ (Lambda Proxy Integration)
    [ AWS Lambda ] (Python 3.x Backend)
           │
           ▼ (boto3 atomic update)
    [ Amazon DynamoDB ] (Visitor Counter Table)

### Live Infrastructure Verification

![AWS Console Deployment](assets/aws-console.png)

### Request Lifecycle & Flow
1. **DNS & Edge Routing:** The user requests your custom domain. Route 53 resolves the query and directs traffic to CloudFront edge locations, secured with a custom TLS certificate managed by AWS Certificate Manager (ACM).
2. **Static Asset Delivery:** CloudFront serves static website files directly from the private S3 Bucket using Origin Access Control (OAC).
3. **Dynamic API Call:** As index.html loads, embedded JavaScript executes an asynchronous HTTP POST request to API Gateway (HTTP API).
4. **Serverless Execution:** API Gateway triggers an AWS Lambda execution environment running Python.
5. **State Persistence:** Lambda calls DynamoDB via boto3 to atomically increment and return the global visitor count back through the API to the user's browser.

---

## 🛠️ Key Skills & Technologies Demonstrated

| Category | Demonstrated Skills & AWS Services |
| :--- | :--- |
| **Cloud Infrastructure (AWS)** | S3, CloudFront, Route 53, ACM, API Gateway (HTTP API), Lambda, DynamoDB |
| **Infrastructure as Code (IaC)** | Terraform (Modules, S3 Remote State, Provider Pinning) |
| **CI/CD & Automation** | GitHub Actions (Decoupled Workflows, Automated Testing Gates, Multi-OS Runners) |
| **Backend & Testing** | Python 3.x (`boto3`), Unit Testing (`unittest`), Dependency Mocking (`unittest.mock`) |
| **Networking & Security** | DNS Management (Route 53), Custom Domain TLS/HTTPS (ACM), CDN Edge Delivery (CloudFront OAC) |
| **Frontend & Version Control** | HTML5, CSS3, JavaScript (Asynchronous Fetch API), Git, GitHub |

---

## 💰 Financial & Resource Efficiency

Because this architecture is 100% serverless, operating costs fall entirely within the **AWS Free Tier** for standard personal usage:
* **S3 & CloudFront:** $0.00 / month (under 1 TB egress).
* **API Gateway & Lambda:** $0.00 / month (under 1M free requests).
* **DynamoDB:** $0.00 / month (25 GB free storage using On-Demand pricing).
* **Estimated Running Cost:** **~$0.50 / month** (primarily Route 53 Hosted Zone charge).

---

## 🚀 Key Engineering & Architecture Decisions

### 1. Decoupled CI/CD Pipelines (`frontend.yaml` vs. `backend.yaml`)
To optimize deployment speed and isolate risk, the automation is split into two distinct GitHub Actions workflows:
* **`frontend.yaml`:** Triggered only on changes within `website/**` or `.github/workflows/frontend.yaml`. Executes rapid `aws s3 sync` and invalidates CloudFront cache in ~10–15 seconds without running heavy infrastructure code.
* **`backend.yaml`:** Triggered on changes to `*.tf` or `lambda/**` or `.github/workflows/backend.yaml`. Handles Python dependencies, executes unit testing gates, and runs `terraform init` / `terraform plan` / `terraform apply`.

![GitHub Actions Decoupled Pipelines](assets/github-actions.png)

### 2. Isolated Unit Testing Gates
Before Terraform touches live AWS infrastructure, GitHub Actions runs `test_lambda.py`. Using mocks (`unittest.mock`), the tests simulate DynamoDB responses in memory without requiring AWS credentials or network latency. If tests fail, execution halts immediately and deployment is aborted.

### 3. Declarative Infrastructure & State Hygiene
* **Declarative Provisioning:** Infrastructure state is managed strictly via Terraform.
* **Security & Secret Protection:** Terraform state is stored remotely in an S3 backend with versioning enabled and excluded from Git using `.gitignore` to prevent accidental exposure of infrastructure metadata.

---

## 🧪 Running Tests Locally

To run the backend Python unit tests locally without modifying live AWS resources:

    cd lambda
    python -m unittest test_lambda.py

![Backend Unit Tests Passing](assets/terminl-tests.png)

---

## 🔮 Roadmap & Technical Callouts

### Planned Security & Domain Enhancements
* [ ] **CloudFront Origin Access Control (OAC):** Restrict S3 bucket policy strictly to CloudFront OAC once public access blocks are re-enabled.
* [ ] **Custom Domain for API Gateway:** Map a dedicated subdomain (e.g., `api.nitincloud.co.uk`) with an ACM SSL certificate to mask the default API Gateway endpoint.

### 💡 DevOps Insight: Windows vs. Linux Zip Hashes
During CI/CD workflow setup, I observed that Terraform's `filename_sha256` or `source_code_hash` for the Lambda `.zip` package produces different hash values when built on a local **Windows** machine versus the **Linux (`ubuntu-latest`)** GitHub Actions runner (due to OS line-ending differences `CRLF` vs `LF` and file permission metadata).
* **Resolution:** Delegating the build/packaging step strictly to the Linux runner inside `backend.yaml` ensures consistent drift-free deployments.
  
---

## 📁 Repository Structure

    .
    ├── .github/
    │   └── workflows/
    │       ├── frontend.yaml       # S3 sync & CloudFront cache invalidation
    │       └── backend.yaml        # Python tests & Terraform deployment
    ├── lambda/
    │   ├── lambda_function.py      # Production AWS Lambda backend code
    │   └── test_lambda.py          # Unit tests with DynamoDB mocking
    ├── website/                    # Static HTML/CSS/JS frontend assets
    ├── main.tf                     # Core Terraform infrastructure definitions
    ├── .terraform.lock.hcl         # Pinpoint Terraform provider version locks
    ├── .gitattributes              # Git path and attribute configurations
    ├── .gitignore                  # Excludes .tfstate, binaries, & secrets
    └── README.md
---

---

## 📬 Connect With Me

* **Website:** [nitincloud.co.uk](https://nitincloud.co.uk)
* **GitHub:** [github.com/Nitinkurva](https://github.com/Nitinkurva)
* **LinkedIn:** [linkedin.com/in/my-profile](https://linkedin.com/in/my-profile)
