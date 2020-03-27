import pathlib
import yaml

from aws_cdk import (
    aws_apigateway as apigateway,
    aws_certificatemanager as cert_mgr,
    aws_cognito as cognito,
    aws_iam as iam,
    aws_lambda,
    aws_route53 as route53,
    aws_route53_targets as r53_targets,
    aws_s3 as s3,
    core
)

WORKING_DIR = pathlib.Path.cwd()
CONFIG_DIR = pathlib.PosixPath(WORKING_DIR).joinpath('config/stack.yaml')

def discover_lambda_files_in_path(path: pathlib.Path):
    files = [f for f in path.glob('**/*_fn.py') if pathlib.Path.is_file(f) and '_fn.py' in f.name]
    lambda_files = {}
    for f in files:
        print(f.with_suffix('').name)
        lambda_files[f.with_suffix('').name] = f

    return lambda_files

def load_config(path: pathlib.Path):
    with open(path, encoding='utf8') as fh:
        config = yaml.safe_load(fh)

    return config


class LunarRocksStack(core.Stack):
    def __init__(self, app: core.App, id: str, **kwargs) -> None:
        super().__init__(app, id, **kwargs)

        config = load_config(CONFIG_DIR)
        stack_id = config['stack_id']

        # S3 Bucket for Gateway to use
        if config['prod']:
            pages_bucket_name = config['pages_bucket']
            pages_bucket = s3.Bucket.from_bucket_arn(self, "LunarRocksPagesBucketexists", 'arn:aws:s3:::' + pages_bucket_name)
        else:
            pages_bucket = s3.Bucket(
                    self,
                    stack_id + "PagesBucket",
                    removal_policy=core.RemovalPolicy.DESTROY
            )
            pages_bucket_name = pages_bucket.bucket_name

        # Get various lambda function files
        lambda_files = discover_lambda_files_in_path(WORKING_DIR)

        # API Gateway to serve the client page
        with open(lambda_files['serve_client_fn'], encoding='utf8') as fh:
            serve_client_fn = fh.read()
        web_server_handler = aws_lambda.Function(
                self,
                stack_id + "ServeClientFn",
                code=aws_lambda.InlineCode(serve_client_fn),
                handler="index.handler",
                runtime=aws_lambda.Runtime.PYTHON_3_7,
                description="Handler function for serving LR client page",
                environment = {
                    "S3_BUCKET": pages_bucket_name
                }
        )
        lambda_read_statement = iam.PolicyStatement(
                actions=['s3:List*', 's3:Get*'],
                principals=[web_server_handler.role],
                resources=[pages_bucket.bucket_arn],
        )
        pages_bucket.add_to_resource_policy(lambda_read_statement)
        pages_bucket.grant_read(web_server_handler)
        domain_cert = cert_mgr.Certificate(
                self,
                stack_id + "DomainCert",
                domain_name=config['domain_name'],
        )
        gateway_domain = apigateway.DomainNameOptions(
                certificate=domain_cert,
                domain_name=config['domain_name'],
        )
        dns_hosted_zone = route53.HostedZone(
                self,
                stack_id + "HostedZone",
                zone_name=config['domain_name'],
        )
        web_api = apigateway.LambdaRestApi(
                self,
                stack_id + 'LambdaRestApi',
                domain_name=gateway_domain,
                handler=web_server_handler,
                default_cors_preflight_options={
                    "allow_origins": apigateway.Cors.ALL_ORIGINS,
                    "allow_methods": ["GET"],
                    "allow_headers": apigateway.Cors.DEFAULT_HEADERS
                },
        )
        dns_record_set = route53.ARecord(
                self,
                stack_id + "RecordSet",
                record_name=config['domain_name'],
                target=route53.RecordTarget.from_alias(r53_targets.ApiGatewayDomain(web_api.domain_name)),
                zone=dns_hosted_zone,
        )

        # user pool and client provide auth for web app and API
        user_pool = cognito.CfnUserPool(
            self, 'UserPool',
            auto_verified_attributes=['email'],
            alias_attributes=['email'],
            schema=[
                {'attributeDataType': 'String', 'name': 'email', 'required': True, 'mutable': True},
                {'attributeDataType': 'String', 'name': 'picture', 'required': False, 'mutable': True},
                {'attributeDataType': 'String', 'name': 'nickname', 'required': False, 'mutable': True},
                {'attributeDataType': 'String', 'name': 'website', 'required': False, 'mutable': True},
                {'attributeDataType': 'String', 'name': 'bio', 'required': False, 'mutable': True, 
                 'stringAttributeConstraints': {'minLength' : '0', 'maxLength' : '2048'}
                },
                {'attributeDataType': 'String', 'name': 'location', 'required': False, 'mutable': True,
                 'stringAttributeConstraints': {'minLength' : '0', 'maxLength' : '2048'}
                },
                ],
            policies={'passwordPolicy': {'minimumLength': 16}},
            user_pool_name='lunar-rocks',
            user_pool_tags={'Site': "lunar.rocks", 'Project': "Lunar Rocks"}
        )

        user_pool_client = cognito.CfnUserPoolClient(
            self, 'UserPoolClient',
            user_pool_id=user_pool.ref,
            client_name='lunar-rocks-app-client',
            explicit_auth_flows=['ALLOW_REFRESH_TOKEN_AUTH', 'ALLOW_USER_SRP_AUTH'],
            refresh_token_validity=30,
            generate_secret=False,
            prevent_user_existence_errors='ENABLED',
            write_attributes=['email','nickname','picture','website','custom:bio','custom:location']
        )

        user_pool_output = core.CfnOutput(
            self, 'UserPoolOutput',
            value=user_pool.ref
        )

        user_pool_client_output = core.CfnOutput(
            self, 'UserPoolClientOutput',
            value=user_pool_client.ref
        )

        # object store is used for storing user assets (such as avatars)
        user_object_store = s3.Bucket(
            self, 'UserObjectStore',
            cors=[
                s3.CorsRule(
                    allowed_origins=['*'],
                    allowed_methods=[
                        s3.HttpMethods.HEAD,
                        s3.HttpMethods.GET,
                        s3.HttpMethods.PUT,
                        s3.HttpMethods.POST,
                        s3.HttpMethods.DELETE,
                    ],
                    allowed_headers=['*'],
                    exposed_headers=[
                        'x-amz-server-side-encryption',
                        'x-amz-request-id',
                        'x-amz-id-2',
                        'ETag'
                    ],
                    max_age=3000
                )
            ]
        )

        user_object_store_output = core.CfnOutput(
            self, 'UserObjectStoreOutput',
            value=user_object_store.bucket_name
        )

        # identity pool grants access to AWS services (user_object_store)
        identity_pool = cognito.CfnIdentityPool(
            self, 'IdentityPool',
            allow_unauthenticated_identities=True,
            cognito_identity_providers=[
                {'clientId': user_pool_client.ref,
                'providerName': 'cognito-idp.us-west-2.amazonaws.com/' + user_pool.ref
                }
            ],
            identity_pool_name='lunar-rocks-identity-pool'
        )

        amplify_auth_policy_document = iam.PolicyDocument(
            statements=[
                iam.PolicyStatement(
                    actions=['s3:GetObject', 's3:PutObject', 's3:DeleteObject'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/public/*',
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/protected/${cognito-identity.amazonaws.com:sub}/*',
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/private/${cognito-identity.amazonaws.com:sub}/*',
                    ],
                    effect=iam.Effect.ALLOW
                ),
                iam.PolicyStatement(
                    actions=['s3:PutObject'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/uploads/*',
                    ],
                    effect=iam.Effect.ALLOW
                ),
                iam.PolicyStatement(
                    actions=['s3:GetObject'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/protected/*',
                    ],
                    effect=iam.Effect.ALLOW
                ),
                iam.PolicyStatement(
                    actions=['s3:ListBucket'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name
                    ],
                    conditions={
                        'StringLike':{
                            's3:prefix': [
                                'public/',
                                'public/*',
                                'protected/',
                                'protected/*',
                                'private/${cognito-identity.amazonaws.com:sub}/',
                                'private/${cognito-identity.amazonaws.com:sub}/*'
                            ]
                        }
                    },
                    effect=iam.Effect.ALLOW
                )
            ]
        )

        auth_role = iam.Role(
            self, "AuthRole",
            assumed_by=iam.FederatedPrincipal(
                "cognito-identity.amazonaws.com",
                {'StringEquals': {"cognito-identity.amazonaws.com:aud": identity_pool.ref}},
                'sts:AssumeRoleWithWebIdentity'
            ),
            inline_policies={'AmplifyAuthPolicy': amplify_auth_policy_document}
        )

        amplify_unauth_policy_document = iam.PolicyDocument(
            statements=[
                iam.PolicyStatement(
                    actions=['s3:GetObject', 's3:PutObject', 's3:DeleteObject'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/public/*',
                    ],
                    effect=iam.Effect.ALLOW
                ),
                iam.PolicyStatement(
                    actions=['s3:PutObject'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/uploads/*',
                    ],
                    effect=iam.Effect.ALLOW
                ),
                iam.PolicyStatement(
                    actions=['s3:GetObject'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name + '/protected/*',
                    ],
                    effect=iam.Effect.ALLOW
                ),
                iam.PolicyStatement(
                    actions=['s3:ListBucket'],
                    resources=[
                        'arn:aws:s3:::' + user_object_store.bucket_name
                    ],
                    conditions={
                        'StringLike':{
                            's3:prefix': [
                                'public/',
                                'public/*',
                                'protected/',
                                'protected/*',
                            ]
                        }
                    },
                    effect=iam.Effect.ALLOW
                )
            ]
        )

        unauth_role = iam.Role(
            self, "UnauthRole",
            assumed_by=iam.FederatedPrincipal(
                "cognito-identity.amazonaws.com",
                {'StringEquals': {"cognito-identity.amazonaws.com:aud": identity_pool.ref}},
                'sts:AssumeRoleWithWebIdentity'
            ),
            inline_policies={'AmplifyUnauthPolicy': amplify_unauth_policy_document}
        )

        identity_pool_role_attachment = cognito.CfnIdentityPoolRoleAttachment(
            self, 'IdentityPoolRoleAttachment',
            identity_pool_id=identity_pool.ref,
            roles={
                "authenticated": auth_role.role_arn,
                "unauthenticated": unauth_role.role_arn,
            }
        )

        identity_pool_output = core.CfnOutput(
            self, 'IdentityPoolOutput',
            value=identity_pool.ref
        )


config = load_config(CONFIG_DIR)
app = core.App()
stack = LunarRocksStack(app, config['stack_id'] + "Stack")
app.synth()
