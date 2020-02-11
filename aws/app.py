
from aws_cdk import (
    aws_iam as iam,
    aws_cognito as cognito,
    aws_s3 as s3,
    core
)


class LunarRocksStack(core.Stack):
    def __init__(self, app: core.App, id: str, **kwargs) -> None:
        super().__init__(app, id, **kwargs)

        # user pool and client provide auth for web app and API
        user_pool = cognito.CfnUserPool(
            self, 'UserPool',
            auto_verified_attributes=['email'],
            alias_attributes=['email'],
            schema=[{'attributeDataType': 'String', 'name': 'email', 'required': True, 'mutable': True}],
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
            write_attributes=['email']
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



app = core.App()
stack = LunarRocksStack(app, "LunarRocksStack")
app.synth()
