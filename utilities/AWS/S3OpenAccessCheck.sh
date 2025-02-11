#!/bin/bash

# S3OpenAccessCheck.sh
# A comprehensive AWS S3 bucket security assessment tool
# 
# This script checks for common S3 bucket misconfigurations that could lead
# to data exposure, including:
# - Disabled public access blocks
# - Public bucket ACLs
# - Permissive bucket policies  
# - Enabled website hosting
#
# Author: The Haag
# Usage: ./S3OpenAccessCheck.sh
#
# Requires:
# - AWS CLI configured with appropriate permissions
# - jq for JSON parsing

banner="
  ____ _____    ___                        _                           ____                        _  ___ _   
 / ___|___ /   / _ \ _ __   ___ _ __      / \   ___ ___ ___  ___ ___  |  _ \ ___  ___ ___  _ __   | |/ (_) |_ 
 \___ \ |_ \  | | | | '_ \ / _ \ '_ \    / _ \ / __/ __/ _ \/ __/ __| | |_) / _ \/ __/ _ \| '_ \  | ' /| | __|
  ___) |__) | | |_| | |_) |  __/ | | |  / ___ \ (_| (_|  __/\__ \__ \ |  _ <  __/ (_| (_) | | | | | . \| | |_ 
 |____/____/   \___/| .__/ \___|_| |_| /_/   \_\___\___\___||___/___/ |_| \_\___|\___\___/|_| |_| |_|\_\_|\__|
                    |_|                                                                                       
                                                                           
                    S3 Open Access Reconnaissance Kit
                    ================================
"

echo "$banner"

buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

echo "Checking for publicly accessible S3 buckets..."
echo "============================================"

for bucket in $buckets; do
    echo "Checking bucket: $bucket"

    # Check Public Access Block - expanded to check all settings
    public_access=$(aws s3api get-public-access-block --bucket "$bucket" 2>/dev/null)
    block_public_acls=$(echo "$public_access" | jq -r '.PublicAccessBlockConfiguration.BlockPublicAcls')
    block_public_policy=$(echo "$public_access" | jq -r '.PublicAccessBlockConfiguration.BlockPublicPolicy')
    ignore_public_acls=$(echo "$public_access" | jq -r '.PublicAccessBlockConfiguration.IgnorePublicAcls')
    restrict_public_buckets=$(echo "$public_access" | jq -r '.PublicAccessBlockConfiguration.RestrictPublicBuckets')

    # Check Bucket ACL - expanded to check for all public permissions
    acl_check=$(aws s3api get-bucket-acl --bucket "$bucket" 2>/dev/null)
    public_acl=$(echo "$acl_check" | jq -r '.Grants[] | select(.Grantee.URI=="http://acs.amazonaws.com/groups/global/AllUsers" or .Grantee.URI=="http://acs.amazonaws.com/groups/global/AuthenticatedUsers") | "\(.Permission) (\(.Grantee.URI))"')

    # Check Bucket Policy - enhanced to detect specific risky statements
    policy_check=$(aws s3api get-bucket-policy --bucket "$bucket" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        policy_risks=$(echo "$policy_check" | jq -r '.Policy' | jq -r '
            .Statement[] | select(
                (.Effect == "Allow") and (
                    .Principal == "*" or
                    .Principal.AWS == "*" or
                    .Principal.AWS[] == "*" or
                    ((.Action == "s3:*" or .Action[] == "s3:*") and .Condition == null)
                )
            ) | "Risky Policy: \(.Effect) on \(.Action)"
        ' 2>/dev/null)
    fi

    # Check Website Hosting with additional details
    website_check=$(aws s3api get-bucket-website --bucket "$bucket" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        index_doc=$(echo "$website_check" | jq -r '.IndexDocument.Suffix')
        error_doc=$(echo "$website_check" | jq -r '.ErrorDocument.Key')
    fi

    # Check bucket versioning (disabled versioning could lead to data loss)
    versioning_check=$(aws s3api get-bucket-versioning --bucket "$bucket" 2>/dev/null | jq -r '.Status')

    # Check encryption settings
    encryption_check=$(aws s3api get-bucket-encryption --bucket "$bucket" 2>/dev/null || echo "No encryption")

    if [[ "$block_public_acls" == "false" || "$block_public_policy" == "false" || \
          "$ignore_public_acls" == "false" || "$restrict_public_buckets" == "false" || \
          -n "$public_acl" || -n "$policy_risks" || -n "$website_check" || \
          "$versioning_check" == "Suspended" || "$encryption_check" == "No encryption" ]]; then
        
        echo "[!] SECURITY CONCERNS FOUND FOR BUCKET: $bucket"
        echo "------------------------------------------------"
        
        # Report Public Access Block settings
        [[ "$block_public_acls" == "false" ]] && echo "    - BlockPublicAcls: Disabled"
        [[ "$block_public_policy" == "false" ]] && echo "    - BlockPublicPolicy: Disabled"
        [[ "$ignore_public_acls" == "false" ]] && echo "    - IgnorePublicAcls: Disabled"
        [[ "$restrict_public_buckets" == "false" ]] && echo "    - RestrictPublicBuckets: Disabled"
        
        # Report ACL issues
        [[ -n "$public_acl" ]] && echo "    - Public ACL Found: $public_acl"
        
        # Report Policy issues
        [[ -n "$policy_risks" ]] && echo "    - $policy_risks"
        
        # Report Website Hosting
        if [[ -n "$website_check" ]]; then
            echo "    - Website Hosting Enabled:"
            echo "      URL: http://$bucket.s3-website-$(aws configure get region).amazonaws.com"
            echo "      Index Document: $index_doc"
            [[ -n "$error_doc" ]] && echo "      Error Document: $error_doc"
        fi
        
        # Report Versioning Status
        [[ "$versioning_check" == "Suspended" ]] && echo "    - Versioning is disabled"
        
        # Report Encryption Status
        [[ "$encryption_check" == "No encryption" ]] && echo "    - Default encryption is not enabled"
        
        echo "------------------------------------------------"
    fi
done
