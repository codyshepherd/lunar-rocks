
from aws_cdk import (
    aws_cognito as cognito,
    core
)


class LunarRocksStack(core.Stack):
    def __init__(self, app: core.App, id: str, **kwargs) -> None:
        super().__init__(app, id, **kwargs)

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


app = core.App()
stack = LunarRocksStack(app, "LunarRocksStack")
app.synth()