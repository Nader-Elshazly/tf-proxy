# Terraform Project with Nginx and Flask

## 🧭 Project Overview

This project provisions a complete AWS infrastructure using **Terraform**, deploying a Flask-based web application behind **Nginx reverse proxies**.
It includes a **VPC** with both public and private subnets, **load balancers**, and **network gateways** for secure and scalable web architecture.

---

## 🏗️ Architecture Overview

### **Network Layout**

* **VPC:** Custom CIDR blocks for both public and private subnets.
* **Public Subnets:**

  * `10.0.0.0/24`
  * `10.0.2.0/24`
  * Contain **Nginx reverse proxy EC2 instances**.
* **Private Subnets:**

  * `10.0.1.0/24`
  * `10.0.3.0/24`
  * Contain **Flask application backend EC2 instances**.
* **NAT Gateway:** Enables private subnets to access the internet.
* **Internet Gateway:** Provides internet access for public subnets.

### **Load Balancers**

* **Public ALB:** Routes incoming web traffic to Nginx proxies.
* **Internal ALB:** Routes traffic from Nginx proxies to Flask backends.

---

## 🧩 Terraform Setup

### **Workspace**

Create and switch to a new Terraform workspace named `dev`:

```bash
terraform workspace new dev
```

### **Backend**

Configure a **remote backend** to store the Terraform state file securely.

### **Modules**

This project uses custom Terraform modules for:

* **VPC**
* **EC2 instances**
* **Load balancers**

Each module includes:

```
main.tf
variables.tf
outputs.tf
```

---

## ⚙️ Provisioners

A `local-exec` provisioner is used to output instance and ALB IPs into a file named **all-ips.txt**, formatted as follows:

```
public-ip1 98.94.78.45
public-ip2 52.87.153.67
private-ip1 10.0.1.58
private-ip2 10.0.3.224
```

---

## 🌐 Nginx Proxy Configuration

Below is an example configuration used for the reverse proxy setup:

```nginx
server {
    listen 80;
    server_name _;

    resolver 10.0.0.2 valid=30s;
    set $backend_server "http://${var.internal_alb_dns}";

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    location / {
        proxy_pass $backend_server;
    }
}
```

---

## 🚀 Accessing the Application

Traffic flow:

```
Public ALB → Nginx Proxies → Internal ALB → Flask Backends
```

Once deployed, open the **Public ALB DNS name** in your browser to access the app.

---

## 🧰 Quick Start

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd <project-folder>
   ```

2. **Initialize and deploy Terraform:**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Clean up resources when finished:**

   ```bash
   terraform destroy
   ```

---


