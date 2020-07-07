# Backup a folder from a Kubernetes Pod to an S3 bucket

## Example for backing up GeoServer's data folder

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: geoserver-config-backup
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: geoserver-config-backup
            image: backup-pod-folder-to-s3
            args:
            - /backup-folder.sh
            env:
            - name: DEBUG
              value: "echo"
            - name: NAMESPACES
              value: "test-csvs,dev-csvs,stage-csvs"
            - name: SELECTOR
              value: "app.kubernetes.io/name=geoserver"
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
```
