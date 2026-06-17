
## Karpenter

### What is Karpenter?

Karpenter is an open-source Kubernetes node autoscaler developed by AWS that automatically provisions and terminates EC2 instances based on application workload requirements.

Unlike traditional cluster autoscalers, Karpenter directly interacts with AWS APIs to launch the most suitable EC2 instances dynamically.

---

### Why Do We Need Karpenter?

In Kubernetes, Horizontal Pod Autoscaler (HPA) scales pods based on CPU or memory usage. However, if there are insufficient nodes available in the cluster, new pods remain in the `Pending` state.

Karpenter solves this problem by automatically creating new worker nodes when required and removing unused nodes to optimize costs.

### Benefits of Karpenter

- Automatic node provisioning
- Faster scaling compared to Cluster Autoscaler
- Cost optimization through node consolidation
- Supports Spot and On-Demand instances
- Dynamically selects the best EC2 instance type
- Removes underutilized nodes automatically

---

**HPA scales Pods, while Karpenter scales Nodes. Together they provide complete autoscaling in Amazon EKS.**

### step by step implementation of **Karpenter**
---

#### step1: Karpenter is installed in clusters with a **Helm chart**.

Karpenter requires cloud provider permissions to provision nodes, for AWS IAM Roles for Service Accounts **(IRSA)** should be used. IRSA permits Karpenter (within the cluster) to make privileged requests to AWS (as the cloud provider) via a ServiceAccount.

---
### step2: Install Karpenter IAM Roles

- Download CloudFormation template:

- curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/v"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml  > "${TEMPOUT}" \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

---

### Step3: Create Node IAM Role

 eksctl create iamidentitymapping \
  --cluster ${CLUSTER_NAME} \
  --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME} \
  --username system:node:{{EC2PrivateDNSName}} \
  --group system:bootstrappers \
  --group system:nodes
---
### Step4: Install Karpenter

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set "settings.enableZonalShift=${ENABLE_ZONAL_SHIFT}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait
---
### Step 5: Create EC2NodeClass

#### EC2NodeClass

`EC2NodeClass` defines **how nodes are created** in AWS. It contains infrastructure-related configurations such as:

- AMI family (Amazon Linux)
- IAM role
- Subnets
- Security groups

In simple terms, **EC2NodeClass specifies the AWS infrastructure configuration for worker nodes.**

---
- [EC2NodeClass.yaml](/quickChat/k8/karpenter/ec2-node-class.yaml)

```bash
kubectl apply -f ec2-node-class.yaml
```
---
### Step 6 : Create NodePool

### NodePool

`NodePool` defines **when and what type of nodes should be created**. It contains scheduling and scaling rules such as:

- Allowed instance types
- CPU limits
- Spot or On-Demand capacity
- Node consolidation policies

In simple terms, **NodePool controls node provisioning and autoscaling behavior.**

---
- [Node-Pool.yaml](/quickChat/k8/karpenter/node-pool.yaml)

```bash
kubectl apply -f node-pool.yaml
```
---

### Relationship

```text
Pods Need Resources
        ↓
NodePool decides which nodes to create
        ↓
EC2NodeClass provides AWS configuration
        ↓
Karpenter launches EC2 instances
        ↓
Pods are scheduled on new nodes
```
