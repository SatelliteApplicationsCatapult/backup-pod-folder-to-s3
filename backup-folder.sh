#!/bin/sh

# Validate environment
if [ -z ${NAMESPACES} ]; then
    echo "NAMESPACES variable is not set"
    echo "Set it to the namespaces whose pods have folders to be backed up"
    exit 1
fi

if [ -z ${SELECTOR} ]; then
    echo "SELECTOR variable is not set"
    echo "Set it to the selector to filter the pod in which there's the container with a folder to be backed up"
    exit 1
fi

if [ -z ${CONTAINER} ]; then
    echo "CONTAINER variable is not set"
    echo "Set it to the container in which there's a folder to be backed up"
    exit 1
fi

if [ -z ${BACKUP_FOLDER} ]; then
    echo "BACKUP_FOLDER variable is not set"
    echo "Set it to the folder to backup within the selected pod"
    exit 1
fi

if [ -z ${BACKUP_NAME_TEMPLATE} ]; then
    echo "BACKUP_NAME_TEMPLATE variable is not set"
    echo "Set it to the mid part of the backup filename"
    exit 1
fi

if [ -z ${AWS_DESTINATION_BUCKET} ]; then
    echo "AWS_DESTINATION_BUCKET variable is not set"
    echo "Set it to the destination S3 bucket for backups"
    exit 1
fi

if [ -z ${AWS_ACCESS_KEY_ID} ]; then
    echo "AWS_ACCESS_KEY_ID variable is not set"
    echo "Set it to the access key required to write to the destination bucket"
    exit 1
fi

if [ -z ${AWS_SECRET_ACCESS_KEY} ]; then
    echo "AWS_SECRET_ACCESS_KEY variable is not set"
    echo "Set it to the secret required to write to the destination bucket"
    exit 1
fi

# Environment looks fine, we are good to go
OIFS=$IFS
IFS=','
for ns in ${NAMESPACES}
do
    echo "Current namespace: ${ns}"
    target_pod=$(kubectl get pod -n ${ns} -l "${SELECTOR}" --no-headers -o=custom-columns='DATA:.metadata.name')
    if [ -z ${target_pod} ]; then
        echo "No Pod was matched by the provided selector, ${SELECTOR}, within the referenced Namespace, ${ns}"
    else 
        echo "Pod: ${target_pod}"
        backup_file=/tmp/${ns}_${BACKUP_NAME_TEMPLATE}_$(date --utc +%FT%TZ).tgz
        echo "Backup file: ${backup_file}"
        ${DEBUG} kubectl exec -n ${ns} ${target_pod} -c ${CONTAINER} -- tar czf - ${BACKUP_FOLDER} > ${backup_file}
        if [ "$?" -ne "0" ]; then
            echo "Backup file generation failed; not uploading to the provided S3 bucket"
        else
            if [ -z ${AWS_ENDPOINT_URL} ]; then
                ${DEBUG} aws s3 cp ${backup_file} s3://${AWS_DESTINATION_BUCKET}
            else
                ${DEBUG} aws --endpoint-url=${AWS_ENDPOINT_URL} s3 cp ${backup_file} s3://${AWS_DESTINATION_BUCKET}
            fi
        fi
        ${DEBUG} rm -rf ${backup_file}
    fi
done

IFS=$OIFS

