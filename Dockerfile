FROM python:alpine

LABEL maintainer="Luigi Di Fraia"

RUN pip install --no-cache-dir awscli

RUN apk add curl

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.5/bin/linux/amd64/kubectl

RUN chmod u+x kubectl && mv kubectl /bin/kubectl

ADD backup-folder.sh /usr/local/bin/backup-folder.sh

CMD ["sh"]
