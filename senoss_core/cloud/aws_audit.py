# Safe, read-only AWS checks. Requires AWS credentials if used.
import boto3, botocore

def list_s3_buckets():
    try:
        s3 = boto3.client("s3")
        resp = s3.list_buckets()
        return {"buckets": [b["Name"] for b in resp.get("Buckets", [])]}
    except botocore.exceptions.NoCredentialsError:
        return {"error": "no-aws-creds"}
    except Exception as e:
        return {"error": str(e)}
