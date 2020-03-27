# AWS Backend Readme

The Lunar Rocks backend uses AWS Cognito for auth.

==================================================

## Auth

The backend uses AWS CDK to deploy a Cognito `UserPool` and a `UserPoolClient`.
The primary identifier for a user is their username, but they can also sign in 
with an email. The username cannot be changed after initial sign up.

## Setup

Install and configure the 
[AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html#w84aab9b9b9b5) 
for use with Python.

Set up a virtual environment, activate it and install the project dependencies:

```
virtualenv -p python3 venv
source venv/bin/activate
pip install -r requirements.txt
```

### Configure

* Local Config
  * Make sure you edit `config/stack.yaml` to include the correct
    configuration for your test or production stack. The file included
    in the repo is meant as an example only, to demonstrate the template
    the CDK app expects.
* Domain Config
  * You will need to configure your domain to use the custom nameservers
    listed by AWS route53 rather than whatever default NS they might use

## Deploy

Deploy to AWS:

```
cdk deploy
```

This command will use your default AWS profile. You can specify another profile 
with the `--profile` flag.

You can preview the resources that will be deployed with:

```
cdk synth
```

## Client Configuration

The client must be configured with the Region, User Pool Id, and App Client Id.

After the completing the deployment, run:

```
python configure_client.py
```

to configure the client.
