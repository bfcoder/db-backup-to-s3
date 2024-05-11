#!/bin/bash
# dump the database and upload it to S3
#
# usage: dump_db_to_s3

if [ -z "$DB_HOSTNAME" ]; then
  echo "Error: DB_HOSTNAME environment variable is not set"
  exit 1
fi

if [ -z "$DB_USER" ]; then
  echo "Error: DB_USER environment variable is not set"
  exit 1
fi

if [ -z "$DB_NAME" ]; then
  echo "Error: DB_NAME environment variable is not set"
  exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "Error: DB_PASSWORD environment variable is not set"
  exit 1
fi

if [ -z "$DUMP_FILE_LOCATION" ]; then
  echo "Error: DUMP_FILE_LOCATION environment variable is not set"
  exit 1
fi

if [ -z "$DUMP_FILE_PREFIX" ]; then
  echo "Error: DUMP_FILE_PREFIX environment variable is not set"
  exit 1
fi

if [ -z "$S3_BUCKET" ]; then
  echo "Error: S3_BUCKET environment variable is not set"
  exit 1
fi

if [ -z "$PGPASSFILE" ]; then
  echo "Error: PGPASSFILE environment variable is not set"
  exit 1
fi

if [ -z "$AWS_DEFAULT_REGION" ]; then
  export AWS_DEFAULT_REGION="us-east-1"
fi

cat << EOF > $PGPASSFILE
$DB_HOSTNAME:*:$DB_NAME:$DB_USER:$DB_PASSWORD
EOF

chmod 600 $PGPASSFILE

export DUMP_FILE="$DUMP_FILE_LOCATION/$DUMP_FILE_PREFIX$(date +%Y%m%d%H%M%S).dump"

time pg_dump -h $DB_HOSTNAME -U $DB_USER --clean --format=c --no-owner --no-acl --no-password -f $DUMP_FILE $DB_NAME

if [ -f "$DUMP_FILE" ]; then
  echo "Database dumped successfully to $DUMP_FILE"
else
  echo "Error: Failed to dump the database"
  exit 1
fi

aws s3 cp "$DUMP_FILE" "s3://$S3_BUCKET/$(basename "$DUMP_FILE")"

if [ $? -eq 0 ]; then
  echo "Database dump uploaded to S3"
else
  echo "Error: Failed to upload the database dump to S3"
fi

if [ -n "$TAG_KEY" ] && [ -n "$TAG_VALUE" ]; then
  aws s3api put-object-tagging --bucket "$S3_BUCKET" --key "$(basename "$DUMP_FILE")" --tagging "TagSet=[{Key=$TAG_KEY,Value=$TAG_VALUE}]"

  if [ $? -eq 0 ]; then
    echo "Tags added to the uploaded file"
  else
    echo "Error: Failed to add tags to the uploaded file"
    exit 1
  fi
fi

rm "$DUMP_FILE"

echo "Script execution completed"
