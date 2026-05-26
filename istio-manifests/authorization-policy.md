# What is Istio Authorization Policy?

AuthorizationPolicy is an Istio security resource used to control:

- which service can access another service
- who is allowed or denied
- what actions are permitted

It provides Zero Trust Security inside Kubernetes.

---

# Why AuthorizationPolicy is Needed?

In microservices architecture:

```text
Frontend -> Order Service -> Payment Service
```

Without AuthorizationPolicy:
- any pod may access any service

This is insecure.

AuthorizationPolicy restricts communication.

Example:
- frontend can access order-service
- only order-service can access payment-service
- other pods denied

---

# How AuthorizationPolicy Works

Istio uses:
- Envoy sidecar proxies
- mTLS identities
- service accounts

to verify and authorize requests.

---


# for practical impelementation see [helm-chart-services-manifest](/Production-Grade_GitOps-Driven_Microservices-Demo/helm-chart/templates/adservice.yaml)