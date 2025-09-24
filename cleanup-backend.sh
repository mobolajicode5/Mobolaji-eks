#!/bin/bash

# Delete all objects in S3 bucket (including versions)
aws s3api delete-objects --bucket innovatemart-terraform-state --delete "$(aws s3api list-object-versions --bucket innovatemart-terraform-state --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete all delete markers
aws s3api delete-objects --bucket innovatemart-terraform-state --delete "$(aws s3api list-object-versions --bucket innovatemart-terraform-state --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Delete S3 bucket
aws s3 rb s3://innovatemart-terraform-state --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-state-lock --region eu-west-1