#!/bin/bash

echo "🗑️  MSK Cleanup Script"
echo "====================="
echo ""

# Set AWS profile
export AWS_PROFILE=heroseguros-tripHero
REGION="us-east-2"

# Find MSK cluster
echo "🔍 Looking for MSK cluster..."
CLUSTER_ARN=$(aws kafka list-clusters --region $REGION --output json 2>/dev/null | jq -r '.ClusterInfoList[] | select(.ClusterName == "hero-trip-prod-msk") | .ClusterArn')

if [ -n "$CLUSTER_ARN" ]; then
    echo "✅ Found cluster: $CLUSTER_ARN"
    echo ""
    echo "🗑️  Deleting MSK cluster..."
    aws kafka delete-cluster --cluster-arn "$CLUSTER_ARN" --region $REGION
    
    echo ""
    echo "⏳ Waiting for cluster deletion (this takes ~15 minutes)..."
    echo "💡 You can check status with: aws kafka describe-cluster --cluster-arn $CLUSTER_ARN --region $REGION"
    echo ""
    echo "Run this script again after the cluster is deleted to clean up the configuration."
else
    echo "❌ No MSK cluster found or already deleted"
    
    # Try to delete configuration
    echo ""
    echo "🔍 Looking for MSK configuration..."
    CONFIG_ARN=$(aws kafka list-configurations --region $REGION --output json 2>/dev/null | jq -r '.Configurations[] | select(.Name == "hero-trip-prod-msk-config") | .Arn')
    
    if [ -n "$CONFIG_ARN" ]; then
        echo "✅ Found configuration: $CONFIG_ARN"
        echo ""
        echo "🗑️  Deleting MSK configuration..."
        aws kafka delete-configuration --arn "$CONFIG_ARN" --region $REGION
        
        if [ $? -eq 0 ]; then
            echo "✅ Configuration deleted successfully"
        else
            echo "❌ Failed to delete configuration. It might still be in use."
            echo "💡 Wait a few more minutes and run this script again."
        fi
    else
        echo "❌ No MSK configuration found or already deleted"
    fi
fi

echo ""
echo "🧹 Cleanup other resources..."

# Delete IAM policies
echo "🗑️  Deleting IAM policies..."
aws iam delete-role-policy --role-name hero-trip-prod-debezium --policy-name hero-trip-prod-debezium-msk 2>/dev/null && echo "  ✅ Deleted debezium-msk policy"
aws iam delete-role-policy --role-name hero-trip-prod-debezium --policy-name hero-trip-prod-debezium-secrets 2>/dev/null && echo "  ✅ Deleted debezium-secrets policy"

# Delete IAM role
echo "🗑️  Deleting IAM role..."
aws iam delete-role --role-name hero-trip-prod-debezium 2>/dev/null && echo "  ✅ Deleted debezium role"

echo ""
echo "✅ Cleanup script completed!"
echo ""
echo "📋 Next steps:"
echo "1. Wait for MSK cluster deletion to complete (~15 min)"
echo "2. Run this script again to delete the configuration"
echo "3. Run: cd /home/jpvieirah/triphero-infra/triphero-datalake-infrastructure && terraform init && terraform apply -var-file=environments/prod.tfvars"
