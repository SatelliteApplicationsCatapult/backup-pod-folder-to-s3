#!/bin/sh

# Validate environment
if [ -z ${NAMESPACES+x} ]; then
    echo "NAMESPACES variable is not set"
    echo "Set it to the namespaces whose pods have folders to be backed up"
    exit 1
fi

if [ -z ${SELECTOR+x} ]; then
    echo "SELECTOR variable is not set"
    echo "Set it to the selector to filter the pods that have folders to be backed up"
    exit 1
fi

if [ -z ${BACKUP_FOLDER+x} ]; then
    echo "BACKUP_FOLDER variable is not set"
    echo "Set it to the folder to backup from within each selected pod"
    exit 1
fi

if [ -z ${BACKUP_NAME_TEMPLATE+x} ]; then
    echo "BACKUP_NAME_TEMPLATE variable is not set"
    echo "Set it to the mid part of the backup filename"
    exit 1
fi

if [ -z ${AWS_DESTINATION_BUCKET+x} ]; then
    echo "AWS_DESTINATION_BUCKET variable is not set"
    echo "Set it to the destination S3 bucket for backups"
    exit 1
fi

if [ -z ${AWS_ACCESS_KEY_ID+x} ]; then
    echo "AWS_ACCESS_KEY_ID variable is not set"
    echo "Set it to the access key required to write to the destination bucket"
    exit 1
fi

if [ -z ${AWS_SECRET_ACCESS_KEY+x} ]; then
    echo "AWS_SECRET_ACCESS_KEY variable is not set"
    echo "Set it to the secret required to write to the destination bucket"
    exit 1
fi


OIFS=$IFS
IFS=','
for ns in ${NAMESPACES}
do
    echo "Current namespace: ${ns}"
    target_pod=$(kubectl get pod -n ${ns} -l "${SELECTOR}" --no-headers -o=custom-columns='DATA:.metadata.name')
    echo "Pod: ${target_pod}"
    backup_file=/tmp/${ns}_${BACKUP_NAME_TEMPLATE}_$(date --utc +%FT%TZ).tgz
    echo "Backup file: ${backup_file}"
    ${DEBUG} kubectl exec -n ${ns} ${target_pod} -- tar czf - ${BACKUP_FOLDER} > ${backup_file}
    if [ -z ${AWS_ENDPOINT_URL+x} ]; then
        ${DEBUG} aws s3 cp ${backup_file} s3://${AWS_DESTINATION_BUCKET}
    else
        ${DEBUG} aws --endpoint-url=${AWS_ENDPOINT_URL} s3 cp ${backup_file} s3://${AWS_DESTINATION_BUCKET}
    fi
    ${DEBUG} rm -rf /tmp/*geoserver_data_backup*.tgz
done

IFS=$OIFS

