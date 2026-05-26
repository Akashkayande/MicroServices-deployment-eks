# 🔍 End-to-End Production-Grade Distributed Tracing on Amazon EKS using OpenTelemetry & Jaeger

## 📌 Project Overview

In modern **production-grade, cloud-native systems**, applications are built using **multiple microservices** deployed across Kubernetes clusters. While **monitoring** tells us *whether* a system is healthy and **logging** tells us *what* went wrong, neither clearly answers the most critical question:

> **Where exactly did the problem occur in a complex, distributed system?**

This project demonstrates a **production-level, industry-standard implementation of distributed tracing** on an **Amazon EKS (Kubernetes) cluster** using **OpenTelemetry** and **Jaeger**, with **Elasticsearch** as the trace storage backend.

The goal of this project is to **trace requests end-to-end across multiple microservices**, and debug failures efficiently.

---

## ❗ Problem Statement

In production environments:

* Applications consist of **multiple microservices**
* Requests flow through **multiple components** (API Gateway → Backend → Database → External services)
* Failures and latency issues are **hard to debug** using logs alone

### Observability Pillars

| Pillar         | Purpose                             |
| -------------- | ----------------------------------- |
| **Monitoring** | Tells *if* the system is healthy    |
| **Logging**    | Tells *what* happened               |
| **Tracing**    | Tells *where* and *why* it happened |

🔎 **Tracing is the missing link** that shows the complete request journey across services.

---
🔎 Tracing Implementation Tool is **Jaeger**

## 🕵️‍♂️ What is Jaeger?

**Jaeger** is an open-source, end-to-end **distributed tracing system** used for monitoring and troubleshooting microservices-based architectures.

It helps engineers:

* Visualize request flows
* Measure latency at each service hop
* Identify failures and bottlenecks

---

## ❓ Why Use Jaeger?

In a microservices architecture, a single user request may touch **dozens of services**. Jaeger helps by:

* 🔍 **Finding root causes of failures**
* ⚡ **Optimizing service latency**
* 🧭 **Understanding service dependencies**

---
🧩 Core Components of Jaeger

* Agent: Collects traces from your application.
* Collector: Receives traces from the agent and processes them.
* Query: Provides a UI to view traces.
* Storage: Stores traces for later retrieval (often a database like Elasticsearch).
---
## 🏗️ Architecture Overview

<p align="center">
  <img src="/Production-Grade_GitOps-Driven_Microservices-Demo/observability/tracing/architecture (1).png" width="700"/>
</p>
---
### High-Level Flow

1. Client sends request
2. Request passes through multiple microservices
3. OpenTelemetry instruments generate spans
4. Traces are sent to Jaeger
5. Jaeger stores traces in Elasticsearch
6. Traces are visualized in Jaeger UI

---

## 🚀 Step-by-Step Implementation

### ✅ Step 1: Instrument Application using OpenTelemetry

To enable tracing, applications must be **instrumented**.

We use **OpenTelemetry**, the industry-standard observability framework.

* Tracing is implemented at the application level
* Automatically captures HTTP requests, responses, and service interactions

📎 **Instrumentation File**:

* 🔗 [`tracing.js`](/Production-Grade_GitOps-Driven_Microservices-Demo/observability/tracing/tracing.js)

---

## 🗄️ Elasticsearch Setup (Persistent Trace Storage)

Jaeger requires a storage backend. In production, **Elasticsearch** is commonly used.

### Why Elasticsearch?

* Scalable
* Persistent
* Production-proven

Since Elasticsearch requires **persistent storage**, we use **AWS EBS volumes**.

Since EKS (Kubernetes) and EBS (storage service) are separate AWS services, secure and controlled access between them is required. This integration is achieved using:

IAM Roles for Service Accounts (IRSA)

OIDC identity provider associated with the EKS cluster

AWS EBS CSI Driver for dynamic volume provisioning
---

### 1️⃣ Create IAM Service Account for EBS CSI Driver

```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster observability \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve
```

```bash
ARN=$(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole --query 'Role.Arn' --output text)
```

---

### 2️⃣ Install EBS CSI Driver
* Without the EBS CSI Driver, Kubernetes cannot provision EBS-backed persistent volumes.

```bash
eksctl create addon \
  --cluster observability \
  --name aws-ebs-csi-driver \
  --version latest \
  --service-account-role-arn $ARN \
  --force
```

---

### 3️⃣ Create Logging Namespace

```bash
kubectl create namespace logging
```

---

### 4️⃣ Install Elasticsearch using Helm

```bash
helm repo add elastic https://helm.elastic.co
```

```bash
helm install elasticsearch \
  --set replicas=1 \
  --set volumeClaimTemplate.storageClassName=gp2 \
  --set persistence.labels.enabled=true \
  elastic/elasticsearch -n logging
```

---
 

### 🔑 Elasticsearch Credentials

Jaeger requires Elasticsearch credentials during configuration.
* **Username**: `elastic`
* **Password**:

```bash
kubectl get secrets --namespace=logging elasticsearch-master-credentials \
-ojsonpath='{.data.password}' | base64 -d
```

---

### 4️⃣ Install Jaeger using Helm

```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update
```

```bash
helm install jaeger jaegertracing/jaeger \
-n tracing --values tracing/jaeger-values.yaml
```

📎 Configuration:

* 🔗 [`jaeger-values.yaml`](/Production-Grade_GitOps-Driven_Microservices-Demo/observability/tracing/jaeger-values.yaml)

---

### ✅ Verify Installation

```bash
kubectl get pods -n tracing
```

## 🌐 Access Jaeger UI

```bash
kubectl port-forward svc/jaeger-query 8080:80 -n tracing
```

### INSTALL OTel COLLECTOR (GATEWAY)

* Gateway collector:

- Central processing
- Sampling
- Exporting
- Add Repo

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```
### Install Agent Collector

* 🔗 [`otel-collector-values.yaml`](/Production-Grade_GitOps-Driven_Microservices-Demo/observability/tracing/otel-collector-values.yaml)

```bash
helm install otel-agent open-telemetry/opentelemetry-collector \
  -n observability \
  -f otel-collector-values.yaml
```
