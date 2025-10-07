# **Setting up the terraform-netwrok-mirror**
Before we start running the script there are some pre-requirements we have to configure in order for our script to complete successfully.
There are two things we need to accomplish before running the script:

1. Create S3 bucket with static website hosting enabled
2. Create CloudFront distribution endpoint and configure the created S3 bucket as an origin source

&nbsp;
&nbsp;

## **Creating S3 bucket with static website hosting enabled**
First we are gonna create an empty bucket and then configure the static website hosting setting.

1. Go to the S3 bucket service tab and then click the create bucket.
2. In the bucket name, define your name but it has to be unique. 
3. Leave the ACL disabled as we only want the objects in this bucket to be own by the bucket owner.
4. Uncheck the Block all public access and you can leave the rest of the setting as default.
5. Then click the create bucket.

After you have created the bucket, click the bucket and go to the ***Properties*** tab, scroll down to the bottom, once 
&nbsp;

<img width="1883" height="465" alt="image" src="https://github.com/user-attachments/assets/752cb969-fead-4938-ac10-e3aa2f0a7912" />

&nbsp;
&nbsp;

> And also make sure that the bucket is publically accessiable by disabling the ***Block all public access*** and having a proper ***bucket policy***.

&nbsp;
&nbsp;

<img width="1890" height="288" alt="image" src="https://github.com/user-attachments/assets/db0f1c9c-6544-4739-b5b2-0ed7ff648218" />
&nbsp;

```JSON

Bucket policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::provider-cache-tf",
                "arn:aws:s3:::provider-cache-tf/*"
            ]
        }
    ]
}
```
&nbsp;
&nbsp;

## **Creating CloudFront distribution endpoint with S3 bucket as an origin source**

<img width="1377" height="771" alt="image" src="https://github.com/user-attachments/assets/719797f3-3e87-446e-b38b-8a155addb6a5" />
