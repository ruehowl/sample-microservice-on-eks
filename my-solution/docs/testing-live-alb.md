# Live Testing (EKS via ALB Ingress)

This guide shows how to validate the deployed service through the AWS ALB created by the Kubernetes Ingress.

## Prerequisites
- `kubectl` configured for the target EKS cluster
- The Helm release deployed (see `my-solution/docs/deployment.md`)

## 1. Find the Ingress and ALB hostname

The Helm chart creates an Ingress named `document-service` (release name) in the target namespace.

```sh
# set namespace if you deployed somewhere other than default
NAMESPACE=default

kubectl -n "$NAMESPACE" get ingress
kubectl -n "$NAMESPACE" get ingress document-service -o wide

# ALB DNS name
ALB_HOST=$(kubectl -n "$NAMESPACE" get ingress document-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "$ALB_HOST"
```

If `ALB_HOST` is empty, wait for the controller to provision the ALB and try again.

## 2. Determine the Host header

The Ingress host comes from the Helm values file `my-solution/kubernetes/helm/values/document-service-dev.yaml`.

Default in this repo:
- `Host: document-service-dev.local`

Set it once:

```sh
HOST_HEADER=document-service-dev.local
```

## 3. Health checks via ALB

```sh
curl -fsS -H "Host: $HOST_HEADER" "http://$ALB_HOST/health/live"
curl -fsS -H "Host: $HOST_HEADER" "http://$ALB_HOST/health/ready"
```

## 4. Document API roundtrip via ALB

Create/update:

```sh
doc_id=example-id-1
curl -fsS -X PUT -H "Host: $HOST_HEADER" \
  -H "Content-Type: application/json" \
  "http://$ALB_HOST/documents/$doc_id" \
  -d '{"content":"hello-from-alb"}'
```

Retrieve:

```sh
curl -fsS -H "Host: $HOST_HEADER" "http://$ALB_HOST/documents/$doc_id"
```

Example (as requested):

```sh
curl -H "Host: document-service-dev.local" \
  "http://$ALB_HOST/documents/example-id-1"
```

