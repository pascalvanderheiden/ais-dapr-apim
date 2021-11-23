# ais-dapr-apim
This repo contains the technical instructions to complete an end-to-end scenario for using Dapr with Azure API Management Self-Hosted Gateway.

# Setup environment
minikube start
dapr init -k

## Add Distributed Tracing with Application Insights

kubectl apply -f config/open-telemetry-collector-appinsights.yaml
kubectl apply -f config/collector-config.yaml

## Create API Gateway
## Download file and script
## Add Dapr Sidecar

kind: Deployment
spec:
  template:
    metadata:
        annotations:
            dapr.io/enabled: "true" 
            dapr.io/app-id: "apim-local-gw-app"
            dapr.io/app-port: "3500"
            dapr.io/config: "tracing"

## Run script from portal

kubectl create secret generic xxx --from-literal=value="xxx" --type=Opaque

kubectl apply -f requests/apim-local-gw.yaml

kubectl get pods
kubectl describe pod <PODNAME>

## Get Health (/health) policy (check APIM connection)

# Create API in Azure Portal, connect to Gateway 
    <inbound>
        <base />
        <return-response>
            <set-status code="200" />
            <set-body>@("All is okay. Cheers from " + context.Deployment.Region)</set-body>
        </return-response>
    </inbound>

kubectl port-forward service/apim-local-gw 8080:80 8081:443

# Test

## Post Order (/order) policy (Dapr PubSub)
    <inbound>
        <base />
        <publish-to-dapr topic="@("pub-sub-orders/orders")" timeout="10" ignore-error="false" template="liquid">{{body}}</publish-to-dapr>
        <return-response>
            <set-status code="200" />
            <set-body>@("Message send to Service Bus.")</set-body>
        </return-response>
    </inbound>

kubectl apply -f components/pub-sub-orders.yaml

kubectl get components

kubectl rollout restart deployments/apim-local-gw

kubectl port-forward service/apim-local-gw 8080:80 8081:443

# Test
# Show message in Service Bus Topic in Azure Portal

## Get Orders (/order) policy (Dapr Service Invocation)
    <inbound>
        <base />
        <set-backend-service backend-id="dapr" dapr-app-id="httpbin-app" dapr-method="get" />
        <set-header name="x-dapr-test" exists-action="override">
            <value>request-header</value>
        </set-header>
    </inbound>

kubectl apply -f services/httpbin-app.yaml

kubectl get pods

kubectl port-forward service/apim-local-gw 8080:80 8081:443

# Test

## Get Order (/order/{id}) policy (Dapr state-store)
    <inbound>
        <base />
        <set-backend-service base-url="http://localhost:3500" />
        <rewrite-uri template="/v1.0/state/state-store-orders/{id}" copy-unmatched-params="true" />
    </inbound>

kubectl apply -f components/state-store-orders.yaml

kubectl get components

kubectl port-forward deployment/apim-local-gw 3500:3500

# Get some orders in 
# prereq.http

kubectl port-forward service/apim-local-gw 8080:80 8081:443

# Test

# Application Insights Portal