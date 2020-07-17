# Backup a folder within a Kubernetes Pod to an S3 bucket

Docker image to backup a folder within a Kubernetes Pod to an S3 bucket.

The backup method implemented in this repo uses `tar` to backup a folder within a user *Pod* by means of issuing `kubectl exec` from inside an ephemeral *Pod* that can deployed as part of a *CronJob*. It is particularly recommended to backup a *Persistent Volume* that cannot be mounted *ReadWriteMany* due to limitations with the *StorageClass* or *Storage Provisioner* in use.
If you're not limited to working with *ReadWriteOnce*, then please have a look at *restic*, *Velero*, and *Stash*, instead of using the method described here.

## Example for backing up GeoServer's data folder

```bash
NAMESPACES=dev-csvs,stage-csvs

OIFS=$IFS
IFS=','
for ns in ${NAMESPACES}
do
    kubectl create role pod-reader --verb=get --verb=list --verb=watch --resource=pods --namespace=${ns}
    kubectl create rolebinding ${ns}-pod-reader --role=pod-reader --serviceaccount=default:default --namespace=${ns}
    kubectl create role pod-exec --verb=create --resource=pods/exec --namespace=${ns}
    kubectl create rolebinding ${ns}-pod-exec --role=pod-exec --serviceaccount=default:default --namespace=${ns}
done

IFS=$OIFS
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: geoserver-config-backup
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 3600
      template:
        spec:
          containers:
          - name: geoserver-config-backup
            image: satapps/backup-pod-folder-to-s3:0.3.0
            args:
            - backup-folder.sh
            env:
            - name: DEBUG
              value: ""
            - name: NAMESPACES
              value: "$NAMESPACES"
            - name: SELECTOR
              value: "app.kubernetes.io/name=geoserver"
            - name: CONTAINER
              value: "geoserver"
            - name: BACKUP_FOLDER
              value: "/geoserver_data/data"
            - name: BACKUP_NAME_TEMPLATE
              value: "geoserver_config_backup"
            - name: AWS_DESTINATION_BUCKET
              value: "csvs-backups"
            - name: AWS_ENDPOINT_URL
              value: "http://s3-uk-1.sa-catapult.co.uk"
            - name: AWS_ACCESS_KEY_ID
              value: "AKIAIOSFODNN7INVALID"
            - name: AWS_SECRET_ACCESS_KEY
              value: "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"
          restartPolicy: OnFailure
EOF
```
