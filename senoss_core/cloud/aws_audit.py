import boto3, botocore

def list_s3_buckets():
    try:
        cli = boto3.client("s3")
        r = cli.list_buckets()
        return {"buckets": [b["Name"] for b in r.get("Buckets",[])]}
    except botocore.exceptions.NoCredentialsError:
        return {"error": "no-aws-creds"}
    except Exception as e:
        return {"error": str(e)}
