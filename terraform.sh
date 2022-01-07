#!/usr/bin/env bash

set -e

if [ "$#"  -ne 3 ]; then
    echo "Usage: $0 TASK STACK-NAME STACK-INSTANCE"
    exit 1
fi

task=$1
stack_name=$2
stack_identifier=$3

account_id=$(aws sts get-caller-identity --query Account --output text)
#account_id="123456789"
state_region="eu-west-2"
state_bucket="${account_id}-tfstate-global"
state_key="${stack_name}/${stack_identifier}/terraform.tfstate"

export TF_DATA_DIR=.terraform/${stack_name}/${stack_identifier}

echo "Terraform data directory: ${TF_DATA_DIR}"
echo "Remote state stored in s3://${state_bucket}/${state_key} (${state_region})"

case "${task}" in
    init)
        terraform -chdir=${stack_name} init \
            -backend-config key=${state_key} \
            -backend-config bucket=${state_bucket} \
            -backend-config region=${state_region}
        ;;
    validate)
        terraform -chdir=${stack_name} validate
        ;;
    plan)
        terraform -chdir=${stack_name} plan \
            -var stack_identifier=${stack_identifier} \
            -out=${stack_name}-${stack_identifier}.tfplan
        ;;
    apply)
        terraform -chdir=${stack_name} apply ${stack_name}-${stack_identifier}.tfplan
        ;;
    *)
        echo "Unrecognised task: ${task}"
        exit 1
        ;;
esac

