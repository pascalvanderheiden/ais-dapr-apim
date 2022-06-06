## Step 1: Run all prerequisites and deployment of Azure Services
minikube start
dapr init -k

## Step 2: Show services in Azure & Create an API Gateway (apim-local-gw)
requests/apim-local-gw.yaml

# Past yaml from Portal

# Add Dapr Sidecar, annotation part
kind: Deployment
spec:
  template:
    metadata:
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "apim-local-gw-app"
        dapr.io/app-port: "3500"
#        dapr.io/config: "tracing"

# Copy deployment script from Portal
kubectl create secret...........
kubectl apply -f requests/apim-local-gw.yaml

# Check if deployment is successful
kubectl get pods
kubectl describe pod <podname>

## Step 3: Add Logging to Application Insights (Update Instrumentation Key)
config/open-telemetry-collector-appinsights.yaml
kubectl apply -f config/open-telemetry-collector-appinsights.yaml
kubectl apply -f config/collector-config.yaml

# Update APIM Gateway to use Logging (uncomment tracing)
requests/apim-local-gw.yaml
kubectl apply -f requests/apim-local-gw.yaml

## Step 4: Create Dapr API (dapr) 
Set logging and Gateway

## Step 5: Create Get Health (/health)

# Set Policy
<inbound>
    <base />
        <return-response>
            <set-status code="200" />
            <set-body>@("All is okay. Cheers from " + context.Deployment.Region)</set-body>
        </return-response>
</inbound>

# Test
kubectl port-forward service/apim-local-gw 8080:80 8081:443
requests/tests.http

## Step 6: Create Post Order (/order)

## Show Diagram (docs/images/arch.png)

# Update Dapr Sidecar to point to Azure Service Bus (update Service Bus Connection String)
components/pub-sub-orders.yaml
kubectl apply -f components/pub-sub-orders.yaml

# Check if components are deployed, restart API Gateway
kubectl get components
kubectl rollout restart deployments/apim-local-gw

# Set Policy (Post Order)
<inbound>
    <base />
        <publish-to-dapr topic="@("pub-sub-orders/orders")" timeout="10" ignore-error="false" template="liquid">{{body}}</publish-to-dapr>
        <return-response>
            <set-status code="200" />
            <set-body>@("Message send to Service Bus.")</set-body>
        </return-response>
</inbound>

# Test
kubectl port-forward service/apim-local-gw 8080:80 8081:443
requests/tests.http

# Show message in Azure Service Bus Explorer in VSCode

## Check Application Insights Map

####### IF THERE IS TIME #######

## Step 7: Create Get Orders (/order) 

# Deploy httpbin API
services/httpbin-app.yaml
kubectl apply -f services/httpbin-app.yaml
kubectl get pods

# Set Policy (Get Orders)
<inbound>
    <base />
        <set-backend-service backend-id="dapr" dapr-app-id="httpbin-app" dapr-method="get" />
        <set-header name="x-dapr-test" exists-action="override">
            <value>request-header</value>
        </set-header>
</inbound>

# Test httpbin locally
kubectl port-forward deployment/apim-local-gw 3500:3500
requests/prereq.http

# Test
kubectl port-forward service/apim-local-gw 8080:80 8081:443
requests/tests.http

## Step 8: Create Get Order by Id (/order/{id})

# Update Dapr Sidecar to point to Azure Storage as State Store (update Storage Connection String)
components/state-store-orders.yaml
kubectl apply -f components/state-store-orders.yaml

# Check if components are deployed, restart API Gateway
kubectl get components
kubectl rollout restart deployments/apim-local-gw

# Set Policy (Get Order by Id)
<inbound>
    <base />
        <set-backend-service base-url="http://localhost:3500" />
        <rewrite-uri template="/v1.0/state/state-store-orders/{id}" copy-unmatched-params="true" />
</inbound>

# Post 2 entries to Azure Storage
kubectl port-forward deployment/apim-local-gw 3500:3500
requests/prereq.http

# Test
kubectl port-forward service/apim-local-gw 8080:80 8081:443
requests/tests.http

## Step 9: Check Application Insights Map

## Cleanup
minikube stop
minikube delete
Remove data from Azure Storage
Remove API Gateway from API Management
Remove API from API Management
Receive message from Azure Service Bus Subscription
