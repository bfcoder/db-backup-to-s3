FROM alpine:latest

RUN apk --no-cache add postgresql-client aws-cli

COPY dump_db_to_s3.sh dump_db_to_s3.sh

ENTRYPOINT ["/bin/sh"]

CMD ["./dump_db_to_s3.sh"]
